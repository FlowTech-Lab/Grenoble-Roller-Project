class CreateOrganizerApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :organizer_applications do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.text :motivation
      t.string :status, limit: 20, null: false, default: "pending"
      t.references :reviewed_by, null: true, foreign_key: { to_table: :users }, index: true
      t.timestamp :reviewed_at

      t.timestamps
    end
  end
end
