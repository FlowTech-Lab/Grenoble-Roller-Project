# frozen_string_literal: true

FactoryBot.define do
  factory :checkout_line, class: "UnifiedCheckoutLineDouble" do
    id { 1 }
    line_type { "product_variant" }
    reference_type { "ProductVariant" }
    reference_id { 1 }
    amount_cents { 2000 }
    label { "Snapshot line" }
    quantity { 1 }
    metadata { {} }

    trait :product do
      line_type { "product_variant" }
      reference_type { "ProductVariant" }
      reference_id { 101 }
      amount_cents { 2000 }
      label { "T-shirt Grenoble Roller" }
      metadata { { sku: "SKU-TSHIRT" } }
    end

    trait :membership do
      line_type { "membership" }
      reference_type { "Membership" }
      reference_id { 202 }
      amount_cents { 1000 }
      label { "Adhésion 2025-2026" }
    end

    trait :event do
      line_type { "event_registration" }
      reference_type { "Attendance" }
      reference_id { 303 }
      amount_cents { 1500 }
      label { "Rando du samedi" }
      metadata { { event_id: 55 } }
    end
  end
end
