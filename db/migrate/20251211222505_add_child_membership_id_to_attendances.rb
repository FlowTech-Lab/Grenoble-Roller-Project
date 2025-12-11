class AddChildMembershipIdToAttendances < ActiveRecord::Migration[8.1]
  def change
    add_column :attendances, :child_membership_id, :bigint
    add_index :attendances, :child_membership_id
    add_foreign_key :attendances, :memberships, column: :child_membership_id
  end
end
