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
    level { 'intermediate' }
    distance_km { 10.0 }

    # Attacher une image de test - utiliser after(:build) pour que l'image soit attachée avant la validation
    after(:build) do |event|
      # Toujours attacher une image pour les tests (même pour les drafts, au cas où)
      unless event.cover_image.attached?
        # Créer un fichier JPEG minimal valide (1x1 pixel)
        test_image_path = Rails.root.join('spec', 'fixtures', 'files', 'test-image.jpg')
        FileUtils.mkdir_p(test_image_path.dirname)
        unless test_image_path.exist?
          # JPEG minimal valide (1x1 pixel noir)
          jpeg_data = "\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00\xFF\xDB\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t\x08\n\f\x14\r\f\x0B\x0B\f\x19\x12\x13\x0F\x14\x1D\x1A\x1F\x1E\x1D\x1A\x1C\x1C $.' \",#\x1C\x1C(7),01444\x1F'9=82<.342\xFF\xC0\x00\x0B\x08\x00\x01\x00\x01\x01\x01\x11\x00\xFF\xC4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\xFF\xC4\x00\x14\x10\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xDA\x00\x08\x01\x01\x00\x00?\x00\xAA\xFF\xD9"
          File.binwrite(test_image_path, jpeg_data)
        end
        event.cover_image.attach(
          io: File.open(test_image_path),
          filename: 'test-image.jpg',
          content_type: 'image/jpeg'
        )
      end
    end
    
    # S'assurer que l'image est attachée après création pour les événements publiés
    after(:create) do |event|
      if (event.published? || event.canceled?) && !event.cover_image.attached?
        test_image_path = Rails.root.join('spec', 'fixtures', 'files', 'test-image.jpg')
        FileUtils.mkdir_p(test_image_path.dirname)
        unless test_image_path.exist?
          jpeg_data = "\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00\xFF\xDB\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t\x08\n\f\x14\r\f\x0B\x0B\f\x19\x12\x13\x0F\x14\x1D\x1A\x1F\x1E\x1D\x1A\x1C\x1C $.' \",#\x1C\x1C(7),01444\x1F'9=82<.342\xFF\xC0\x00\x0B\x08\x00\x01\x00\x01\x01\x01\x11\x00\xFF\xC4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\xFF\xC4\x00\x14\x10\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xDA\x00\x08\x01\x01\x00\x00?\x00\xAA\xFF\xD9"
          File.binwrite(test_image_path, jpeg_data)
        end
        event.cover_image.attach(
          io: File.open(test_image_path),
          filename: 'test-image.jpg',
          content_type: 'image/jpeg'
        )
        event.save!
      end
    end


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
