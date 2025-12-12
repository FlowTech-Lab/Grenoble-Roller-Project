class Event < ApplicationRecord
  include Hashid::Rails
  
  belongs_to :creator_user, class_name: "User"
  belongs_to :route, optional: true # Parcours principal (rétrocompatibilité)
  has_many :event_loop_routes, dependent: :destroy
  has_many :loop_routes, through: :event_loop_routes, source: :route
  has_many :attendances, dependent: :destroy
  has_many :users, through: :attendances
  has_many :waitlist_entries, dependent: :destroy

  # Active Storage attachments
  has_one_attached :cover_image

  # Variants optimisés pour différents contextes d'affichage
  # Utilisation: event.cover_image.variant(:hero), event.cover_image.variant(:card), etc.

  def cover_image_hero
    return nil unless cover_image.attached?
    # Hero image (page détail) : 1200x500px max (ratio 2.4:1)
    # Desktop: 500px height, Tablet: 400px, Mobile: 300px
    cover_image.variant(resize_to_limit: [ 1200, 500 ], format: :webp, saver: { quality: 85 })
  end

  def cover_image_card
    return nil unless cover_image.attached?
    # Card event (liste) : 800x200px (ratio 4:1)
    cover_image.variant(resize_to_limit: [ 800, 200 ], format: :webp, saver: { quality: 80 })
  end

  def cover_image_card_featured
    return nil unless cover_image.attached?
    # Card featured (événement mis en avant) : 1200x350px (ratio ~3.4:1)
    cover_image.variant(resize_to_limit: [ 1200, 350 ], format: :webp, saver: { quality: 85 })
  end

  def cover_image_thumb
    return nil unless cover_image.attached?
    # Thumbnail (formulaire/admin) : 400x200px
    cover_image.variant(resize_to_limit: [ 400, 200 ], format: :webp, saver: { quality: 75 })
  end

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
  validates :description, presence: true, length: { minimum: 20, maximum: 1000 }, unless: :initiation?
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
  validates :distance_km, presence: true, numericality: { greater_than_or_equal_to: 0.1 }, unless: :initiation?

  # Méthode helper pour vérifier si c'est une initiation
  def initiation?
    is_a?(Event::Initiation)
  end

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
      max_participants
      attendances_count
      type
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

  # Calculer la distance totale si plusieurs boucles
  def total_distance_km
    # Si on utilise le nouveau système avec event_loop_routes
    if event_loop_routes.any?
      event_loop_routes.sum(:distance_km)
    # Sinon, utiliser l'ancien système (rétrocompatibilité)
    elsif loops_count && loops_count > 1
      (distance_km || 0) * loops_count
    else
      distance_km
    end
  end

  # Retourne les parcours par boucle (pour affichage)
  def loops_with_routes
    return [] unless loops_count && loops_count > 1
    
    if event_loop_routes.any?
      # Nouveau système : parcours différents par boucle
      # S'assurer que toutes les boucles sont présentes (y compris la boucle 1)
      loops_data = {}
      
      # Charger les boucles depuis event_loop_routes
      event_loop_routes.order(:loop_number).each do |elr|
        loops_data[elr.loop_number] = {
          loop_number: elr.loop_number,
          route: elr.route,
          distance_km: elr.distance_km
        }
      end
      
      # Si la boucle 1 n'est pas dans event_loop_routes, utiliser le parcours principal
      unless loops_data[1]
        loops_data[1] = {
          loop_number: 1,
          route: route,
          distance_km: distance_km
        }
      end
      
      # Retourner dans l'ordre des boucles
      (1..loops_count).map { |num| loops_data[num] }.compact
    else
      # Ancien système : même parcours pour toutes les boucles
      (1..loops_count).map do |num|
        {
          loop_number: num,
          route: route,
          distance_km: distance_km
        }
      end
    end
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
