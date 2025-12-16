module Admin
  module Event
    class InitiationPolicy < Admin::ApplicationPolicy
      def convert_waitlist?
        update?
      end

      def notify_waitlist?
        update?
      end

      def toggle_volunteer?
        update?
      end

      def presences?
        show?
      end

      def update_presences?
        update?
      end

      class Scope < Admin::ApplicationPolicy::Scope
        def resolve
          scope.all
        end
      end
    end
  end
end
