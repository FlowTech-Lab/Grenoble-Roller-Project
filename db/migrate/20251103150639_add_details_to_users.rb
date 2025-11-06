class AddDetailsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :bio, :text
    add_column :users, :phone, :string, limit: 10
    add_column :users, :avatar_url, :string
    add_column :users, :email_verified, :boolean, default: false, null: false
    add_column :users, :role_id, :integer, null: false
    add_index :users, :role_id
  end
end
