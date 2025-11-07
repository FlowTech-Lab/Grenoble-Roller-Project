class CreateAttendances < ActiveRecord::Migration[8.0]
  def change
    create_table :attendances do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :event, null: false, foreign_key: true, index: true
      t.string :status, limit: 20, null: false, default: "registered"
      t.references :payment, null: true, foreign_key: true, index: true
      t.string :stripe_customer_id, limit: 255

      t.timestamps
    end

    add_index :attendances, [:user_id, :event_id], unique: true
  end
end
