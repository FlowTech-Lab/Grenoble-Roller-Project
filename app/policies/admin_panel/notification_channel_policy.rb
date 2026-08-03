# frozen_string_literal: true

module AdminPanel
  class NotificationChannelPolicy < BasePolicy
    def index?
      superadmin?
    end

    def show?
      superadmin?
    end

    def create?
      superadmin?
    end

    def new?
      create?
    end

    def update?
      superadmin?
    end

    def edit?
      update?
    end

    def destroy?
      superadmin?
    end

    def test?
      superadmin?
    end

    def sample_event?
      test?
    end

    def sample_all_events?
      test?
    end

    private

    def superadmin?
      user.present? && user.role&.level.to_i >= 70
    end
  end
end
