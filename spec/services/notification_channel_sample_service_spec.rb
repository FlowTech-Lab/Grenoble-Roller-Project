# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationChannelSampleService do
  let(:channel) { create(:notification_channel) }
  let(:service) { described_class.new(channel: channel) }

  describe "#send_event!" do
    it "posts a QA-prefixed embed for a known event" do
      expect(DiscordWebhookClient).to receive(:post!) do |_url, payload|
        expect(payload.dig(:embeds, 0, :title)).to start_with("[QA]")
      end

      service.send_event!("order.paid")
    end

    it "raises for unknown event keys" do
      expect {
        service.send_event!("unknown.event")
      }.to raise_error(NotificationSampleSourceService::MissingSampleDataError)
    end
  end
end
