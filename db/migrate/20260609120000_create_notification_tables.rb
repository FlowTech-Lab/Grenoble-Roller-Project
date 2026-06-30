# frozen_string_literal: true

class CreateNotificationTables < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_channels do |t|
      t.string :name, null: false
      t.text :webhook_url_ciphertext
      t.boolean :enabled, null: false, default: true
      t.datetime :last_tested_at
      t.string :last_test_status

      t.timestamps
    end

    create_table :notification_subscriptions do |t|
      t.references :notification_channel, null: false, foreign_key: true
      t.string :event_key, null: false
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end

    add_index :notification_subscriptions,
              %i[notification_channel_id event_key],
              unique: true,
              name: "index_notification_subscriptions_on_channel_and_event_key"

    create_table :notification_deliveries do |t|
      t.references :notification_channel, null: false, foreign_key: true
      t.string :event_key, null: false
      t.string :source_type, null: false
      t.bigint :source_id, null: false
      t.string :status, null: false, default: "pending"
      t.integer :http_code
      t.text :error_message
      t.datetime :delivered_at

      t.timestamps
    end

    add_index :notification_deliveries,
              %i[notification_channel_id event_key source_type source_id],
              unique: true,
              name: "index_notification_deliveries_idempotency"
  end
end
