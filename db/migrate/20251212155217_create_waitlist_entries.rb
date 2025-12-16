class CreateWaitlistEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :waitlist_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.references :child_membership, null: true, foreign_key: { to_table: :memberships }
      t.integer :position, null: false, default: 0
      t.datetime :notified_at
      t.string :status, null: false, default: "pending" # pending, notified, converted, cancelled

      t.timestamps
    end

    # Index pour optimiser les requêtes
    add_index :waitlist_entries, [ :event_id, :status, :position ]
    add_index :waitlist_entries, [ :user_id, :event_id, :child_membership_id ], unique: true, name: "index_waitlist_entries_on_user_event_child"
  end
end
