# frozen_string_literal: true

FactoryBot.define do
  factory :cart_line do
    user
    line_type { :product_variant }
    association :reference, factory: :product_variant
    amount_cents { 2000 }
    label { "Test product" }
    quantity { 1 }

    trait :membership do
      line_type { :membership }
      association :reference, factory: [ :membership, :pending, :with_health_questionnaire ]
      amount_cents { 1000 }
      label { "Adhésion 2025-2026" }
      quantity { 1 }
    end

    trait :event_registration do
      line_type { :event_registration }
      association :reference, factory: :attendance
      amount_cents { 500 }
      label { "Rando test — Participant" }
      quantity { 1 }
      expires_at { 15.minutes.from_now }
      metadata { { "event_id" => 1, "attendance_id" => 1 } }
    end

    trait :expired do
      expires_at { 1.minute.ago }
    end
  end
end
