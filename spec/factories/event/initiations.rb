FactoryBot.define do
  factory :event_initiation, class: 'Event::Initiation' do
    association :creator_user, factory: :user
    type { 'Event::Initiation' }

    # Calculer le prochain samedi à 10h15
    start_at do
      today = Date.today
      days_until_saturday = (6 - today.wday) % 7
      days_until_saturday = 7 if days_until_saturday == 0 && Time.current.hour >= 10
      (today + days_until_saturday.days).beginning_of_day + 10.hours + 15.minutes
    end

    duration_min { 105 } # 1h45
    title { "Initiation Roller - Samedi #{start_at.strftime('%d %B %Y')}" }
    description { "Cours d'initiation au roller pour débutants" }
    location_text { "Gymnase Ampère, 74 Rue Anatole France, 38100 Grenoble" }
    meeting_lat { 45.1891 }
    meeting_lng { 5.7317 }
    max_participants { 30 }
    status { 'published' }
    season { '2025-2026' }
    is_recurring { true }
    recurring_day { 'saturday' }
    recurring_time { '10:15' }
    level { 'beginner' }
    distance_km { 0 }
    price_cents { 0 }
    currency { 'EUR' }

    trait :full do
      after(:create) do |initiation|
        create_list(:attendance, initiation.max_participants, event: initiation, is_volunteer: false, status: 'registered')
      end
    end

    trait :with_volunteers do
      after(:create) do |initiation|
        create_list(:attendance, 3, event: initiation, is_volunteer: true, status: 'registered')
      end
    end
  end
end
