class CreateProductVariants < ActiveRecord::Migration[8.0]
  def change
    create_table :product_variants do |t|
      t.references :product, null: false, foreign_key: true
      t.string  :sku, null: false, limit: 80
      t.integer :price_cents, null: false
      t.string  :currency, null: false, limit: 3, default: "EUR"
      t.integer :stock_qty, null: false, default: 0
      t.boolean :is_active, null: false, default: true

      # ❌ NE PAS remettre t.index :product_id (déjà créé par t.references)
      t.index :sku, unique: true

      t.timestamps
    end
  end
end