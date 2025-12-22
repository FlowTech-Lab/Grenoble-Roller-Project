# frozen_string_literal: true

module AdminPanel
  module Event
    class InitiationPolicy < AdminPanel::BasePolicy
      # Les méthodes index?, show?, create?, update?, destroy? héritent de BasePolicy
      # qui vérifie admin_user? (ADMIN ou SUPERADMIN)

      def presences?
        admin_user?
      end

      def update_presences?
        admin_user?
      end

      def convert_waitlist?
        admin_user?
      end

      def notify_waitlist?
        admin_user?
      end

      def toggle_volunteer?
        admin_user?
      end

      # admin_user? hérite de BasePolicy qui utilise level >= 60
    end
  end
end
