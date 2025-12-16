FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Role #{n}" }
    sequence(:code) { |n| "ROLE_#{n}" }
    level { 10 }

    trait :organizer do
      code { 'ORGANIZER' }
      name { 'Organisateur' }
      level { 40 }
    end

    trait :admin do
      code { 'ADMIN' }
      name { 'Administrateur' }
      level { 60 }
    end

    trait :superadmin do
      code { 'SUPERADMIN' }
      name { 'Super Administrateur' }
      level { 70 }
    end
  end
end
