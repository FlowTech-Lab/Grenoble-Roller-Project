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

    after(:build) do |initiation|
      # Attacher une image de test si aucune image n'est déjà attachée
      unless initiation.cover_image.attached?
        # Créer un fichier JPEG minimal valide (1x1 pixel)
        test_image_path = Rails.root.join('spec', 'fixtures', 'files', 'test-image.jpg')
        FileUtils.mkdir_p(test_image_path.dirname)
        unless test_image_path.exist?
          # JPEG minimal valide (1x1 pixel noir)
          jpeg_data = "\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00\xFF\xDB\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t\x08\n\f\x14\r\f\x0B\x0B\f\x19\x12\x13\x0F\x14\x1D\x1A\x1F\x1E\x1D\x1A\x1C\x1C $.' \",#\x1C\x1C(7),01444\x1F'9=82<.342\xFF\xC0\x00\x0B\x08\x00\x01\x00\x01\x01\x01\x11\x00\xFF\xC4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\xFF\xC4\x00\x14\x10\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xDA\x00\x08\x01\x01\x00\x00?\x00\xAA\xFF\xD9"
          File.binwrite(test_image_path, jpeg_data)
        end
        initiation.cover_image.attach(
          io: File.open(test_image_path),
          filename: 'test-image.jpg',
          content_type: 'image/jpeg'
        )
      end
    end

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
