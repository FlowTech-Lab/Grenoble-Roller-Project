class CreateRollerStocks < ActiveRecord::Migration[8.1]
  def change
    create_table :roller_stocks do |t|
      t.string :size, null: false
      t.integer :quantity, default: 0, null: false
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    add_index :roller_stocks, :size, unique: true
    add_index :roller_stocks, :is_active
  end
end
