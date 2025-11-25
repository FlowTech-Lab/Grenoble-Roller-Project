class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :status, null: false, default: "pending"
      t.integer :total_cents, null: false, default: 0
      t.string :currency, null: false, limit: 3, default: "EUR"
      t.references :payment, foreign_key: true, index: true
      t.timestamps
    end
  end
end
