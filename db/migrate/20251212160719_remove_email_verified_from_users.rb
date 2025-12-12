class RemoveEmailVerifiedFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :email_verified, :boolean
  end
end
