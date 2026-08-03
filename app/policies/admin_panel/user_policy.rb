# frozen_string_literal: true

module AdminPanel
  class UserPolicy < BasePolicy
    # Inherits BasePolicy admin gate (level >= 60).
    # Level 60 = ADMIN, Level 70 = SUPERADMIN.
    # Admins cannot modify or delete super admins.

    def update?
      admin_user? && manageable_user?
    end

    def edit?
      update?
    end

    def destroy?
      admin_user? && manageable_user?
    end

    private

    def manageable_user?
      RoleAssignmentService.can_manage_user?(assigner: user, target_user: record)
    end
  end
end
