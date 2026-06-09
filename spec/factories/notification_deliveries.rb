# frozen_string_literal: true

FactoryBot.define do
  factory :notification_delivery do
    notification_channel
    event_key { "order.paid" }
    source_type { "Order" }
    source_id { create(:order).id }
    status { "pending" }

    trait :delivered do
      status { "delivered" }
      http_code { 204 }
      delivered_at { Time.current }
    end
  end
end
