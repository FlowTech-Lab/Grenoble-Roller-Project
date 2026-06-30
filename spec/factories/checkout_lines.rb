# frozen_string_literal: true

FactoryBot.define do
  factory :checkout_line do
    checkout
    line_type { :product_variant }
    association :reference, factory: :product_variant
    amount_cents { 2000 }
    label { "Snapshot line" }
    quantity { 1 }
    metadata { {} }

    trait :product do
      line_type { :product_variant }
      association :reference, factory: :product_variant
      amount_cents { 2000 }
      label { "T-shirt Grenoble Roller" }
      metadata { { "sku" => "SKU-TSHIRT" } }
    end

    trait :membership do
      line_type { :membership }
      association :reference, factory: [ :membership, :pending, :with_health_questionnaire ]
      amount_cents { 1000 }
      label { "Adhésion 2025-2026" }
    end

    trait :event do
      line_type { :event_registration }
      association :reference, factory: :attendance
      amount_cents { 1500 }
      label { "Rando du samedi" }
      metadata { { "event_id" => 55 } }
    end
  end
end
