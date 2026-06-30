# frozen_string_literal: true

FactoryBot.define do
  factory :notification_channel do
    sequence(:name) { |n| "Discord Ops #{n}" }
    webhook_url { DiscordNotificationHelpers::DISCORD_WEBHOOK_URL }
    enabled { true }

    trait :disabled do
      enabled { false }
    end

    trait :with_order_paid_subscription do
      after(:create) do |channel|
        create(:notification_subscription, notification_channel: channel, event_key: "order.paid", enabled: true)
      end
    end
  end
end
