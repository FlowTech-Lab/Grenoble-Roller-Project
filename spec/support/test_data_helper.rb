require 'securerandom'

module TestDataHelper
  def ensure_role(code: 'USER', name: nil, level: 10)
    Role.find_or_create_by!(code: code) do |role|
      role.name = name || code.capitalize
      role.level = level
    end
  end

  def build_user(attrs = {})
    role = attrs.delete(:role) || ensure_role(code: 'USER', name: 'User', level: 10)
    defaults = {
      first_name: 'Alex',
      last_name: 'Rider',
      email: "user#{SecureRandom.hex(4)}@example.com",
      # Doit respecter la validation de longueur minimale (12 caractères)
      password: 'password12345',
      skill_level: 'intermediate',
      role: role
    }

    User.new(defaults.merge(attrs))
  end

  def create_user(attrs = {})
    user = build_user(attrs)
    user.save!
    user
  end

  def build_route(attrs = {})
    defaults = {
      name: 'Boucle Bastille',
      difficulty: 'easy',
      distance_km: 12.5,
      elevation_m: 150
    }
    Route.new(defaults.merge(attrs))
  end

  def create_route(attrs = {})
    route = build_route(attrs)
    route.save!
    route
  end

  def build_event(attrs = {})
    creator = attrs.delete(:creator_user) || create_user
    route   = attrs.key?(:route) ? attrs.delete(:route) : create_route
    defaults = {
      creator_user: creator,
      route: route,
      status: 'draft',
      start_at: 2.days.from_now,
      duration_min: 60,
      title: 'Evening Ride',
      description: 'An engaging rollerblading event description.',
      price_cents: 0,
      currency: 'EUR',
      location_text: 'Grenoble City Center'
    }

    event = Event.new(defaults.merge(attrs))
    
    # Attacher une image de test si aucune image n'est déjà attachée
    unless event.cover_image.attached?
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
    
    event
  end

  def create_event(attrs = {})
    event = build_event(attrs)
    # Pour certains tests de modèles, on ne veut pas échouer sur des validations
    # d'Event (image, distance_km, etc.). On autorise donc la sauvegarde sans validation.
    event.save(validate: false)
    event
  end

  def build_attendance(attrs = {})
    user = attrs.delete(:user) || create_user
    event = attrs.delete(:event) || create_event
    defaults = {
      user: user,
      event: event,
      status: 'registered',
      stripe_customer_id: 'cus_123'
    }
    Attendance.new(defaults.merge(attrs))
  end

  def create_attendance(attrs = {})
    attendance = build_attendance(attrs)
    attendance.save!
    attendance
  end
end
