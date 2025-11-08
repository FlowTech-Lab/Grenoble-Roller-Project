module Admin
  class RolePolicy < Admin::ApplicationPolicy
    def admin_user?
      user.present? && user.role&.code == 'SUPERADMIN'
    end

    class Scope < Admin::ApplicationPolicy::Scope
      def resolve
        return scope.all if admin_user?

        scope.none
      end
    end
  end
end

