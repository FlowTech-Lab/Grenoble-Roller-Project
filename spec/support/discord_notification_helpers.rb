# frozen_string_literal: true

module DiscordNotificationHelpers
  DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/123456789012345678/abcdefghijklmnopqrstuvwxyz1234567890"

  def allow_discord_notifications!
    allow(Rails.env).to receive(:production?).and_return(true)
    ENV["ALLOW_DISCORD_NOTIFICATIONS"] = "true"
  end

  def block_discord_notifications!
    allow(Rails.env).to receive(:production?).and_return(false)
    ENV.delete("ALLOW_DISCORD_NOTIFICATIONS")
  end
end

RSpec.configure do |config|
  config.include DiscordNotificationHelpers

  config.after do
    ENV.delete("ALLOW_DISCORD_NOTIFICATIONS")
  end
end
