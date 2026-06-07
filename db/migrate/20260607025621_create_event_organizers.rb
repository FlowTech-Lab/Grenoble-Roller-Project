class CreateEventOrganizers < ActiveRecord::Migration[8.1]
  def change
    create_table :event_organizers do |t|
      t.string :name, null: false
      t.string :url
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :event_organizers, :is_active
  end
end
