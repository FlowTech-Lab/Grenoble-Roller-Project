class AddEmailFlagsToMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :memberships, :renewal_reminder_sent_at, :datetime
    add_column :memberships, :expired_email_sent_at, :datetime
  end
end
