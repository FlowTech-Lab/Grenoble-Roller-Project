class AddConfirmationAuditFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :confirmed_ip, :string
    add_column :users, :confirmed_user_agent, :text
    add_column :users, :confirmation_token_last_used_at, :datetime

    # Index pour recherche rapide par IP (détection anomalies)
    add_index :users, :confirmed_ip
  end
end
