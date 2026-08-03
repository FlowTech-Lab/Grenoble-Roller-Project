class AddOrganizerToEvents < ActiveRecord::Migration[8.1]
  def change
    add_reference :events, :organizer, null: true, foreign_key: { to_table: :event_organizers }
  end
end
