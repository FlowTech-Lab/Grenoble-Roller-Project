class EventPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record.published? || organizer? || owner?
  end

  def create?
    organizer?
  end

  def new?
    create?
  end

  def update?
    organizer? && (owner? || admin?)
  end

  def edit?
    update?
  end

  def destroy?
    admin? || owner?
  end

  def permitted_attributes
    [
      :title,
      :status,
      :start_at,
      :duration_min,
      :description,
      :price_cents,
      :currency,
      :location_text,
      :meeting_lat,
      :meeting_lng,
      :route_id,
      :cover_image_url
    ]
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if admin?
        scope.all
      elsif organizer?
        scope.where(creator_user_id: user.id).or(scope.published)
      elsif user.present?
        scope.published.or(scope.where(creator_user_id: user.id))
      else
        scope.published
      end
    end

    private

    def organizer?
      user.present? && user.role&.level.to_i >= 40
    end

    def admin?
      user.present? && user.role&.level.to_i >= 60
    end
  end

  private

  def owner?
    user.present? && record.creator_user_id == user.id
  end

  def organizer?
    user.present? && user.role&.level.to_i >= 40
  end

  def admin?
    user.present? && user.role&.level.to_i >= 60
  end
end

