FactoryBot.define do
  factory :attendance do
    association :user
    association :event
    status { 'registered' }
    stripe_customer_id { 'cus_test' }

    trait :paid do
      status { 'paid' }
    end

    trait :canceled do
      status { 'canceled' }
    end
  end
end

