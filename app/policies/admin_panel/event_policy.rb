# frozen_string_literal: true

module AdminPanel
  class EventPolicy < BasePolicy
    # Permissions for randos (non-initiation events):
    # - Read (index?, show?): level >= 40 (ORGANIZER, MODERATOR, ADMIN+)
    # - Write / waitlist actions: level >= 60 (ADMIN+)

    def index?
      can_view_events?
    end

    def show?
      can_view_events?
    end

    def create?
      admin_user?
    end

    def new?
      create?
    end

    def update?
      admin_user?
    end

    def edit?
      update?
    end

    def destroy?
      admin_user?
    end

    def convert_waitlist?
      admin_user?
    end

    def notify_waitlist?
      admin_user?
    end

    private

    def can_view_events?
      user.present? && user.role&.level.to_i >= 40
    end

    def admin_user?
      user.present? && user.role&.level.to_i >= 60
    end
  end
end
