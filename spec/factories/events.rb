FactoryBot.define do
  factory :event do
    association :creator_user, factory: :user
    association :route

    status { 'draft' }
    start_at { 3.days.from_now }
    duration_min { 60 }
    max_participants { 0 } # 0 = illimité par défaut
    sequence(:title) { |n| "Roller Session ##{n}" }
    description { 'Session hebdomadaire pour rouler ensemble dans les rues de Grenoble.' }
    price_cents { 0 }
    currency { 'EUR' }
    location_text { 'Grenoble, place Victor Hugo' }
    meeting_lat { 45.1885 }
    meeting_lng { 5.7245 }
    cover_image_url { nil }

    trait :published do
      status { 'published' }
    end

    trait :upcoming do
      start_at { 1.week.from_now }
    end

    trait :past do
      start_at { 2.days.ago }
    end

    trait :with_limit do
      max_participants { 20 }
    end

    trait :unlimited do
      max_participants { 0 }
    end
  end
end
