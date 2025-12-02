class AddChildFieldsToMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :memberships, :is_child_membership, :boolean, default: false, null: false
    add_column :memberships, :child_first_name, :string
    add_column :memberships, :child_last_name, :string
    add_column :memberships, :child_date_of_birth, :date

    # Index pour les adhésions enfants
    add_index :memberships, [ :user_id, :is_child_membership, :season ]
  end
end
