# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    association :category, factory: :product_category
    name { 'Roller Quad' }
    slug { "roller-quad-#{SecureRandom.hex(4)}" }
    description { 'Description du produit' }
    price_cents { 5000 }
    currency { 'EUR' }
    image_url { 'https://example.com/image.jpg' }
    is_active { true }

    trait :with_variant do
      after(:create) do |product|
        create(:product_variant, product: product, is_active: true)
        product.reload
      end
    end
  end
end
