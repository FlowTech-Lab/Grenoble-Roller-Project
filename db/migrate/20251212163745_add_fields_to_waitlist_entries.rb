class AddFieldsToWaitlistEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :waitlist_entries, :needs_equipment, :boolean
    add_column :waitlist_entries, :roller_size, :string
    add_column :waitlist_entries, :wants_reminder, :boolean
  end
end
