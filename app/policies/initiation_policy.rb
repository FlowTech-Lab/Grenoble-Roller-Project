class InitiationPolicy < ApplicationPolicy
  def index?
    true # Tous peuvent voir la liste
  end
  
  def show?
    true # Tous peuvent voir une initiation
  end
  
  def attend?
    return false unless user
    return false if record.full?
    return false if user.attendances.exists?(event: record)
    
    # Vérifier adhésion ou essai gratuit disponible
    user.memberships.active_now.exists? || 
      !user.attendances.where(free_trial_used: true).exists?
  end
  
  def cancel_attendance?
    return false unless user
    user.attendances.exists?(event: record)
  end
  
  def manage?
    user&.role&.level.to_i >= 30 # INSTRUCTOR+
  end
  
  def create?
    user&.role&.level.to_i >= 30 # INSTRUCTOR+
  end
  
  def new?
    create?
  end
  
  def update?
    # L'instructeur peut modifier son initiation, mais pas le statut (sauf modos+)
    owner? || admin? || moderator?
  end
  
  def edit?
    update?
  end
  
  def destroy?
    admin? || owner?
  end
  
  def permitted_attributes
    attrs = [
      :title,
      :start_at,
      :duration_min,
      :description,
      :location_text,
      :meeting_lat,
      :meeting_lng,
      :max_participants,
      :level,
      :distance_km,
      :cover_image
    ]
    
    # Seuls les modérateurs+ peuvent modifier le statut
    attrs << :status if admin? || moderator?
    
    attrs
  end
  
  class Scope < Scope
    def resolve
      if admin? || moderator?
        scope.all
      elsif instructor?
        # Instructeurs voient leurs initiations + les initiations publiées
        scope.where(creator_user_id: user.id).or(scope.published)
      elsif user.present?
        # Utilisateurs connectés voient les initiations publiées + leurs propres initiations
        scope.published.or(scope.where(creator_user_id: user.id))
      else
        # Utilisateurs non connectés voient les initiations publiées
        scope.published
      end
    end
    
    private
    
    def instructor?
      user.present? && user.role&.level.to_i >= 30
    end
    
    def admin?
      user.present? && user.role&.level.to_i >= 60
    end
    
    def moderator?
      user.present? && user.role&.level.to_i >= 50
    end
  end
  
  private
  
  def owner?
    user.present? && record.creator_user_id == user.id
  end
  
  def admin?
    user.present? && user.role&.level.to_i >= 60
  end
  
  def moderator?
    user.present? && user.role&.level.to_i >= 50
  end
end

