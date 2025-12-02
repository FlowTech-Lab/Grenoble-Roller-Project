module EventsHelper
  FALLBACK_EVENT_IMAGE = "img/roller.png"

  # Helper pour obtenir l'URL de l'image de fallback (image par défaut)
  # Utilisé uniquement quand aucune image Active Storage n'est attachée
  def event_cover_image_url(event)
    fallback_image_path
  end

  # Helper pour obtenir l'image (Active Storage ou fallback)
  def event_cover_image(event)
    if event&.cover_image&.attached?
      event.cover_image
    else
      event_cover_image_url(event)
    end
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
