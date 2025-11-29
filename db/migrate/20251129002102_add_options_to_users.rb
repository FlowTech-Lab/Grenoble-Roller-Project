class AddOptionsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :wants_whatsapp, :boolean, default: false
    add_column :users, :wants_email_info, :boolean, default: true
  end
end
