module ProductsHelper
  def product_primary_image(product)
    return nil unless product
    return product.image if product.image.attached?

    nil
  end

  def variant_primary_image(variant)
    return nil unless variant
    return variant.images.first if variant.images.attached?

    product_primary_image(variant.product)
  end

  # Storefront square (1:1) — catalog + PDP frames are square.
  def square_image_variant(attachment, size: 800, quality: 82)
    return nil unless attachment_ready?(attachment)

    attachment.variant(
      resize_to_fill: [ size, size ],
      format: :webp,
      saver: { quality: quality }
    )
  end

  # Gallery for PDP: product image + unique variant images (pro multi-photo strip).
  def product_gallery_entries(product, variants = [])
    seen = {}
    entries = []

    append_gallery_entry = lambda do |attachment, label: nil, variant_id: nil|
      return unless attachment_ready?(attachment)

      blob_id = attachment.blob_id
      return if seen[blob_id]

      seen[blob_id] = true
      full = square_image_variant(attachment, size: 900)
      thumb = square_image_variant(attachment, size: 160)
      return unless full && thumb

      entries << {
        blob_id: blob_id,
        full_url: url_for(full),
        thumb_url: url_for(thumb),
        label: label,
        variant_id: variant_id
      }
    end

    append_gallery_entry.call(product.image, label: product.name) if product&.image&.attached?

    Array(variants).each do |variant|
      next unless variant.images.attached?

      variant.images.each_with_index do |img, idx|
        append_gallery_entry.call(
          img,
          label: "#{product.name} — vue #{idx + 1}",
          variant_id: variant.id
        )
      end
    end

    entries
  end

  def product_image_url(product)
    image = product_primary_image(product)
    return url_for(square_image_variant(image, size: 800)) if image

    nil
  end

  def variant_image_url(variant)
    image = variant_primary_image(variant)
    return url_for(square_image_variant(image, size: 800)) if image

    nil
  end

  def product_image_tag(product)
    image = product_primary_image(product)
    square_image_variant(image, size: 800) if image
  end

  def variant_image_tag(variant)
    image = variant_primary_image(variant)
    square_image_variant(image, size: 800) if image
  end

  def variant_available_stock(variant)
    return 0 unless variant
    if variant.inventory && variant.inventory.stock_qty == variant.stock_qty
      variant.inventory.available_qty
    else
      variant.stock_qty.to_i
    end
  end

  private

  def attachment_ready?(attachment)
    return false unless attachment
    return attachment.attached? if attachment.respond_to?(:attached?)

    attachment.respond_to?(:blob) && attachment.blob.present?
  end
end
