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
  validate :is_saturday, :is_correct_time, :is_correct_location
  
  # Callback pour forcer distance_km = 0 pour les initiations (avant validation)
  before_validation :set_distance_km_to_zero, on: [:create, :update]
  
  # Méthodes métier
  def full?
    available_places <= 0
  end
  
  def available_places
    max_participants - participants_count
  end
  
  def participants_count
    attendances.where(is_volunteer: false, status: ['registered', 'present']).count
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
  
  def is_saturday
    return if start_at.blank?
    errors.add(:start_at, "doit être un samedi") unless start_at.saturday?
  end
  
  def is_correct_time
    return if start_at.blank?
    errors.add(:start_at, "doit commencer à 10h15") unless start_at.hour == 10 && start_at.min == 15
  end
  
  def is_correct_location
    return if location_text.blank?
    errors.add(:location_text, "doit être le Gymnase Ampère") unless location_text.include?("Gymnase Ampère")
  end
end

