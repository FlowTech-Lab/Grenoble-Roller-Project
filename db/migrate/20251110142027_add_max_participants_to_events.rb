class AddMaxParticipantsToEvents < ActiveRecord::Migration[8.1]
  def up
    add_column :events, :max_participants, :integer, default: 0, null: false
    
    # Mettre à jour les événements existants à 0 (illimité)
    execute <<-SQL
      UPDATE events
      SET max_participants = 0
      WHERE max_participants IS NULL
    SQL
  end

  def down
    remove_column :events, :max_participants
  end
end
