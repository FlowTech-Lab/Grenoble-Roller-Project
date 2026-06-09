# frozen_string_literal: true

class NotificationDelivery < ApplicationRecord
  STATUSES = %w[pending delivered failed].freeze

  belongs_to :notification_channel

  validates :event_key, presence: true
  validates :source_type, presence: true
  validates :source_id, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :delivered, -> { where(status: "delivered") }
end
