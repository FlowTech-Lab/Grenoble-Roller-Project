class InitiationsController < ApplicationController
  before_action :set_initiation, only: [:show, :attend, :cancel_attendance]
  before_action :authenticate_user!, only: [:attend, :cancel_attendance]
  
  def index
    # Précharger associations pour éviter N+1 queries
    @initiations = Event::Initiation
      .published
      .upcoming_initiations
      .limit(12) # 3 mois
      .includes(:creator_user, :attendances) # Précharger attendances pour calcul places
    
    @current_season = Membership.current_season_name
  end
  
  def show
    authorize @initiation
    # @initiation déjà chargé avec includes dans set_initiation
    @user_attendance = current_user&.attendances&.find_by(event: @initiation)
    @can_register = can_register?
  end
  
  def attend
    authorize @initiation, :attend?
    
    attendance = @initiation.attendances.find_or_initialize_by(user: current_user)
    
    if attendance.persisted?
      redirect_to @initiation, notice: "Vous êtes déjà inscrit(e)."
      return
    end
    
    attendance.assign_attributes(attendance_params)
    attendance.status = 'registered'
    
    # Gestion essai gratuit (paramètre top-level, pas dans attendance)
    if params[:use_free_trial] == '1'
      if current_user.attendances.where(free_trial_used: true).exists?
        redirect_to @initiation, alert: "Vous avez déjà utilisé votre essai gratuit."
        return
      end
      attendance.free_trial_used = true
    else
      # Vérifier adhésion (parent OU enfant)
      has_active_membership = current_user.memberships.active_now.exists?
      has_child_membership = current_user.memberships.active_now.where(is_child_membership: true).exists?
      
      unless has_active_membership || has_child_membership
        redirect_to @initiation, alert: "Adhésion requise. Utilisez votre essai gratuit ou adhérez à l'association."
        return
      end
    end
    
    if attendance.save
      # Email de confirmation : vérifier wants_initiation_mail pour les initiations
      if current_user.wants_initiation_mail?
        EventMailer.attendance_confirmed(attendance).deliver_later
      end
      redirect_to @initiation, notice: "Inscription confirmée pour le #{l(@initiation.start_at, format: :long)}."
    else
      redirect_to @initiation, alert: attendance.errors.full_messages.to_sentence
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
        redirect_to @initiation, notice: "Inscription annulée."
      else
        redirect_to @initiation, alert: "Impossible d'annuler votre participation."
      end
    else
      redirect_to @initiation, alert: "Impossible d'annuler votre participation."
    end
  end
  
  private
  
  def set_initiation
    # Précharger associations pour éviter N+1 queries
    @initiation = Event::Initiation.includes(:attendances, :users, :creator_user).find(params[:id])
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
end

