# frozen_string_literal: true

class NotificationSubscription < ApplicationRecord
  belongs_to :notification_channel

  validates :event_key, presence: true,
                        inclusion: { in: ->(_) { NotificationEventRegistry.event_keys } }
  validates :event_key, uniqueness: { scope: :notification_channel_id }
end
