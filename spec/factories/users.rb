FactoryBot.define do
  factory :user do
    association :role
    sequence(:first_name) { |n| "User#{n}" }
    sequence(:last_name) { |n| "Tester#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password12345' } # Minimum 12 caractères requis
    phone { '0612345678' }
    skill_level { 'intermediate' }
    confirmed_at { Time.current } # Par défaut, utilisateur confirmé

    trait :organizer do
      association :role, factory: [ :role, :organizer ]
    end

    trait :admin do
      association :role, factory: [ :role, :admin ]
    end

    trait :superadmin do
      association :role, factory: [ :role, :superadmin ]
    end

    trait :unconfirmed do
      confirmed_at { nil }
      confirmation_sent_at { Time.current }
    end

    trait :beginner do
      skill_level { 'beginner' }
    end

    trait :advanced do
      skill_level { 'advanced' }
    end
  end
end
