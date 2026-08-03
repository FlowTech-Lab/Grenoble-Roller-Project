# frozen_string_literal: true

require "rails_helper"

RSpec.describe AnalyticsHelper, type: :helper do
  include CookieConsentHelper

  around do |example|
    original_script = ENV["UMAMI_SCRIPT_URL"]
    original_id = ENV["UMAMI_WEBSITE_ID"]
    original_share = ENV["UMAMI_SHARE_URL"]
    ENV.delete("UMAMI_SCRIPT_URL")
    ENV.delete("UMAMI_WEBSITE_ID")
    ENV.delete("UMAMI_SHARE_URL")
    example.run
  ensure
    if original_script
      ENV["UMAMI_SCRIPT_URL"] = original_script
    else
      ENV.delete("UMAMI_SCRIPT_URL")
    end
    if original_id
      ENV["UMAMI_WEBSITE_ID"] = original_id
    else
      ENV.delete("UMAMI_WEBSITE_ID")
    end
    if original_share
      ENV["UMAMI_SHARE_URL"] = original_share
    else
      ENV.delete("UMAMI_SHARE_URL")
    end
  end

  describe "#umami_configured?" do
    it "returns false when env vars are missing" do
      expect(helper.umami_configured?).to be false
    end

    it "returns true when both env vars are set" do
      ENV["UMAMI_SCRIPT_URL"] = "https://stats.example.com/script.js"
      ENV["UMAMI_WEBSITE_ID"] = "abc-123"

      expect(helper.umami_configured?).to be true
    end
  end

  describe "#umami_tracking_allowed?" do
    before do
      ENV["UMAMI_SCRIPT_URL"] = "https://stats.example.com/script.js"
      ENV["UMAMI_WEBSITE_ID"] = "abc-123"
    end

    it "returns false without analytics consent" do
      expect(helper.umami_tracking_allowed?).to be false
    end

    it "returns true when configured and analytics consent is granted" do
      helper.cookies[:cookie_consent] = {
        necessary: true,
        analytics: true
      }.to_json

      expect(helper.umami_tracking_allowed?).to be true
    end
  end

  describe "#umami_public_stats_available?" do
    it "returns false without share url" do
      expect(helper.umami_public_stats_available?).to be false
    end

    it "returns true when UMAMI_SHARE_URL is set" do
      ENV["UMAMI_SHARE_URL"] = "https://stats.grenoble-roller.org/share/SFubHpdEHVbb4xAh"

      expect(helper.umami_public_stats_available?).to be true
    end
  end
end
