# frozen_string_literal: true

class CreateCheckouts < ActiveRecord::Migration[8.1]
  def change
    create_table :checkouts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.integer :subtotal_cents, null: false, default: 0
      t.integer :donation_cents, null: false, default: 0
      t.integer :total_cents, null: false, default: 0
      t.references :payment, foreign_key: true
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :checkouts, [ :user_id, :status ]

    create_table :checkout_lines do |t|
      t.references :checkout, null: false, foreign_key: true
      t.bigint :cart_line_id
      t.string :line_type, null: false
      t.references :reference, polymorphic: true, null: false
      t.integer :amount_cents, null: false
      t.string :label, null: false
      t.integer :quantity, null: false, default: 1
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :checkout_lines, :cart_line_id
  end
end
