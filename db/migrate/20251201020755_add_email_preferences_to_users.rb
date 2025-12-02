class AddEmailPreferencesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :wants_initiation_mail, :boolean, default: true, null: false
    add_column :users, :wants_events_mail, :boolean, default: true, null: false
  end
end
