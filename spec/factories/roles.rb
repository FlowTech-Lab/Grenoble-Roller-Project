FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Role #{n}" }
    sequence(:code) { |n| "ROLE_#{n}" }
    level { 10 }

    trait :organizer do
      level { 40 }
    end

    trait :admin do
      level { 60 }
    end

    trait :superadmin do
      level { 70 }
    end
  end
end
