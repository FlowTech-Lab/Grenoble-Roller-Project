# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationEventRegistry do
  describe ".event_keys" do
    it "includes every DR-002 catalog event key" do
      expect(described_class.event_keys).to match_array(NotificationEventKeys::ALL)
    end

    it "includes test.ping for admin test action" do
      expect(described_class.event_keys).to include("test.ping")
    end
  end

  describe ".default_on_keys" do
    it "matches DR-002 default subscriptions for new webhooks" do
      expect(described_class.default_on_keys).to match_array(NotificationEventKeys::DEFAULT_ON)
    end

    it "does not pre-select payment.failed" do
      expect(described_class.default_on_keys).not_to include("payment.failed")
    end
  end

  describe ".find" do
    it "returns EventDefinition for a known event" do
      entry = described_class.find("order.paid")

      expect(entry).to be_a(NotificationEventRegistry::EventDefinition)
      expect(entry.key).to eq("order.paid")
      expect(entry.default_on).to be(true)
      expect(entry.label).to be_present
      expect(entry.group).to eq("paiements")
    end

    it "returns nil for unknown keys" do
      expect(described_class.find("unknown.event")).to be_nil
    end
  end

  describe ".grouped" do
    it "returns events grouped by section" do
      groups = described_class.grouped

      expect(groups).to be_a(Hash)
      keys = groups.values.flatten.map(&:key)
      expect(keys).to include("order.paid", "contact_message.received")
    end

    it "includes French labels for admin UI" do
      entry = described_class.grouped.values.flatten.find { |e| e.key == "order.paid" }
      expect(entry.label).to eq("Nouvelle commande payée")
    end
  end

  describe ".build_payload" do
    it "builds a Discord embed hash for order.paid" do
      order = create(:order, :paid, total_cents: 3400)
      payload = described_class.build_payload("order.paid", source: order)

      expect(payload).to include(:embeds)
      expect(payload[:embeds].first).to include(:title, :fields)
    end

    it "returns nil for unknown event keys" do
      expect(described_class.build_payload("unknown.event", source: create(:order))).to be_nil
    end
  end
end
