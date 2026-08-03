# frozen_string_literal: true

module TurnstileHelper
  # ENV overrides credentials so local dev can use Cloudflare test keys on localhost.
  # See https://developers.cloudflare.com/turnstile/troubleshooting/testing/
  def turnstile_site_key
    ENV["TURNSTILE_SITE_KEY"].presence ||
      Rails.application.credentials.dig(:turnstile, :site_key)
  end

  def turnstile_secret_key
    ENV["TURNSTILE_SECRET_KEY"].presence ||
      Rails.application.credentials.dig(:turnstile, :secret_key).to_s
  end

  def turnstile_enabled?
    !Rails.env.test? && turnstile_site_key.present?
  end
end
