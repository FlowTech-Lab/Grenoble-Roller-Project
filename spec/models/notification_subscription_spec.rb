# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationSubscription, type: :model do
  describe "associations" do
    it "belongs to notification_channel" do
      subscription = create(:notification_subscription)
      expect(subscription.notification_channel).to be_a(NotificationChannel)
    end
  end

  describe "validations" do
    it "requires event_key" do
      subscription = build(:notification_subscription, event_key: nil)
      expect(subscription).not_to be_valid
      expect(subscription.errors[:event_key]).to be_present
    end

    it "rejects unknown event keys" do
      subscription = build(:notification_subscription, event_key: "unknown.event")
      expect(subscription).not_to be_valid
      expect(subscription.errors[:event_key]).to be_present
    end

    it "enforces uniqueness of event_key per channel" do
      channel = create(:notification_channel)
      create(:notification_subscription, notification_channel: channel, event_key: "order.paid")

      duplicate = build(:notification_subscription, notification_channel: channel, event_key: "order.paid")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:event_key]).to be_present
    end

    it "allows same event_key on different channels" do
      create(:notification_subscription, event_key: "order.paid")
      other = build(:notification_subscription, event_key: "order.paid")

      expect(other).to be_valid
    end
  end
end
