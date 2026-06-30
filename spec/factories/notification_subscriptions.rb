# frozen_string_literal: true

FactoryBot.define do
  factory :notification_subscription do
    notification_channel
    event_key { "order.paid" }
    enabled { true }
  end
end
