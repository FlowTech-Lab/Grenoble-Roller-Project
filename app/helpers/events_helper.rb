module EventsHelper
  FALLBACK_EVENT_IMAGE = "img/roller.png"

  def event_cover_image_url(event)
    source = event&.cover_image_url

    return fallback_image_path if source.blank?
    return source if source.start_with?("http://", "https://")

    asset_exists?(source) ? asset_path(source) : fallback_image_path
  end

  private

  def fallback_image_path
    asset_path(FALLBACK_EVENT_IMAGE)
  end

  def asset_exists?(logical_path)
    return false if logical_path.blank?

    load_path = Rails.application.assets
    manifest = Rails.application.assets_manifest

    from_load_path = load_path&.respond_to?(:load_path) && load_path.load_path.find(logical_path).present?
    from_manifest = manifest&.respond_to?(:assets) && manifest.assets[logical_path].present?

    from_load_path || from_manifest
  rescue StandardError
    false
  end
end
