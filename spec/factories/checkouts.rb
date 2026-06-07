# frozen_string_literal: true

FactoryBot.define do
  factory :checkout do
    user
    status { :pending }
    subtotal_cents { 5000 }
    donation_cents { 0 }
    total_cents { 5000 }
    metadata { {} }

    trait :with_mixed_lines do
      after(:create) do |checkout|
        create(:checkout_line, :product, checkout: checkout)
        create(:checkout_line, :membership, checkout: checkout)
        create(:checkout_line, :event, checkout: checkout)
        subtotal = checkout.checkout_lines.sum(&:subtotal_cents)
        checkout.update!(subtotal_cents: subtotal, total_cents: subtotal + checkout.donation_cents)
      end
    end

    trait :processing do
      status { :processing }
    end

    trait :paid do
      status { :paid }
    end
  end
end
