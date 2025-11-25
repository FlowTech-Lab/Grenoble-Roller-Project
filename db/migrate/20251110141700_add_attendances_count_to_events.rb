class AddAttendancesCountToEvents < ActiveRecord::Migration[8.1]
  def up
    add_column :events, :attendances_count, :integer, default: 0, null: false

    # Mettre à jour les compteurs pour tous les événements existants
    execute <<-SQL
      UPDATE events
      SET attendances_count = (
        SELECT COUNT(*)
        FROM attendances
        WHERE attendances.event_id = events.id
      )
    SQL
  end

  def down
    remove_column :events, :attendances_count
  end
end
