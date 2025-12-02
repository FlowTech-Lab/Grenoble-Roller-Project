class AddHealthQuestionsToMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :memberships, :health_q1, :string
    add_column :memberships, :health_q2, :string
    add_column :memberships, :health_q3, :string
    add_column :memberships, :health_q4, :string
    add_column :memberships, :health_q5, :string
    add_column :memberships, :health_q6, :string
    add_column :memberships, :health_q7, :string
    add_column :memberships, :health_q8, :string
    add_column :memberships, :health_q9, :string
  end
end
