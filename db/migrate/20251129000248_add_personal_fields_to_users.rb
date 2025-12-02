class AddPersonalFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :date_of_birth, :date
    add_column :users, :address, :string
    add_column :users, :postal_code, :string
    add_column :users, :city, :string
  end
end
