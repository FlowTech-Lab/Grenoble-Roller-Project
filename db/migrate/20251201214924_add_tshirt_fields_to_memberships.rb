class AddTshirtFieldsToMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :memberships, :with_tshirt, :boolean, default: false, null: false
    add_column :memberships, :tshirt_size, :string, null: true
    add_column :memberships, :tshirt_qty, :integer, default: 0, null: false
  end
end
