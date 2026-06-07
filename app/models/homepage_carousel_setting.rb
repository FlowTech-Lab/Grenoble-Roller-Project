# frozen_string_literal: true

class HomepageCarouselSetting < ApplicationRecord
  INTERVAL_SECONDS_RANGE = (2..30).freeze
  SINGLETON_ID = 1

  validates :interval_seconds,
            presence: true,
            numericality: { only_integer: true, in: INTERVAL_SECONDS_RANGE }

  def self.current
    find_or_create_by!(id: SINGLETON_ID) do |setting|
      setting.autoplay_enabled = true
      setting.interval_seconds = 6
    end
  end

  def interval_ms
    interval_seconds * 1000
  end
end
