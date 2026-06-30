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

  describe "#custom_hero_image?" do
    it "returns false when no hero image is attached" do
      setting = described_class.current

      expect(setting.custom_hero_image?).to be(false)
    end

    it "returns true when a hero image is attached" do
      setting = described_class.current
      attach_test_hero_image(setting)

      expect(setting.custom_hero_image?).to be(true)
    end
  end

  describe "hero image validation" do
    it "rejects unsupported content types" do
      setting = described_class.current
      setting.hero_image.attach(
        io: StringIO.new("not-an-image"),
        filename: "hero.txt",
        content_type: "text/plain"
      )

      expect(setting).to be_invalid
      expect(setting.errors[:hero_image]).to be_present
    end
  end

  def attach_test_hero_image(setting)
    test_image_path = Rails.root.join("spec", "fixtures", "files", "test-image.jpg")
    setting.hero_image.attach(
      io: File.open(test_image_path),
      filename: "test-image.jpg",
      content_type: "image/jpeg"
    )
  end
end
