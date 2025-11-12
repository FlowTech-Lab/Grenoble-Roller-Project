FactoryBot.define do
  factory :attendance do
    association :user
    association :event
    status { 'registered' }
    stripe_customer_id { 'cus_test' }
    wants_reminder { false }

    trait :paid do
      status { 'paid' }
    end

    trait :canceled do
      status { 'canceled' }
    end

    trait :with_reminder do
      wants_reminder { true }
    end
  end
end

