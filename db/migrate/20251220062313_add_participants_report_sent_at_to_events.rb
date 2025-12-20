class AddParticipantsReportSentAtToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :participants_report_sent_at, :datetime, null: true
    add_index :events, :participants_report_sent_at
  end
end
