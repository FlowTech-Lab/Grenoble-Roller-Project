class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.references :category, null: false, foreign_key: { to_table: :product_categories }
      t.string  :name, null: false, limit: 140
      t.string  :slug, null: false, limit: 160
      t.text    :description
      t.integer :price_cents, null: false
      t.string  :currency, null: false, limit: 3, default: "EUR"
      t.integer :stock_qty, null: false, default: 0
      t.boolean :is_active, null: false, default: true
      t.string  :image_url, limit: 255

      # 🔽 Conserve uniquement ces index supplémentaires :
      t.index [ :is_active, :slug ]
      t.index :slug, unique: true

      t.timestamps
    end
  end
end
