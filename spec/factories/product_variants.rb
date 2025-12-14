# frozen_string_literal: true

FactoryBot.define do
  factory :product_variant do
    association :product
    sku { "SKU-#{SecureRandom.hex(4)}" }
    price_cents { 5000 }
    currency { 'EUR' }
    image_url { 'https://example.com/variant-image.jpg' }
    stock_qty { 10 }
    is_active { true }
  end
end

