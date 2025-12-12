class Event::Initiation < Event
  # Scopes spécifiques
  scope :upcoming_initiations, -> { where("start_at > ?", Time.current).order(:start_at) }

  # Validations spécifiques aux initiations
  # distance_km : doit être 0 (pas de parcours) - la validation du parent est désactivée avec unless: :initiation?
  validates :distance_km, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # description : assouplir la validation (minimum 10 caractères au lieu de 20)
  # La validation du parent est désactivée avec unless: :initiation?, on redéfinit ici
  validates :description, presence: true, length: { minimum: 10, maximum: 1000 }

  # Validations spécifiques
  validates :max_participants, presence: true, numericality: { greater_than: 0 }

  # Callback pour forcer distance_km = 0 pour les initiations (avant validation)
  before_validation :set_distance_km_to_zero, on: [ :create, :update ]

  # Méthodes métier
  def full?
    available_places <= 0
  end

  def available_places
    max_participants - participants_count
  end

  def participants_count
    attendances.where(is_volunteer: false, status: [ "registered", "present" ]).count
  end

  def volunteers_count
    attendances.where(is_volunteer: true).count
  end

  # Override pour initiations : max_participants doit être > 0 (pas illimité)
  def unlimited?
    false
  end

  private

  def set_distance_km_to_zero
    self.distance_km = 0
  end
end
