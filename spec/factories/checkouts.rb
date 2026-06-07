# frozen_string_literal: true

FactoryBot.define do
  factory :checkout, class: "UnifiedCheckoutDouble" do
    id { 42 }
    subtotal_cents { 5000 }
    donation_cents { 0 }
    total_cents { 5000 }
    checkout_lines { [] }

    trait :with_mixed_lines do
      after(:build) do |checkout|
        checkout.checkout_lines = [
          build(:checkout_line, :product),
          build(:checkout_line, :membership),
          build(:checkout_line, :event)
        ]
        checkout.subtotal_cents = checkout.checkout_lines.sum { |l| l.amount_cents * l.quantity }
        checkout.total_cents = checkout.subtotal_cents + checkout.donation_cents
      end
    end
  end
end
