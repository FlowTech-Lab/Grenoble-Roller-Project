class AddDonationCentsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :donation_cents, :integer, default: 0, null: false
  end
end
