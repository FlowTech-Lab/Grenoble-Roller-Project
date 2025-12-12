class AddCanBeVolunteerToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :can_be_volunteer, :boolean, default: false, null: false
  end
end
