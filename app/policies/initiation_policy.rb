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
  
  class Scope < Scope
    def resolve
      scope.published
    end
  end
end

