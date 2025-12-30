class CreateInventoryMovements < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_movements do |t|
      t.references :inventory, null: false, foreign_key: true, index: true
      t.references :user, null: true, foreign_key: true
      t.integer :quantity, null: false
      t.string :reason, null: false
      t.string :reference
      t.integer :before_qty, null: false
      t.timestamps
    end

    add_index :inventory_movements, :created_at
  end
end
