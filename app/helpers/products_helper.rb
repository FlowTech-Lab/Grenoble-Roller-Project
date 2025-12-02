module ProductsHelper
  # Helper pour obtenir l'URL de l'image d'un produit (Active Storage ou URL string)
  def product_image_url(product)
    return url_for(product.image) if product&.image&.attached?
    return product.image_url if product&.image_url.present?
    nil
  end

  # Helper pour obtenir l'URL de l'image d'une variante (Active Storage ou URL ou fallback produit)
  def variant_image_url(variant)
    return url_for(variant.image) if variant&.image&.attached?
    return variant.image_url if variant&.image_url.present?
    product_image_url(variant.product) if variant.product
  end

  # Helper pour obtenir l'objet image (pour image_tag direct)
  def product_image_tag(product)
    return product.image if product&.image&.attached?
    return product.image_url if product&.image_url.present?
    nil
  end

  def variant_image_tag(variant)
    return variant.image if variant&.image&.attached?
    return variant.image_url if variant&.image_url.present?
    product_image_tag(variant.product) if variant.product
  end
end
