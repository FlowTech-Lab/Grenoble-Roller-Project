# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationDispatchService do
  include ActiveJob::TestHelper

  around do |example|
    ActiveJob::Base.queue_adapter = :test
    example.run
  end

  describe ".notifications_enabled?" do
    it "is false in non-production without ALLOW_DISCORD_NOTIFICATIONS" do
      block_discord_notifications!
      create(:notification_channel, enabled: true)

      expect(described_class.notifications_enabled?).to be(false)
    end

    it "is true in production when channels exist" do
      allow(Rails.env).to receive(:production?).and_return(true)
      create(:notification_channel, enabled: true)

      expect(described_class.notifications_enabled?).to be(true)
    end

    it "is true in test/staging when ALLOW_DISCORD_NOTIFICATIONS is set" do
      allow_discord_notifications!
      create(:notification_channel, enabled: true)

      expect(described_class.notifications_enabled?).to be(true)
    end

    it "is false when no enabled channel exists" do
      allow_discord_notifications!
      NotificationChannel.delete_all
      create(:notification_channel, enabled: false)

      expect(described_class.notifications_enabled?).to be(false)
    end
  end

  describe ".dispatch" do
    let(:order) { create(:order, :paid, total_cents: 3400) }

    before { allow_discord_notifications! }

    it "does not enqueue when staging guard blocks dispatch" do
      block_discord_notifications!
      create(:notification_channel, :with_order_paid_subscription)

      expect {
        described_class.dispatch("order.paid", source: order)
      }.not_to have_enqueued_job(DiscordWebhookDeliveryJob)
    end

    it "enqueues delivery for matching enabled channels" do
      channel = create(:notification_channel, :with_order_paid_subscription)

      expect {
        described_class.dispatch("order.paid", source: order)
      }.to have_enqueued_job(DiscordWebhookDeliveryJob).with(
        channel.id,
        kind_of(Hash),
        kind_of(Integer)
      )
    end

    it "skips disabled channels" do
      disabled_channel = create(:notification_channel, enabled: false)
      create(:notification_subscription, notification_channel: disabled_channel, event_key: "order.paid", enabled: true)

      expect {
        described_class.dispatch("order.paid", source: order)
      }.not_to have_enqueued_job(DiscordWebhookDeliveryJob)
    end

    it "skips channels without subscription for event" do
      create(:notification_channel, enabled: true)

      expect {
        described_class.dispatch("order.paid", source: order)
      }.not_to have_enqueued_job(DiscordWebhookDeliveryJob)
    end

    it "is idempotent — second dispatch does not enqueue again" do
      create(:notification_channel, :with_order_paid_subscription)

      described_class.dispatch("order.paid", source: order)

      expect {
        described_class.dispatch("order.paid", source: order)
      }.not_to have_enqueued_job(DiscordWebhookDeliveryJob)
    end

    it "creates a notification_delivery record on first dispatch" do
      channel = create(:notification_channel, :with_order_paid_subscription)

      expect {
        described_class.dispatch("order.paid", source: order)
      }.to change(NotificationDelivery, :count).by(1)

      delivery = NotificationDelivery.last
      expect(delivery.notification_channel).to eq(channel)
      expect(delivery.event_key).to eq("order.paid")
      expect(delivery.source_type).to eq("Order")
      expect(delivery.source_id).to eq(order.id)
    end
  end

  describe ".dispatch_payment_succeeded!" do
    before { allow_discord_notifications! }

    it "dispatches order.paid for paid orders linked to payment" do
      payment = create(:payment, :pending)
      order = create(:order, payment: payment, status: "paid", total_cents: 3400)
      channel = create(:notification_channel)
      create(:notification_subscription, notification_channel: channel, event_key: "order.paid", enabled: true)

      allow(NotificationDispatchService).to receive(:activated_memberships).and_return(Membership.none)
      allow(NotificationDispatchService).to receive(:fulfilled_attendances).and_return(Attendance.none)

      expect {
        described_class.dispatch_payment_succeeded!(payment)
      }.to have_enqueued_job(DiscordWebhookDeliveryJob)

      delivery = NotificationDelivery.find_by(source_type: "Order", source_id: order.id)
      expect(delivery).to be_present
    end

    it "dispatches membership.activated for active memberships" do
      payment = create(:payment, :pending)
      membership = create(:membership, :pending, payment: payment)
      membership.update!(status: :active)
      channel = create(:notification_channel)
      create(:notification_subscription, notification_channel: channel, event_key: "membership.activated", enabled: true)

      allow(NotificationDispatchService).to receive(:activated_memberships).and_return(Membership.where(id: membership.id))
      allow(NotificationDispatchService).to receive(:fulfilled_attendances).and_return(Attendance.none)

      expect {
        described_class.dispatch_payment_succeeded!(payment)
      }.to have_enqueued_job(DiscordWebhookDeliveryJob)

      delivery = NotificationDelivery.find_by(source_type: "Membership", source_id: membership.id)
      expect(delivery).to be_present
    end
  end
end
