class AddWantsReminderToAttendances < ActiveRecord::Migration[8.1]
  def change
    add_column :attendances, :wants_reminder, :boolean, default: false, null: false
    add_index :attendances, :wants_reminder
  end
end
