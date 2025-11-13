class CreateRoutes < ActiveRecord::Migration[8.0]
  def change
    create_table :routes do |t|
      t.string :name, limit: 140, null: false
      t.text :description
      t.decimal :distance_km, precision: 5, scale: 2
      t.integer :elevation_m
      t.string :difficulty, limit: 20
      t.string :gpx_url, limit: 255
      t.string :map_image_url, limit: 255
      t.text :safety_notes

      t.timestamps
    end
  end
end
