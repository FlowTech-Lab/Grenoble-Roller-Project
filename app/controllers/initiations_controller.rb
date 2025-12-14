class InitiationsController < ApplicationController
  before_action :set_initiation, only: [ :show, :edit, :update, :destroy, :attend, :cancel_attendance, :toggle_reminder, :join_waitlist, :leave_waitlist, :convert_waitlist_to_attendance, :refuse_waitlist, :confirm_waitlist, :decline_waitlist ]
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
      # Vérifier si l'utilisateur peut s'inscrire en tant que bénévole (pas encore inscrit en tant que bénévole)
      @user_volunteer_attendance = @user_attendances.find_by(child_membership_id: nil, is_volunteer: true)
      @can_register_as_volunteer = current_user.can_be_volunteer == true && @user_volunteer_attendance.nil?
      
      # Charger les entrées de liste d'attente de l'utilisateur
      @user_waitlist_entries = @initiation.waitlist_entries.where(user: current_user).active.includes(:child_membership)
      @user_waitlist_entry = @user_waitlist_entries.find_by(child_membership_id: nil) # Entrée parent
      @child_waitlist_entries = @user_waitlist_entries.where.not(child_membership_id: nil) # Entrées enfants
    else
      @user_attendances = Attendance.none
      @user_attendance = nil
      @child_attendances = Attendance.none
      @user_volunteer_attendance = nil
      @can_register_as_volunteer = false
      
      # Charger les entrées de liste d'attente de l'utilisateur
      @user_waitlist_entries = WaitlistEntry.none
      @user_waitlist_entry = nil
      @child_waitlist_entries = WaitlistEntry.none
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
    # Stocker les paramètres dans des variables d'instance pour la policy
    @child_membership_id_for_policy = params[:child_membership_id].presence
    @is_volunteer_for_policy = params[:is_volunteer] == "1"
    
    # Autorisation via Pundit (la policy récupérera les valeurs depuis le contrôleur)
    authorize @initiation, :attend?

    child_membership_id = params[:child_membership_id].presence
    is_volunteer = params[:is_volunteer] == "1"
    
    # Validation des paramètres
    needs_equipment = params[:needs_equipment] == "1"
    roller_size = params[:roller_size].presence
    
    # Valider roller_size si needs_equipment est true
    if needs_equipment && roller_size.blank?
      redirect_to initiation_path(@initiation), alert: "Veuillez sélectionner une taille de rollers si vous avez besoin de matériel."
      return
    end
    
    # Valider que roller_size est dans la liste des tailles disponibles
    if needs_equipment && roller_size.present?
      unless RollerStock::SIZES.include?(roller_size)
        redirect_to initiation_path(@initiation), alert: "La taille de rollers sélectionnée n'est pas valide."
        return
      end
    end
    
    # Log de la tentative d'inscription
    Rails.logger.info("Tentative d'inscription - User: #{current_user.id}, Initiation: #{@initiation.id}, Child: #{child_membership_id}, Volunteer: #{is_volunteer}")

    attendance = @initiation.attendances.build(user: current_user)
    attendance.status = "registered"
    # Lire les paramètres directement au niveau racine (comme EventsController)
    attendance.wants_reminder = params[:wants_reminder].present? ? params[:wants_reminder] == "1" : false
    attendance.needs_equipment = needs_equipment
    attendance.roller_size = roller_size if needs_equipment
    attendance.child_membership_id = child_membership_id
    
    # Gestion bénévole (uniquement pour le parent, pas pour les enfants)
    if is_volunteer && child_membership_id.nil?
      unless current_user.can_be_volunteer?
        redirect_to initiation_path(@initiation), alert: "Vous n'êtes pas autorisé à vous inscrire en tant que bénévole."
        return
      end
      attendance.is_volunteer = true
      # Les bénévoles n'ont pas besoin d'adhésion, on skip les vérifications
      if attendance.save
        Rails.logger.info("Inscription bénévole réussie - Attendance: #{attendance.id}, User: #{current_user.id}, Initiation: #{@initiation.id}")
        EventMailer.attendance_confirmed(attendance).deliver_later if current_user.wants_initiation_mail?
        redirect_to initiation_path(@initiation), notice: "Inscription confirmée en tant que bénévole encadrant le #{l(@initiation.start_at, format: :long)}."
      else
        Rails.logger.warn("Échec inscription bénévole - User: #{current_user.id}, Initiation: #{@initiation.id}, Errors: #{attendance.errors.full_messages.join(', ')}")
        redirect_to initiation_path(@initiation), alert: attendance.errors.full_messages.to_sentence
      end
      return
    end

    # Vérifier si l'utilisateur est adhérent
    is_member = if child_membership_id.present?
      # Pour un enfant : vérifier l'adhésion enfant
      child_membership = current_user.memberships.find_by(id: child_membership_id)
      unless child_membership&.active?
        redirect_to initiation_path(@initiation), alert: "L'adhésion de cet enfant n'est pas active."
        return
      end
      true
    else
      # Pour le parent : vérifier adhésion parent ou enfant
      current_user.memberships.active_now.exists? ||
        current_user.memberships.active_now.where(is_child_membership: true).exists?
    end

    # Gestion essai gratuit et vérification adhésion
    if child_membership_id.nil? && !is_member
      # Non-adhérent parent : vérifier si l'option de découverte est activée
      if @initiation.allow_non_member_discovery?
        # Option activée : vérifier qu'il reste des places découverte
        if @initiation.full_for_non_members?
          redirect_to initiation_path(@initiation), alert: "Les places pour non-adhérents sont complètes. Adhérez à l'association pour continuer."
          return
        end
        # Les non-adhérents peuvent s'inscrire dans les places découverte (pas besoin d'essai gratuit)
        # L'essai gratuit n'est utilisé que si explicitement demandé
        if params[:use_free_trial] == "1"
          if current_user.attendances.where(free_trial_used: true).exists?
            redirect_to initiation_path(@initiation), alert: "Vous avez déjà utilisé votre essai gratuit."
            return
          end
          attendance.free_trial_used = true
        end
      else
        # Option non activée : comportement classique - adhésion ou essai gratuit requis
        if params[:use_free_trial] == "1"
          if current_user.attendances.where(free_trial_used: true).exists?
            redirect_to initiation_path(@initiation), alert: "Vous avez déjà utilisé votre essai gratuit."
            return
          end
          attendance.free_trial_used = true
        else
          redirect_to initiation_path(@initiation), alert: "Adhésion requise. Utilisez votre essai gratuit ou adhérez à l'association."
          return
        end
      end
    end

    if attendance.save
      Rails.logger.info("Inscription réussie - Attendance: #{attendance.id}, User: #{current_user.id}, Initiation: #{@initiation.id}, Type: #{attendance.for_child? ? 'Enfant' : (attendance.is_volunteer ? 'Bénévole' : 'Participant')}")
      # Email de confirmation : vérifier wants_initiation_mail pour les initiations
      if current_user.wants_initiation_mail?
        EventMailer.attendance_confirmed(attendance).deliver_later
      end
      participant_name = attendance.for_child? ? attendance.participant_name : "Vous"
      type_message = attendance.is_volunteer ? "en tant que bénévole encadrant" : ""
      redirect_to initiation_path(@initiation), notice: "Inscription confirmée #{type_message} pour #{participant_name} le #{l(@initiation.start_at, format: :long)}."
    else
      Rails.logger.warn("Échec inscription - User: #{current_user.id}, Initiation: #{@initiation.id}, Errors: #{attendance.errors.full_messages.join(', ')}")
      # Améliorer les messages d'erreur
      error_message = if attendance.errors[:base].any?
        attendance.errors[:base].first
      elsif attendance.errors[:event].any?
        attendance.errors[:event].first
      elsif attendance.errors[:child_membership_id].any?
        attendance.errors[:child_membership_id].first
      elsif attendance.errors[:free_trial_used].any?
        attendance.errors[:free_trial_used].first
      else
        attendance.errors.full_messages.to_sentence
      end
      # Si l'événement est complet, proposer la liste d'attente
      if @initiation.full? && attendance.errors[:event].any?
        redirect_to initiation_path(@initiation), alert: "Cet événement est complet. #{error_message} Souhaitez-vous être ajouté(e) à la liste d'attente ?"
      else
        redirect_to initiation_path(@initiation), alert: error_message
      end
    end
  end

  def join_waitlist
    authorize @initiation, :join_waitlist? # Utiliser la policy spécifique pour la liste d'attente
    
    child_membership_id = params[:child_membership_id].presence
    needs_equipment = params[:needs_equipment] == "1"
    roller_size = params[:roller_size].presence
    wants_reminder = params[:wants_reminder].present? ? params[:wants_reminder] == "1" : false
    use_free_trial = params[:use_free_trial] == "1"
    
    # Vérifier que l'utilisateur peut utiliser l'essai gratuit si demandé
    if use_free_trial && current_user.attendances.where(free_trial_used: true).exists?
      redirect_to initiation_path(@initiation), alert: "Vous avez déjà utilisé votre essai gratuit."
      return
    end
    
    if needs_equipment && roller_size.blank?
      redirect_to initiation_path(@initiation), alert: "Veuillez sélectionner une taille de rollers si vous avez besoin de matériel."
      return
    end
    if needs_equipment && roller_size.present?
      unless RollerStock::SIZES.include?(roller_size)
        redirect_to initiation_path(@initiation), alert: "La taille de rollers sélectionnée n'est pas valide."
        return
      end
    end
    
    waitlist_entry = WaitlistEntry.add_to_waitlist(
      current_user,
      @initiation,
      child_membership_id: child_membership_id,
      needs_equipment: needs_equipment,
      roller_size: roller_size,
      wants_reminder: wants_reminder,
      use_free_trial: use_free_trial
    )
    
    if waitlist_entry
      participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
      redirect_to initiation_path(@initiation), notice: "#{participant_name} avez été ajouté(e) à la liste d'attente. Vous serez notifié(e) par email si une place se libère."
    else
      redirect_to initiation_path(@initiation), alert: "Impossible d'ajouter à la liste d'attente. Vérifiez que l'événement est complet et que vous n'êtes pas déjà inscrit(e) ou en liste d'attente."
    end
  end

  def leave_waitlist
    authorize @initiation
    
    child_membership_id = params[:child_membership_id].presence
    
    waitlist_entry = @initiation.waitlist_entries.find_by(
      user: current_user,
      child_membership_id: child_membership_id,
      status: ["pending", "notified"]
    )
    
    if waitlist_entry
      participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
      waitlist_entry.cancel!
      redirect_to initiation_path(@initiation), notice: "#{participant_name} avez été retiré(e) de la liste d'attente."
    else
      redirect_to initiation_path(@initiation), alert: "Vous n'êtes pas en liste d'attente pour cet événement."
    end
  end

  def convert_waitlist_to_attendance
    authorize @initiation, :convert_waitlist_to_attendance?

    waitlist_entry_id = params[:waitlist_entry_id]
    waitlist_entry = @initiation.waitlist_entries.find_by_hashid(waitlist_entry_id)
    
    unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
      redirect_to initiation_path(@initiation), alert: "Entrée de liste d'attente introuvable ou non notifiée."
      return
    end
    
    # Vérifier que l'inscription "pending" existe toujours
    pending_attendance = @initiation.attendances.find_by(
      user: current_user,
      child_membership_id: waitlist_entry.child_membership_id,
      status: "pending"
    )
    
    unless pending_attendance
      redirect_to initiation_path(@initiation), alert: "La place réservée n'est plus disponible. Vous restez en liste d'attente."
      return
    end
    
    if waitlist_entry.convert_to_attendance!
      participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
      EventMailer.attendance_confirmed(pending_attendance.reload).deliver_later if current_user.wants_initiation_mail?
      redirect_to initiation_path(@initiation), notice: "Inscription confirmée pour #{participant_name} ! Vous avez été retiré(e) de la liste d'attente."
    else
      redirect_to initiation_path(@initiation), alert: "Impossible de confirmer votre inscription. Veuillez réessayer."
    end
  end
  
  def refuse_waitlist
    authorize @initiation, :refuse_waitlist?

    waitlist_entry_id = params[:waitlist_entry_id]
    waitlist_entry = @initiation.waitlist_entries.find_by_hashid(waitlist_entry_id)
    
    unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
      redirect_to initiation_path(@initiation), alert: "Entrée de liste d'attente introuvable ou non notifiée."
      return
    end
    
    if waitlist_entry.refuse!
      participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
      redirect_to initiation_path(@initiation), notice: "Vous avez refusé la place pour #{participant_name}. Vous restez en liste d'attente et serez notifié(e) si une autre place se libère."
    else
      redirect_to initiation_path(@initiation), alert: "Impossible de refuser la place. Veuillez réessayer."
    end
  end

  # Route GET pour confirmer depuis un email (redirige vers convert_waitlist_to_attendance en POST)
  def confirm_waitlist
    authenticate_user!
    authorize @initiation, :convert_waitlist_to_attendance?

    waitlist_entry_id = params[:waitlist_entry_id]
    waitlist_entry = @initiation.waitlist_entries.find_by_hashid(waitlist_entry_id)
    
    unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
      redirect_to initiation_path(@initiation), alert: "Entrée de liste d'attente introuvable ou non notifiée."
      return
    end
    
    # Appeler la méthode POST via convert_to_attendance!
    if waitlist_entry.convert_to_attendance!
      participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
      redirect_to initiation_path(@initiation), notice: "Inscription confirmée pour #{participant_name} ! Vous avez été retiré(e) de la liste d'attente."
    else
      redirect_to initiation_path(@initiation), alert: "Impossible de confirmer votre inscription. Veuillez réessayer."
    end
  end

  # Route GET pour refuser depuis un email (redirige vers refuse_waitlist en POST)
  def decline_waitlist
    authenticate_user!
    authorize @initiation, :refuse_waitlist?

    waitlist_entry_id = params[:waitlist_entry_id]
    waitlist_entry = @initiation.waitlist_entries.find_by_hashid(waitlist_entry_id)
    
    unless waitlist_entry && waitlist_entry.user == current_user && waitlist_entry.notified?
      redirect_to initiation_path(@initiation), alert: "Entrée de liste d'attente introuvable ou non notifiée."
      return
    end
    
    if waitlist_entry.refuse!
      participant_name = waitlist_entry.for_child? ? waitlist_entry.participant_name : "Vous"
      redirect_to initiation_path(@initiation), notice: "Vous avez refusé la place pour #{participant_name}. Vous restez en liste d'attente et serez notifié(e) si une autre place se libère."
    else
      redirect_to initiation_path(@initiation), alert: "Impossible de refuser la place. Veuillez réessayer."
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

  def toggle_reminder
    authenticate_user!
    authorize @initiation, :cancel_attendance? # Même permission que cancel_attendance

    # Pour les initiations, le rappel est global (1 email par compte)
    # On active/désactive le rappel pour toutes les inscriptions (parent + enfants)
    user_attendances = @initiation.attendances.where(user: current_user)
    
    if user_attendances.any?
      # Déterminer l'état actuel : si au moins une inscription a le rappel activé, on désactive tout
      # Sinon, on active tout
      any_reminder_active = user_attendances.any? { |a| a.wants_reminder? }
      new_reminder_state = !any_reminder_active
      
      # Mettre à jour toutes les inscriptions
      user_attendances.update_all(wants_reminder: new_reminder_state)
      
      message = new_reminder_state ? 
        "Rappel activé. Vous recevrez un email la veille à 19h pour vous rappeler la séance." : 
        "Rappel désactivé."
      redirect_to initiation_path(@initiation), notice: message
    else
      redirect_to initiation_path(@initiation), alert: "Vous n'êtes pas inscrit(e) à cette séance."
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

    # Les bénévoles peuvent toujours s'inscrire (même sans adhésion)
    return true if current_user.can_be_volunteer?

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
end
