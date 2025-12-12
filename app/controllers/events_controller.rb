class EventsController < ApplicationController
  before_action :set_event, only: %i[show edit update destroy attend cancel_attendance ical toggle_reminder loop_routes reject join_waitlist leave_waitlist convert_waitlist_to_attendance refuse_waitlist confirm_waitlist decline_waitlist]
  before_action :authenticate_user!, except: %i[index show]
  before_action :ensure_email_confirmed, only: [ :attend ] # Exiger confirmation pour s'inscrire à un événement
  before_action :load_supporting_data, only: %i[new create edit update]

  def index
    scoped_events = policy_scope(Event.includes(:route, :creator_user))
    # Les admins/moderateurs voient tous les événements via policy_scope
    # Pour les autres, policy_scope filtre déjà pour ne montrer que les visibles
    # On applique .visible seulement si l'utilisateur n'est pas admin/modo pour éviter de cacher les non publiés aux admins
    if can_moderate?
      # Admins/moderateurs voient tout (y compris les non publiés)
      @upcoming_events = scoped_events.upcoming.order(:start_at)
      @past_events_total = scoped_events.past.count
      if params[:show_all_past] == 'true'
        @past_events = scoped_events.past.order(start_at: :desc)
      else
        @past_events = scoped_events.past.order(start_at: :desc).limit(6)
      end
    else
      # Utilisateurs normaux voient seulement les événements visibles (publiés/annulés)
      @upcoming_events = scoped_events.visible.upcoming.order(:start_at)
      @past_events_total = scoped_events.visible.past.count
      if params[:show_all_past] == 'true'
        @past_events = scoped_events.visible.past.order(start_at: :desc)
      else
        @past_events = scoped_events.visible.past.order(start_at: :desc).limit(6)
      end
    end
  end

  def show
    authorize @event
    # Rediriger si l'événement n'est pas visible (publié ou annulé) et que l'utilisateur n'est pas modo+ ou créateur
    unless @event.published? || @event.canceled? || can_moderate? || @event.creator_user_id == current_user&.id
      redirect_to events_path, alert: "Cet événement n'est pas encore publié."
    end
    # Récupérer toutes les attendances de l'utilisateur (parent + enfants)
    if user_signed_in?
      @user_attendances = @event.attendances.where(user: current_user).includes(:child_membership)
      @user_attendance = @user_attendances.find_by(child_membership_id: nil) # Inscription parent
      @child_attendances = @user_attendances.where.not(child_membership_id: nil) # Inscriptions enfants
      
      # Charger les entrées de liste d'attente de l'utilisateur
      @user_waitlist_entries = @event.waitlist_entries.where(user: current_user).active.includes(:child_membership)
      @user_waitlist_entry = @user_waitlist_entries.find_by(child_membership_id: nil) # Entrée parent
      @child_waitlist_entries = @user_waitlist_entries.where.not(child_membership_id: nil) # Entrées enfants
    else
      @user_attendances = Attendance.none
      @user_attendance = nil
      @child_attendances = Attendance.none
      @user_waitlist_entries = WaitlistEntry.none
      @user_waitlist_entry = nil
      @child_waitlist_entries = WaitlistEntry.none
    end
    @can_register_child = can_register_child?
  end

  def can_moderate?
    current_user.present? && current_user.role&.level.to_i >= 50 # MODERATOR = 50
  end
  helper_method :can_moderate?

  def can_register_child?
    return false unless user_signed_in?
    return false if @event.full?
    # Vérifier qu'il y a des adhésions enfants actives disponibles
    child_memberships = current_user.memberships.active_now.where(is_child_membership: true)
    return false if child_memberships.empty?
    
    # Vérifier qu'il reste des enfants non inscrits
    # Si @child_attendances n'est pas défini (pas encore d'inscription), on peut inscrire n'importe quel enfant
    if @child_attendances.nil? || @child_attendances.empty?
      return child_memberships.exists?
    end
    
    registered_child_ids = @child_attendances.pluck(:child_membership_id).compact
    available_children = child_memberships.where.not(id: registered_child_ids)
    
    available_children.exists?
  end
  helper_method :can_register_child?

  def new
    @event = current_user.created_events.build(
      status: "draft", # Toujours en brouillon à la création (en attente de validation)
      start_at: Time.zone.now.change(min: 0),
      duration_min: 60,
      max_participants: 0, # 0 = illimité par défaut
      currency: "EUR" # Toujours EUR
    )
    authorize @event
  end

  def create
    @event = current_user.created_events.build
    authorize @event

    event_params = permitted_attributes(@event)
    # Toujours EUR
    event_params[:currency] = "EUR"
    # Toujours en draft à la création (en attente de validation par un modérateur)
    event_params[:status] = "draft"
    # Convertir le prix en euros en centimes
    if params[:price_euros].present?
      event_params[:price_cents] = (params[:price_euros].to_f * 100).round
    end

    # Initialiser loops_count à 1 si non défini
    event_params[:loops_count] ||= 1
    
    # Gérer les parcours par boucle
    loop_routes_params = params[:event_loop_routes] || {}
    
    if @event.update(event_params)
      # Sauvegarder les parcours par boucle
      save_loop_routes(@event, loop_routes_params)
      
      redirect_to @event, notice: "Événement créé avec succès. Il est en attente de validation par un modérateur."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @event
  end

  def update
    authorize @event

    event_params = permitted_attributes(@event)
    # Toujours EUR
    event_params[:currency] = "EUR"

    # Seuls les modérateurs+ peuvent changer le statut
    unless current_user.role&.level.to_i >= 50 # MODERATOR = 50
      event_params.delete(:status) # Retirer le statut des params si l'utilisateur n'est pas modo+
    end

    # Convertir le prix en euros en centimes
    if params[:price_euros].present?
      event_params[:price_cents] = (params[:price_euros].to_f * 100).round
    end

    # Initialiser loops_count à 1 si non défini
    event_params[:loops_count] ||= 1
    
    # Gérer les parcours par boucle
    loop_routes_params = params[:event_loop_routes] || {}
    
    if @event.update(event_params)
      # Sauvegarder les parcours par boucle
      save_loop_routes(@event, loop_routes_params)
      
      redirect_to @event, notice: "Événement mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @event
    @event.destroy

    redirect_to events_path, notice: "Événement supprimé."
  end

  def reject
    authorize @event, :reject?
    
    if @event.update(status: :rejected)
      # Envoyer un email au créateur pour le notifier du refus
      EventMailer.event_rejected(@event).deliver_later
      redirect_to events_path, notice: "L'événement a été refusé et le créateur a été notifié par email."
    else
      redirect_to @event, alert: "Impossible de refuser cet événement."
    end
  end

  def attend
    authenticate_user!
    authorize @event, :attend?

    child_membership_id = params[:child_membership_id].presence
    
    # Si c'est pour un enfant, vérifier qu'il n'est pas déjà inscrit
    if child_membership_id.present?
      existing_attendance = @event.attendances.find_by(
        user: current_user,
        child_membership_id: child_membership_id
      )
      if existing_attendance
        child_name = Membership.find_by(id: child_membership_id)&.child_full_name || "cet enfant"
        redirect_to @event, notice: "#{child_name} est déjà inscrit(e) à cet événement."
        return
      end
    else
      # Si c'est pour le parent, vérifier qu'il n'est pas déjà inscrit
      existing_attendance = @event.attendances.find_by(
        user: current_user,
        child_membership_id: nil
      )
      if existing_attendance
        redirect_to @event, notice: "Vous êtes déjà inscrit(e) à cet événement."
        return
      end
    end

    attendance = @event.attendances.build(user: current_user)
    attendance.status = "registered"
    # Accepter wants_reminder depuis les params (formulaire ou paramètre direct)
    attendance.wants_reminder = params[:wants_reminder].present? ? params[:wants_reminder] == "1" : false
    attendance.child_membership_id = child_membership_id

    # Pour les événements : pas d'adhésion requise pour le parent
    # Pour un enfant : vérifier que l'adhésion enfant est active (nécessaire pour identifier l'enfant)
    if child_membership_id.present?
      child_membership = current_user.memberships.find_by(id: child_membership_id)
      unless child_membership&.active?
        redirect_to @event, alert: "L'adhésion de cet enfant n'est pas active."
        return
      end
    end

    if attendance.save
      EventMailer.attendance_confirmed(attendance).deliver_later
      participant_name = attendance.for_child? ? attendance.participant_name : "Vous"
      event_date = l(@event.start_at, format: :event_long, locale: :fr)
      redirect_to @event, notice: "Inscription confirmée pour #{participant_name} ! À bientôt le #{event_date}."
    else
      # Si l'événement est complet, proposer la liste d'attente
      if @event.full? && attendance.errors[:event].any?
        redirect_to @event, alert: "Cet événement est complet. #{attendance.errors.full_messages.to_sentence} Souhaitez-vous être ajouté(e) à la liste d'attente ?"
      else
        redirect_to @event, alert: attendance.errors.full_messages.to_sentence
      end
    end
  end

  def join_waitlist
    authorize @event, :join_waitlist?
    
    child_membership_id = params[:child_membership_id].presence
    wants_reminder = params[:wants_reminder].present? ? params[:wants_reminder] == "1" : false
    
    waitlist_entry = WaitlistEntry.add_to_waitlist(
      current_user,
      @event,
      child_membership_id: child_membership_id,
      needs_equipment: false, # Pas de matériel pour les événements/randos
      roller_size: nil,
      wants_reminder: wants_reminder
    )
    
    if waitlist_entry
      participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
      redirect_to @event, notice: "#{participant_name} avez été ajouté(e) à la liste d'attente. Vous serez notifié(e) par email si une place se libère."
    else
      redirect_to @event, alert: "Impossible d'ajouter à la liste d'attente. Vérifiez que l'événement est complet et que vous n'êtes pas déjà inscrit(e) ou en liste d'attente."
    end
  end

  def leave_waitlist
    authorize @event, :leave_waitlist?
    
    child_membership_id = params[:child_membership_id].presence
    
    waitlist_entry = @event.waitlist_entries.find_by(
      user: current_user,
      child_membership_id: child_membership_id,
      status: ["pending", "notified"]
    )
    
    if waitlist_entry
      participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
      waitlist_entry.cancel!
      redirect_to @event, notice: "#{participant_name} avez été retiré(e) de la liste d'attente."
    else
      redirect_to @event, alert: "Vous n'êtes pas en liste d'attente pour cet événement."
    end
  end

  def convert_waitlist_to_attendance
    authorize @event, :convert_waitlist_to_attendance?

    waitlist_entry_id = params[:waitlist_entry_id]
    waitlist_entry = @event.waitlist_entries.find_by_hashid(waitlist_entry_id)
    
    unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
      redirect_to @event, alert: "Entrée de liste d'attente introuvable ou non notifiée."
      return
    end
    
    # Vérifier que l'inscription "pending" existe toujours
    pending_attendance = @event.attendances.find_by(
      user: current_user,
      child_membership_id: waitlist_entry.child_membership_id,
      status: "pending"
    )
    
    unless pending_attendance
      redirect_to @event, alert: "La place réservée n'est plus disponible. Vous restez en liste d'attente."
      return
    end
    
    if waitlist_entry.convert_to_attendance!
      participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
      EventMailer.attendance_confirmed(pending_attendance.reload).deliver_later if current_user.wants_events_mail?
      redirect_to @event, notice: "Inscription confirmée pour #{participant_name} ! Vous avez été retiré(e) de la liste d'attente."
    else
      redirect_to @event, alert: "Impossible de confirmer votre inscription. Veuillez réessayer."
    end
  end
  
  def refuse_waitlist
    authorize @event, :refuse_waitlist?

    waitlist_entry_id = params[:waitlist_entry_id]
    waitlist_entry = @event.waitlist_entries.find_by_hashid(waitlist_entry_id)
    
    unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
      redirect_to @event, alert: "Entrée de liste d'attente introuvable ou non notifiée."
      return
    end
    
    if waitlist_entry.refuse!
      participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
      redirect_to @event, notice: "Vous avez refusé la place pour #{participant_name}. Vous restez en liste d'attente et serez notifié(e) si une autre place se libère."
    else
      redirect_to @event, alert: "Impossible de refuser la place. Veuillez réessayer."
    end
  end

  # Route GET pour confirmer depuis un email (redirige vers convert_waitlist_to_attendance en POST)
  def confirm_waitlist
    authenticate_user!
    authorize @event, :convert_waitlist_to_attendance?

    waitlist_entry_id = params[:waitlist_entry_id]
    waitlist_entry = @event.waitlist_entries.find_by_hashid(waitlist_entry_id)
    
    unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
      redirect_to event_path(@event), alert: "Entrée de liste d'attente introuvable ou non notifiée."
      return
    end
    
    # Appeler la méthode POST via convert_to_attendance!
    if waitlist_entry.convert_to_attendance!
      participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
      redirect_to event_path(@event), notice: "Inscription confirmée pour #{participant_name} ! Vous avez été retiré(e) de la liste d'attente."
    else
      redirect_to event_path(@event), alert: "Impossible de confirmer votre inscription. Veuillez réessayer."
    end
  end

  # Route GET pour refuser depuis un email (redirige vers refuse_waitlist en POST)
  def decline_waitlist
    authenticate_user!
    authorize @event, :refuse_waitlist?

    waitlist_entry_id = params[:waitlist_entry_id]
    waitlist_entry = @event.waitlist_entries.find_by_hashid(waitlist_entry_id)
    
    unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
      redirect_to event_path(@event), alert: "Entrée de liste d'attente introuvable ou non notifiée."
      return
    end
    
    if waitlist_entry.refuse!
      participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
      redirect_to event_path(@event), notice: "Vous avez refusé la place pour #{participant_name}. Vous avez été retiré(e) de la liste d'attente."
    else
      redirect_to event_path(@event), alert: "Impossible de refuser la place. Veuillez réessayer."
    end
  end

  def cancel_attendance
    authenticate_user!
    authorize @event, :cancel_attendance?

    # Permettre de désinscrire soi-même ou un enfant spécifique
    child_membership_id = params[:child_membership_id].presence
    
    attendance = if child_membership_id.present?
      # Désinscrire un enfant spécifique
      @event.attendances.find_by(
        user: current_user,
        child_membership_id: child_membership_id
      )
    else
      # Désinscrire le parent (child_membership_id est NULL)
      @event.attendances.where(
        user: current_user
      ).where(child_membership_id: nil).first
    end

    if attendance
      participant_name = attendance.for_child? ? attendance.participant_name : "vous"
      wants_events_mail = current_user.wants_events_mail?
      if attendance.destroy
        # Notifier la prochaine personne en liste d'attente si une place se libère
        WaitlistEntry.notify_next_in_queue(@event) if @event.full?
        if wants_events_mail && attendance.for_parent?
          EventMailer.attendance_cancelled(current_user, @event).deliver_later
        end
        redirect_to @event, notice: "Inscription de #{participant_name} annulée."
      else
        redirect_to @event, alert: "Impossible d'annuler cette inscription."
      end
    else
      redirect_to @event, alert: "Inscription introuvable."
    end
  end

  # Active/désactive le rappel la veille à 19h pour l'utilisateur inscrit
  # Le rappel est global (1 email par compte) pour toutes les inscriptions (parent + enfants)
  def toggle_reminder
    authenticate_user!
    authorize @event, :cancel_attendance? # Même permission que cancel_attendance

    # Pour les événements, le rappel est global (1 email par compte)
    # On active/désactive le rappel pour toutes les inscriptions (parent + enfants)
    user_attendances = @event.attendances.where(user: current_user)
    
    if user_attendances.any?
      # Déterminer l'état actuel : si au moins une inscription a le rappel activé, on désactive tout
      # Sinon, on active tout
      any_reminder_active = user_attendances.any? { |a| a.wants_reminder? }
      new_reminder_state = !any_reminder_active
      
      # Mettre à jour toutes les inscriptions
      user_attendances.update_all(wants_reminder: new_reminder_state)
      
      message = new_reminder_state ? 
        "Rappel activé. Vous recevrez un email la veille à 19h pour vous rappeler l'événement." : 
        "Rappel désactivé."
      redirect_to @event, notice: message
    else
      redirect_to @event, alert: "Vous n'êtes pas inscrit(e) à cet événement."
    end
  end

  # Export iCal pour un événement (réservé aux utilisateurs connectés)
  def ical
    authenticate_user!
    authorize @event, :show?

    calendar = Icalendar::Calendar.new
    calendar.prodid = "-//Grenoble Roller//Events//FR"

    event_ical = Icalendar::Event.new
    event_ical.dtstart = Icalendar::Values::DateTime.new(@event.start_at)
    event_ical.dtend = Icalendar::Values::DateTime.new(@event.start_at + @event.duration_min.minutes)
    event_ical.summary = @event.title
    event_ical.description = @event.description.presence || "Événement organisé par #{@event.creator_user.first_name}"
    
    # Location avec adresse et coordonnées GPS si disponibles
    if @event.has_gps_coordinates?
      # Format iCal : adresse avec coordonnées GPS dans le champ location
      event_ical.location = "#{@event.location_text} (#{@event.meeting_lat},#{@event.meeting_lng})"
      # Ajout du champ GEO pour les coordonnées GPS (standard iCal RFC 5545)
      # Format: [latitude, longitude]
      event_ical.geo = [@event.meeting_lat, @event.meeting_lng]
    else
      event_ical.location = @event.location_text
    end
    
    event_ical.url = event_url(@event)
    event_ical.uid = "event-#{@event.id}@grenobleroller.fr"
    event_ical.last_modified = @event.updated_at
    event_ical.created = @event.created_at
    event_ical.organizer = Icalendar::Values::CalAddress.new("mailto:noreply@grenobleroller.fr", cn: "Grenoble Roller")

    calendar.add_event(event_ical)
    calendar.publish

    send_data calendar.to_ical,
              filename: "#{@event.title.parameterize}.ics",
              type: "text/calendar; charset=utf-8",
              disposition: "attachment"
  end

  # Retourner les parcours par boucle en JSON (pour le formulaire)
  def loop_routes
    authorize @event, :show?
    
    loop_routes_data = @event.event_loop_routes.where('loop_number > 1').order(:loop_number).map do |elr|
      {
        loop_number: elr.loop_number,
        route_id: elr.route_id,
        distance_km: elr.distance_km
      }
    end
    
    render json: loop_routes_data
  end

  private

  def set_event
    @event = Event.includes(:route, :creator_user, event_loop_routes: :route).find(params[:id])
    # Charger l'attendance de l'utilisateur connecté si présent
    @user_attendance = current_user&.attendances&.find_by(event: @event) if user_signed_in?
  end

  def load_supporting_data
    @routes = Route.order(:name)
  end

  # Sauvegarder les parcours par boucle
  def save_loop_routes(event, loop_routes_params)
    # Supprimer les anciens parcours par boucle
    event.event_loop_routes.destroy_all
    
    # Si plusieurs boucles, sauvegarder le parcours principal pour la boucle 1
    if event.loops_count && event.loops_count > 1 && event.route_id.present? && event.distance_km.present?
      event.event_loop_routes.create!(
        loop_number: 1,
        route_id: event.route_id,
        distance_km: event.distance_km
      )
    end
    
    # Créer les parcours pour les boucles supplémentaires (2, 3, etc.)
    loop_routes_params.each do |loop_number_str, route_data|
      next unless route_data[:route_id].present? && route_data[:distance_km].present?
      
      loop_number = loop_number_str.to_i
      route_id = route_data[:route_id].to_i
      distance_km = route_data[:distance_km].to_f
      
      # Ignorer la boucle 1 (déjà gérée avec le parcours principal)
      next if loop_number < 2 || route_id < 1 || distance_km < 0.1
      
      event.event_loop_routes.create!(
        loop_number: loop_number,
        route_id: route_id,
        distance_km: distance_km
      )
    end
  end
end
