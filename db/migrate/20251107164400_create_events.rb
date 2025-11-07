class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.references :creator_user, null: false, foreign_key: { to_table: :users }, index: true
      t.string :status, limit: 20, null: false, default: "draft"
      t.timestamptz :start_at, null: false
      t.integer :duration_min, null: false
      t.string :title, limit: 140, null: false
      t.text :description, null: false
      t.integer :price_cents, null: false, default: 0
      t.string :currency, limit: 3, null: false, default: "EUR"
      t.string :location_text, limit: 255, null: false
      t.decimal :meeting_lat, precision: 9, scale: 6
      t.decimal :meeting_lng, precision: 9, scale: 6
      t.references :route, null: true, foreign_key: true, index: true
      t.string :cover_image_url, limit: 255

      t.timestamps
    end

    add_index :events, [:status, :start_at]
  end
end
