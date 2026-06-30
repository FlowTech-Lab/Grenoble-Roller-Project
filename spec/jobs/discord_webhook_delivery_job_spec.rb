# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscordWebhookDeliveryJob, type: :job do
  let(:channel) { create(:notification_channel) }
  let(:order) { create(:order, :paid, total_cents: 3400) }
  let(:payload) { NotificationEventRegistry.build_payload("order.paid", source: order) }
  let!(:delivery) do
    create(
      :notification_delivery,
      notification_channel: channel,
      event_key: "order.paid",
      source_type: "Order",
      source_id: order.id
    )
  end

  describe "#perform" do
    it "posts embed payload via DiscordWebhookClient" do
      stringified_payload = payload.deep_stringify_keys

      expect(DiscordWebhookClient).to receive(:post!).with(channel.webhook_url, stringified_payload).and_return(
        instance_double(Net::HTTPSuccess, code: "204")
      )

      described_class.perform_now(channel.id, stringified_payload, delivery.id)
    end

    it "marks delivery as delivered on success" do
      allow(DiscordWebhookClient).to receive(:post!).and_return(instance_double(Net::HTTPSuccess, code: "204"))

      described_class.perform_now(channel.id, payload.deep_stringify_keys, delivery.id)

      expect(delivery.reload.status).to eq("delivered")
      expect(delivery.http_code).to eq(204)
      expect(delivery.delivered_at).to be_present
    end

    it "records failure and re-raises on client error" do
      allow(DiscordWebhookClient).to receive(:post!).and_raise(
        DiscordWebhookClient::DeliveryError.new("Discord webhook failed (400)", http_code: 400)
      )

      begin
        described_class.perform_now(channel.id, payload.deep_stringify_keys, delivery.id)
      rescue DiscordWebhookClient::DeliveryError
        # ActiveJob retry_on may swallow the re-raise in perform_now
      end

      expect(delivery.reload.status).to eq("failed")
      expect(delivery.http_code).to eq(400)
    end

    it "no-ops when delivery record is missing" do
      delivery.destroy!

      expect(DiscordWebhookClient).not_to receive(:post!)
      described_class.perform_now(channel.id, payload.deep_stringify_keys, 0)
    end
  end
end
