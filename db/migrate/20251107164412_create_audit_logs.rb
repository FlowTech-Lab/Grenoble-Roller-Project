class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :actor_user, null: false, foreign_key: { to_table: :users }, index: true
      t.string :action, limit: 80, null: false
      t.string :target_type, limit: 50, null: false
      t.integer :target_id, null: false
      t.jsonb :metadata

      t.timestamps
    end

    add_index :audit_logs, [ :target_type, :target_id ]
  end
end
