module Admin
  class RolePolicy < Admin::ApplicationPolicy
    def admin_user?
      user.present? && user.role&.level.to_i >= 70 # SUPERADMIN (70) uniquement
    end

    class Scope < Admin::ApplicationPolicy::Scope
      def resolve
        return scope.all if admin_user?

        scope.none
      end
    end
  end
end
