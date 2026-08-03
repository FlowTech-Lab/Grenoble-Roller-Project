# frozen_string_literal: true

module PagesHelper
  def homepage_hero_banner(settings = HomepageCarouselSetting.current, &block)
    options = { class: "banner-hero mb-0" }

    if settings.custom_hero_image?
      options[:class] = "banner-hero banner-hero--custom mb-0"
      options[:style] = "background-image: url('#{url_for(settings.hero_image_banner_variant)}')"
    end

    tag.div(**options, &block)
  end
end
