# frozen_string_literal: true

require "rails_helper"

RSpec.describe UnifiedCart do
  describe ".enabled?" do
    context "when UNIFIED_CART_ENABLED is true" do
      around do |example|
        previous = ENV["UNIFIED_CART_ENABLED"]
        ENV["UNIFIED_CART_ENABLED"] = "true"
        example.run
      ensure
        ENV["UNIFIED_CART_ENABLED"] = previous
      end

      it "returns true" do
        expect(described_class.enabled?).to be(true)
      end
    end

    context "when UNIFIED_CART_ENABLED is false or unset" do
      around do |example|
        previous = ENV["UNIFIED_CART_ENABLED"]
        ENV["UNIFIED_CART_ENABLED"] = "false"
        example.run
      ensure
        ENV["UNIFIED_CART_ENABLED"] = previous
      end

      it "returns false" do
        expect(described_class.enabled?).to be(false)
      end
    end
  end
end
