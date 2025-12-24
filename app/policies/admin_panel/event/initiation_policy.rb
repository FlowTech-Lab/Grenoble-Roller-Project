# frozen_string_literal: true

module AdminPanel
  module Event
    class InitiationPolicy < AdminPanel::BasePolicy
      # Permissions pour les initiations :
      # - Lecture (index?, show?) : level >= 30 (INITIATION, ORGANIZER, MODERATOR, ADMIN, SUPERADMIN)
      # - Écriture (create?, update?, destroy?) : level >= 60 (ADMIN, SUPERADMIN)
      # - Actions spéciales (presences, waitlist, etc.) : level >= 60 (ADMIN, SUPERADMIN)

      def index?
        can_view_initiations?
      end

      def show?
        can_view_initiations?
      end

      def create?
        admin_user? # level >= 60
      end

      def update?
        admin_user? # level >= 60
      end

      def destroy?
        admin_user? # level >= 60
      end

      def presences?
        admin_user? # level >= 60
      end

      def update_presences?
        admin_user? # level >= 60
      end

      def convert_waitlist?
        admin_user? # level >= 60
      end

      def notify_waitlist?
        admin_user? # level >= 60
      end

      def toggle_volunteer?
        admin_user? # level >= 60
      end

      private

      def can_view_initiations?
        user.present? && user.role&.level.to_i >= 30 # INITIATION (30), ORGANIZER (40), MODERATOR (50), ADMIN (60), SUPERADMIN (70)
      end

      def admin_user?
        user.present? && user.role&.level.to_i >= 60 # ADMIN (60) ou SUPERADMIN (70)
      end
    end
  end
end
