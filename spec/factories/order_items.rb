# frozen_string_literal: true

FactoryBot.define do
  factory :order_item do
    association :order
    association :variant, factory: :product_variant
    quantity { 1 }
    unit_price_cents { 5000 } # Par défaut, utiliser le prix du variant
  end
end
