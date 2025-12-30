class CreateInventories < ActiveRecord::Migration[8.1]
  def change
    create_table :inventories do |t|
      t.references :product_variant, null: false, foreign_key: true, index: { unique: true }
      t.integer :stock_qty, default: 0, null: false
      t.integer :reserved_qty, default: 0, null: false
      t.timestamps
    end
  end
end
