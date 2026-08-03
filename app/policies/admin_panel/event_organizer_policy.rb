# frozen_string_literal: true

module AdminPanel
  class EventOrganizerPolicy < BasePolicy
    # Permissions for event organizing entities (associations):
    # - All actions: level >= 60 (ADMIN, SUPERADMIN)
    # - Full CRUD; index?, show?, create?, update?, destroy? inherit from BasePolicy
  end
end
