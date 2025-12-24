module Admin
  class ApplicationPolicy < ::ApplicationPolicy
    def index?
      admin_user?
    end

    def show?
      admin_user?
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

    def admin_user?
      user.present? && user.role&.level.to_i >= 60 # ADMIN (60) ou SUPERADMIN (70)
    end

    class Scope < ::ApplicationPolicy::Scope
      def resolve
        return scope if admin_user?

        if scope.respond_to?(:none)
          scope.none
        else
          []
        end
      end

      private

      def admin_user?
        user.present? && user.role&.level.to_i >= 60 # ADMIN (60) ou SUPERADMIN (70)
      end
    end
  end
end
