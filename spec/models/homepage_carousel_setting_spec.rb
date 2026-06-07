# frozen_string_literal: true

require "rails_helper"

RSpec.describe HomepageCarouselSetting, type: :model do
  describe ".current" do
    it "returns a singleton record with defaults" do
      setting = described_class.current

      expect(setting.id).to eq(HomepageCarouselSetting::SINGLETON_ID)
      expect(setting.autoplay_enabled).to be(true)
      expect(setting.interval_seconds).to eq(6)
    end

    it "returns the same record on subsequent calls" do
      first = described_class.current
      second = described_class.current

      expect(second.id).to eq(first.id)
    end
  end

  describe "#interval_ms" do
    it "converts interval_seconds to milliseconds" do
      setting = described_class.new(interval_seconds: 6)

      expect(setting.interval_ms).to eq(6000)
    end
  end

  describe "validations" do
    it "is valid with interval_seconds in range" do
      setting = described_class.new(interval_seconds: 10, autoplay_enabled: true)

      expect(setting).to be_valid
    end

    it "is invalid when interval_seconds is below minimum" do
      setting = described_class.new(interval_seconds: 1, autoplay_enabled: true)

      expect(setting).to be_invalid
      expect(setting.errors[:interval_seconds]).to be_present
    end

    it "is invalid when interval_seconds is above maximum" do
      setting = described_class.new(interval_seconds: 31, autoplay_enabled: true)

      expect(setting).to be_invalid
      expect(setting.errors[:interval_seconds]).to be_present
    end
  end
end
