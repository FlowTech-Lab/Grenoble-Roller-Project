class CreateCartLines < ActiveRecord::Migration[8.1]
  def change
    create_table :cart_lines do |t|
      t.references :user, null: false, foreign_key: true
      t.string :line_type, null: false
      t.references :reference, polymorphic: true, null: false
      t.integer :amount_cents, null: false, default: 0
      t.string :label, null: false
      t.integer :quantity, null: false, default: 1
      t.datetime :expires_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :cart_lines, [ :user_id, :line_type ]
    add_index :cart_lines, [ :user_id, :expires_at ]
    add_index :cart_lines, [ :user_id, :reference_type, :reference_id, :line_type ],
              unique: true, name: "index_cart_lines_unique_per_user_reference"
  end
end
