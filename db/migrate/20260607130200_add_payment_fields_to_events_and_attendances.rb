# frozen_string_literal: true

class AddPaymentFieldsToEventsAndAttendances < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :payment_required, :boolean, default: false, null: false
    add_column :attendances, :payment_expires_at, :datetime
    add_index :attendances, :payment_expires_at
  end
end
