# frozen_string_literal: true

module AdminPanel
  class BasePolicy < ApplicationPolicy
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

    class Scope < ApplicationPolicy::Scope
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
        user.present? && user.role&.code.in?(%w[ADMIN SUPERADMIN])
      end
    end

    private

    def admin_user?
      user.present? && user.role&.code.in?(%w[ADMIN SUPERADMIN])
    end
  end
end
