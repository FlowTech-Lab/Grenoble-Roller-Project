class Event < ApplicationRecord
  belongs_to :creator_user, class_name: "User"
  belongs_to :route, optional: true
  has_many :attendances, dependent: :destroy
  has_many :users, through: :attendances

  enum :status, {
    draft: "draft",      # Brouillon / En attente de validation
    published: "published", # Publié / Validé
    rejected: "rejected",   # Refusé (demande non aboutie)
    canceled: "canceled"    # Annulé
  }, validate: true

  # Traductions des statuts en français
  def status_label
    case status
    when "draft"
      "En attente de validation"
    when "published"
      "Publié"
    when "rejected"
      "Refusé"
    when "canceled"
      "Annulé"
    else
      status.humanize
    end
  end
  enum :level, { beginner: "beginner", intermediate: "intermediate", advanced: "advanced", all_levels: "all_levels" }, validate: true, prefix: true

  validates :status, presence: true
  validates :start_at, presence: true
  validates :duration_min, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :duration_multiple_of_five
  validates :title, presence: true, length: { minimum: 5, maximum: 140 }
  validates :description, presence: true, length: { minimum: 20, maximum: 1000 }
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, length: { is: 3 }
  validates :location_text, presence: true, length: { minimum: 3, maximum: 255 }
  validates :max_participants, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # GPS optionnel, mais si meeting_lat présente, meeting_lng obligatoire et vice-versa
  validates :meeting_lat, presence: true, if: :meeting_lng?
  validates :meeting_lng, presence: true, if: :meeting_lat?
  validates :meeting_lat, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :meeting_lng, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true

  # Niveau et distance toujours requis
  validates :level, presence: true
  validates :distance_km, presence: true, numericality: { greater_than_or_equal_to: 0.1 }

  scope :upcoming, -> { where("start_at > ?", Time.current) }
  scope :past, -> { where("start_at <= ?", Time.current) }
  scope :published, -> { where(status: "published") }

  # Événements visibles pour les utilisateurs (publiés + annulés pour information)
  scope :visible, -> { where(status: [ "published", "canceled" ]) }

  # Événements en attente de validation (pour les modérateurs)
  scope :pending_validation, -> { where(status: "draft") }

  # Événements refusés (pour les modérateurs)
  scope :rejected, -> { where(status: "rejected") }

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      id
      title
      status
      start_at
      duration_min
      price_cents
      currency
      location_text
      meeting_lat
      meeting_lng
      route_id
      level
      distance_km
      creator_user_id
      cover_image_url
      max_participants
      attendances_count
      created_at
      updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[attendances creator_user route users]
  end

  # Vérifie si l'événement a une limite de participants (0 = illimité)
  def unlimited?
    max_participants.zero?
  end

  # Vérifie si l'événement est plein (compte uniquement les inscriptions actives)
  def full?
    return false if unlimited?

    active_attendances_count >= max_participants
  end

  # Retourne le nombre de places restantes
  def remaining_spots
    return nil if unlimited?

    [ max_participants - active_attendances_count, 0 ].max
  end

  # Vérifie s'il reste des places disponibles
  def has_available_spots?
    unlimited? || active_attendances_count < max_participants
  end

  # Compte les inscriptions actives (non annulées)
  def active_attendances_count
    attendances.active.count
  end

  # Vérifie si l'événement est passé
  def past?
    start_at <= Time.current
  end

  # Vérifie si l'événement a été créé récemment (dans les 4 dernières semaines)
  def recent?
    created_at >= 7.days.ago
  end

  # Vérifie si l'événement a des coordonnées GPS
  def has_gps_coordinates?
    meeting_lat.present? && meeting_lng.present?
  end

  # Retourne l'URL Google Maps pour les coordonnées GPS
  def google_maps_url
    return nil unless has_gps_coordinates?
    "https://www.google.com/maps?q=#{meeting_lat},#{meeting_lng}"
  end

  # Retourne l'URL Waze pour les coordonnées GPS
  def waze_url
    return nil unless has_gps_coordinates?
    "https://www.waze.com/ul?ll=#{meeting_lat},#{meeting_lng}&navigate=yes"
  end

  private

  def duration_multiple_of_five
    return if duration_min.blank?

    errors.add(:duration_min, "must be a multiple of 5") unless (duration_min % 5).zero?
  end
end
