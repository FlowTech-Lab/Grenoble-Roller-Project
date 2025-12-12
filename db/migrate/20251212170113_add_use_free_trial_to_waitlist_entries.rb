class AddUseFreeTrialToWaitlistEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :waitlist_entries, :use_free_trial, :boolean, default: false
  end
end
