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
      location_text: 'Grenoble City Center',
      # Champs devenus obligatoires sur Event
      level: 'beginner',
      distance_km: 10.0
    }

    Event.new(defaults.merge(attrs))
  end

  def create_event(attrs = {})
    # Utiliser build_event qui gère correctement les attributs par défaut
    event = build_event(attrs)
    event.save!
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
