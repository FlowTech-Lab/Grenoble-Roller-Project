# frozen_string_literal: true

# Umami web analytics — UX metrics only, gated by ENV and cookie consent.
# See docs/08-security-privacy/umami-analytics.md
module AnalyticsHelper
  def umami_script_url
    ENV["UMAMI_SCRIPT_URL"].to_s.strip.presence
  end

  def umami_website_id
    ENV["UMAMI_WEBSITE_ID"].to_s.strip.presence
  end

  def umami_dashboard_url
    ENV["UMAMI_DASHBOARD_URL"].to_s.strip.presence
  end

  def umami_share_url
    ENV["UMAMI_SHARE_URL"].to_s.strip.presence
  end

  def umami_configured?
    umami_script_url.present? && umami_website_id.present?
  end

  def umami_public_stats_available?
    umami_share_url.present?
  end

  def umami_tracking_allowed?
    umami_configured? && cookie_consent?(:analytics)
  end
end
