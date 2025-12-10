class AddTshirtAndOptionsToMemberships < ActiveRecord::Migration[8.1]
  def change
    add_reference :memberships, :tshirt_variant, null: true, foreign_key: { to_table: :product_variants }
    add_column :memberships, :tshirt_price_cents, :integer, default: 1400 # 14€
    add_column :memberships, :wants_whatsapp, :boolean, default: false
    add_column :memberships, :wants_email_info, :boolean, default: true
  end
end
