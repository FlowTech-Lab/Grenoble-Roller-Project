class CreateEventLoopRoutes < ActiveRecord::Migration[8.1]
  def change
    create_table :event_loop_routes do |t|
      t.references :event, null: false, foreign_key: true
      t.references :route, null: false, foreign_key: true
      t.integer :loop_number, null: false
      t.decimal :distance_km, precision: 5, scale: 1

      t.timestamps
    end

    add_index :event_loop_routes, [:event_id, :loop_number], unique: true
  end
end
