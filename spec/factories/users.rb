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

    trait :initiation do
      after(:build) do |user|
        user.role = Role.find_or_create_by!(code: 'INITIATION') do |role|
          role.name = 'Initiation'
          role.level = 30
        end
      end
    end

    trait :organizer do
      after(:build) do |user|
        user.role = Role.find_or_create_by!(code: 'ORGANIZER') do |role|
          role.name = 'Organisateur'
          role.level = 40
        end
      end
    end

    trait :moderator do
      after(:build) do |user|
        user.role = Role.find_or_create_by!(code: 'MODERATOR') do |role|
          role.name = 'Modérateur'
          role.level = 50
        end
      end
    end

    trait :admin do
      after(:build) do |user|
        user.role = Role.find_or_create_by!(code: 'ADMIN') do |role|
          role.name = 'Administrateur'
          role.level = 60
        end
      end
    end

    trait :superadmin do
      after(:build) do |user|
        user.role = Role.find_or_create_by!(code: 'SUPERADMIN') do |role|
          role.name = 'Super Administrateur'
          role.level = 70
        end
      end
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
