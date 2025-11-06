class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.string  :provider,             null: false, limit: 20   # stripe, helloasso, free
      t.string  :provider_payment_id
      t.integer :amount_cents,         null: false, default: 0
      t.string  :currency,             null: false, default: "EUR", limit: 3
      t.string  :status,               null: false, default: "succeeded", limit: 20
      t.datetime :created_at
    end
  end
end