# frozen_string_literal: true

class CreateOutboundEmailLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :outbound_email_logs do |t|
      t.string :active_job_id, null: false
      t.bigint :solid_queue_job_id
      t.string :mailer_class
      t.string :mailer_method
      t.string :status, null: false, default: "queued"
      t.jsonb :arguments, default: {}, null: false
      t.text :error_message
      t.datetime :queued_at, null: false
      t.datetime :sent_at
      t.datetime :failed_at

      t.timestamps
    end

    add_index :outbound_email_logs, :active_job_id, unique: true
    add_index :outbound_email_logs, :solid_queue_job_id
    add_index :outbound_email_logs, :status
    add_index :outbound_email_logs, :mailer_class
    add_index :outbound_email_logs, :created_at
  end
end
