class AddReminderSentAtToAttendances < ActiveRecord::Migration[8.1]
  def change
    add_column :attendances, :reminder_sent_at, :datetime
  end
end
