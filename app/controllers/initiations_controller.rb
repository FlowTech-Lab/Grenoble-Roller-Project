class InitiationsController < ApplicationController
  before_action :set_initiation, only: [ :show, :edit, :update, :destroy, :attend, :cancel_attendance ]
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :load_supporting_data, only: [ :new, :create, :edit, :update ]

  def index
    # Utiliser policy_scope pour respecter les permissions Pundit
    # Les créateurs peuvent voir leurs initiations en draft, les autres voient seulement les publiées
    scoped_initiations = policy_scope(Event::Initiation.includes(:creator_user, :attendances))
    @initiations = scoped_initiations
      .upcoming_initiations
      .limit(12) # 3 mois
  end

  def show
    authorize @initiation
    # @initiation déjà chargé avec includes dans set_initiation
    # Récupérer toutes les attendances de l'utilisateur (parent + enfants)
    if user_signed_in?
      @user_attendances = @initiation.attendances.where(user: current_user).includes(:child_membership)
      @user_attendance = @user_attendances.find_by(child_membership_id: nil) # Inscription parent
      @child_attendances = @user_attendances.where.not(child_membership_id: nil) # Inscriptions enfants
    else
      @user_attendances = Attendance.none
      @user_attendance = nil
      @child_attendances = Attendance.none
    end
    @can_register = can_register?
    @can_register_child = can_register_child?
  end

  def new
    @initiation = Event::Initiation.new(
      creator_user: current_user,
      status: "draft",
      start_at: next_saturday_at_10_15,
      duration_min: 105, # 1h45
      max_participants: 30,
      location_text: "Gymnase Ampère, 74 Rue Anatole France, 38100 Grenoble",
      meeting_lat: 45.17323364952216,
      meeting_lng: 5.705659385672371,
      level: "beginner",
      distance_km: 0,
      price_cents: 0,
      currency: "EUR"
    )
    authorize @initiation
  end

  def create
    @initiation = Event::Initiation.new(creator_user: current_user)
    authorize @initiation

    initiation_params = permitted_attributes(@initiation)
    initiation_params[:currency] = "EUR"
    initiation_params[:status] = "draft" # Toujours en draft à la création
    initiation_params[:price_cents] = 0 # Gratuit
    initiation_params[:creator_user_id] = current_user.id

    if @initiation.update(initiation_params)
      redirect_to initiation_path(@initiation), notice: "Initiation créée avec succès. Elle est en attente de validation par un modérateur."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @initiation
  end

  def update
    authorize @initiation

    initiation_params = permitted_attributes(@initiation)
    initiation_params[:currency] = "EUR"
    initiation_params[:price_cents] = 0 # Gratuit

    # Seuls les modérateurs+ peuvent changer le statut
    unless current_user.role&.level.to_i >= 50 # MODERATOR = 50
      initiation_params.delete(:status)
    end

    if @initiation.update(initiation_params)
      redirect_to initiation_path(@initiation), notice: "Initiation mise à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @initiation
    @initiation.destroy

    redirect_to initiations_path, notice: "Initiation supprimée."
  end

  def attend
    authorize @initiation, :attend?

    child_membership_id = params[:child_membership_id].presence
    
    # Si c'est pour un enfant, vérifier qu'il n'est pas déjà inscrit
    if child_membership_id.present?
      existing_attendance = @initiation.attendances.find_by(
        user: current_user,
        child_membership_id: child_membership_id
      )
      if existing_attendance
        child_name = Membership.find_by(id: child_membership_id)&.child_full_name || "cet enfant"
        redirect_to initiation_path(@initiation), notice: "#{child_name} est déjà inscrit(e) à cette séance."
        return
      end
    else
      # Si c'est pour le parent, vérifier qu'il n'est pas déjà inscrit
      existing_attendance = @initiation.attendances.find_by(
        user: current_user,
        child_membership_id: nil
      )
      if existing_attendance
        redirect_to initiation_path(@initiation), notice: "Vous êtes déjà inscrit(e) à cette séance."
        return
      end
    end

    attendance = @initiation.attendances.build(user: current_user)
    attendance.status = "registered"
    # Lire les paramètres directement au niveau racine (comme EventsController)
    attendance.wants_reminder = params[:wants_reminder].present? ? params[:wants_reminder] == "1" : false
    attendance.equipment_note = params[:equipment_note] if params[:equipment_note].present?
    attendance.child_membership_id = child_membership_id

    # Gestion essai gratuit (uniquement pour le parent, pas pour les enfants)
    if params[:use_free_trial] == "1" && child_membership_id.nil?
      if current_user.attendances.where(free_trial_used: true).exists?
        redirect_to initiation_path(@initiation), alert: "Vous avez déjà utilisé votre essai gratuit."
        return
      end
      attendance.free_trial_used = true
    elsif child_membership_id.nil?
      # Pour le parent : vérifier adhésion ou essai gratuit
      has_active_membership = current_user.memberships.active_now.exists?
      has_child_membership = current_user.memberships.active_now.where(is_child_membership: true).exists?

      unless has_active_membership || has_child_membership
        redirect_to initiation_path(@initiation), alert: "Adhésion requise. Utilisez votre essai gratuit ou adhérez à l'association."
        return
      end
    else
      # Pour un enfant : vérifier que l'adhésion enfant est active
      child_membership = current_user.memberships.find_by(id: child_membership_id)
      unless child_membership&.active?
        redirect_to initiation_path(@initiation), alert: "L'adhésion de cet enfant n'est pas active."
        return
      end
    end

    if attendance.save
      # Email de confirmation : vérifier wants_initiation_mail pour les initiations
      if current_user.wants_initiation_mail?
        EventMailer.attendance_confirmed(attendance).deliver_later
      end
      participant_name = attendance.for_child? ? attendance.participant_name : "Vous"
      redirect_to initiation_path(@initiation), notice: "Inscription confirmée pour #{participant_name} le #{l(@initiation.start_at, format: :long)}."
    else
      redirect_to initiation_path(@initiation), alert: attendance.errors.full_messages.to_sentence
    end
  end

  def cancel_attendance
    authorize @initiation, :cancel_attendance?

    # Permettre de désinscrire soi-même ou un enfant spécifique
    child_membership_id = params[:child_membership_id].presence
    
    attendance = if child_membership_id.present?
      # Désinscrire un enfant spécifique
      @initiation.attendances.find_by(
        user: current_user,
        child_membership_id: child_membership_id
      )
    else
      # Désinscrire le parent (child_membership_id est NULL)
      @initiation.attendances.where(
        user: current_user
      ).where(child_membership_id: nil).first
    end

    if attendance
      participant_name = attendance.for_child? ? attendance.participant_name : "vous"
      wants_initiation_mail = current_user.wants_initiation_mail?
      if attendance.destroy
        # Email d'annulation : vérifier wants_initiation_mail pour les initiations
        if wants_initiation_mail && attendance.for_parent?
          EventMailer.attendance_cancelled(current_user, @initiation).deliver_later
        end
        redirect_to initiation_path(@initiation), notice: "Inscription de #{participant_name} annulée."
      else
        redirect_to initiation_path(@initiation), alert: "Impossible d'annuler cette inscription."
      end
    else
      redirect_to initiation_path(@initiation), alert: "Inscription introuvable."
    end
  end

  private

  def set_initiation
    # Précharger associations pour éviter N+1 queries
    @initiation = Event::Initiation.includes(:attendances, :users, :creator_user).find(params[:id])
  end

  def load_supporting_data
    # Pas de routes pour les initiations, mais on garde la méthode pour cohérence
  end

  def next_saturday_at_10_15
    next_saturday = Date.current.next_occurring(:saturday)
    Time.zone.local(next_saturday.year, next_saturday.month, next_saturday.day, 10, 15, 0)
  end

  def can_register?
    return false unless user_signed_in?
    return false if @initiation.full?
    # Permettre l'inscription si le parent n'est pas encore inscrit
    return false if @user_attendance&.persisted?

    # Vérifier adhésion ou essai gratuit disponible
    # Utiliser exists? (optimisé) plutôt que count > 0
    has_membership = current_user.memberships.active_now.exists?
    has_used_trial = current_user.attendances.where(free_trial_used: true).exists?

    has_membership || !has_used_trial
  end
  helper_method :can_register?

  def can_register_child?
    return false unless user_signed_in?
    return false if @initiation.full?
    # Vérifier qu'il y a des adhésions enfants actives disponibles
    child_memberships = current_user.memberships.active_now.where(is_child_membership: true)
    return false if child_memberships.empty?
    
    # Vérifier qu'il reste des enfants non inscrits
    registered_child_ids = @child_attendances.pluck(:child_membership_id).compact
    available_children = child_memberships.where.not(id: registered_child_ids)
    
    available_children.exists?
  end
  helper_method :can_register_child?

  def can_moderate?
    current_user.present? && current_user.role&.level.to_i >= 50 # MODERATOR = 50
  end
  helper_method :can_moderate?

  # Export iCal pour une initiation (réservé aux utilisateurs connectés)
  def ical
    authenticate_user!
    authorize @initiation, :show?

    calendar = Icalendar::Calendar.new
    calendar.prodid = "-//Grenoble Roller//Initiations//FR"

    event_ical = Icalendar::Event.new
    event_ical.dtstart = Icalendar::Values::DateTime.new(@initiation.start_at)
    event_ical.dtend = Icalendar::Values::DateTime.new(@initiation.start_at + @initiation.duration_min.minutes)
    event_ical.summary = @initiation.title
    event_ical.description = @initiation.description.presence || "Cours d'initiation au roller organisé par Grenoble Roller"
    
    # Location avec adresse et coordonnées GPS si disponibles
    if @initiation.has_gps_coordinates?
      event_ical.location = "#{@initiation.location_text} (#{@initiation.meeting_lat},#{@initiation.meeting_lng})"
      event_ical.geo = [@initiation.meeting_lat, @initiation.meeting_lng]
    else
      event_ical.location = @initiation.location_text
    end
    
    event_ical.url = initiation_url(@initiation)
    event_ical.uid = "initiation-#{@initiation.id}@grenobleroller.fr"
    event_ical.last_modified = @initiation.updated_at
    event_ical.created = @initiation.created_at
    event_ical.organizer = Icalendar::Values::CalAddress.new("mailto:noreply@grenobleroller.fr", cn: "Grenoble Roller")

    calendar.add_event(event_ical)

    render plain: calendar.to_ical, content_type: "text/calendar"
  end
end
