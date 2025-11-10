FactoryBot.define do
  factory :user do
    association :role
    sequence(:first_name) { |n| "User#{n}" }
    sequence(:last_name) { |n| "Tester#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    phone { '+33612345678' }

    trait :organizer do
      association :role, factory: [:role, :organizer]
    end

    trait :admin do
      association :role, factory: [:role, :admin]
    end

    trait :superadmin do
      association :role, factory: [:role, :superadmin]
    end
  end
  end
end

