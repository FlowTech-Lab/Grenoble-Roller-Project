FactoryBot.define do
  factory :membership do
    association :user
    status { :active }
    category { :standard }
    start_date { Date.new(2025, 9, 1) }
    end_date { Date.new(2026, 8, 31) }
    amount_cents { 1000 } # 10€
    currency { 'EUR' }
    season { '2025-2026' }
    is_minor { false }
    is_child_membership { false }
    rgpd_consent { true }
    legal_notices_accepted { true }

    trait :child do
      is_child_membership { true }
      is_minor { true }
      child_first_name { 'Jack' }
      child_last_name { 'Doe' }
      child_date_of_birth { Date.new(2017, 9, 27) }
      parent_name { 'John Doe' }
      parent_email { 'parent@example.com' }
      parent_phone { '0612345678' }
      parent_authorization { true }
    end

    trait :pending do
      status { :pending }
    end

    trait :expired do
      status { :expired }
    end
  end
end

