class Event::InitiationPolicy < ApplicationPolicy
  def index?
    true # Tous peuvent voir la liste
  end

  def show?
    true # Tous peuvent voir une initiation
  end

  def attend?
    return false unless user
    return false if record.full?
    
    # Vérifier si l'utilisateur est déjà inscrit en tant que parent
    parent_already_registered = user.attendances.exists?(event: record, child_membership_id: nil)
    
    # Si le parent est déjà inscrit, autoriser uniquement si l'utilisateur a des enfants avec des adhésions actives
    # (pour permettre l'inscription d'enfants supplémentaires)
    if parent_already_registered
      # Autoriser si l'utilisateur a des enfants avec des adhésions actives
      return user.memberships.active_now.where(is_child_membership: true).exists?
    end

    # Vérifier si l'utilisateur est adhérent
    is_member = user.memberships.active_now.exists? || 
                user.memberships.active_now.where(is_child_membership: true).exists?

    # Si l'option de limitation des non-adhérents est activée
    if record.allow_non_member_discovery?
      if is_member
        # Adhérent : vérifier qu'il reste des places pour adhérents
        return false if record.full_for_members?
        return true
      else
        # Non-adhérent : vérifier qu'il reste des places pour non-adhérents
        return false if record.full_for_non_members?
        # Autoriser l'inscription dans les places découverte (pas besoin d'essai gratuit)
        return true
      end
    end

    # Si l'option n'est pas activée : comportement classique
    # Vérifier adhésion ou essai gratuit disponible
    is_member || !user.attendances.where(free_trial_used: true).exists?
  end

  def cancel_attendance?
    return false unless user
    user.attendances.exists?(event: record)
  end

  def manage?
    user&.role&.level.to_i >= 30 # INSTRUCTOR+
  end

  def create?
    # Seuls les admins peuvent créer des initiations (pas les organisateurs)
    user&.role&.level.to_i >= 60 # ADMIN+
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
      :cover_image,
      :allow_non_member_discovery,
      :non_member_discovery_slots
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
