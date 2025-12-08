class InitiationsController < ApplicationController
  before_action :set_initiation, only: [:show, :edit, :update, :destroy, :attend, :cancel_attendance]
  before_action :authenticate_user!, except: [:index, :show]
  before_action :load_supporting_data, only: [:new, :create, :edit, :update]
  
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
    @user_attendance = current_user&.attendances&.find_by(event: @initiation)
    @can_register = can_register?
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
      level: 'beginner',
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
    
    attendance = @initiation.attendances.find_or_initialize_by(user: current_user)
    
    if attendance.persisted?
      redirect_to initiation_path(@initiation), notice: "Vous êtes déjà inscrit(e)."
      return
    end
    
    attendance.assign_attributes(attendance_params)
    attendance.status = 'registered'
    
    # Gestion essai gratuit (paramètre top-level, pas dans attendance)
    if params[:use_free_trial] == '1'
      if current_user.attendances.where(free_trial_used: true).exists?
        redirect_to initiation_path(@initiation), alert: "Vous avez déjà utilisé votre essai gratuit."
        return
      end
      attendance.free_trial_used = true
    else
      # Vérifier adhésion (parent OU enfant)
      has_active_membership = current_user.memberships.active_now.exists?
      has_child_membership = current_user.memberships.active_now.where(is_child_membership: true).exists?
      
      unless has_active_membership || has_child_membership
        redirect_to initiation_path(@initiation), alert: "Adhésion requise. Utilisez votre essai gratuit ou adhérez à l'association."
        return
      end
    end
    
    if attendance.save
      # Email de confirmation : vérifier wants_initiation_mail pour les initiations
      if current_user.wants_initiation_mail?
        EventMailer.attendance_confirmed(attendance).deliver_later
      end
      redirect_to initiation_path(@initiation), notice: "Inscription confirmée pour le #{l(@initiation.start_at, format: :long)}."
    else
      redirect_to initiation_path(@initiation), alert: attendance.errors.full_messages.to_sentence
    end
  end
  
  def cancel_attendance
    authorize @initiation, :cancel_attendance?
    
    attendance = @initiation.attendances.find_by(user: current_user)
    if attendance
      wants_initiation_mail = current_user.wants_initiation_mail?
      if attendance.destroy
        # Email d'annulation : vérifier wants_initiation_mail pour les initiations
        if wants_initiation_mail
          EventMailer.attendance_cancelled(current_user, @initiation).deliver_later
        end
        redirect_to initiation_path(@initiation), notice: "Inscription annulée."
      else
        redirect_to initiation_path(@initiation), alert: "Impossible d'annuler votre participation."
      end
    else
      redirect_to initiation_path(@initiation), alert: "Impossible d'annuler votre participation."
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
  
  
  def attendance_params
    # child_membership_id si c'est un enfant qui s'inscrit
    params.require(:attendance).permit(:wants_reminder, :equipment_note, :child_membership_id)
  end
  
  def can_register?
    return false unless user_signed_in?
    return false if @initiation.full?
    return false if @user_attendance&.persisted?
    
    # Vérifier adhésion ou essai gratuit disponible
    # Utiliser exists? (optimisé) plutôt que count > 0
    has_membership = current_user.memberships.active_now.exists?
    has_used_trial = current_user.attendances.where(free_trial_used: true).exists?
    
    has_membership || !has_used_trial
  end
  helper_method :can_register?
  
  def can_moderate?
    current_user.present? && current_user.role&.level.to_i >= 50 # MODERATOR = 50
  end
  helper_method :can_moderate?
end

