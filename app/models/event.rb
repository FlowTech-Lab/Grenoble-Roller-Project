class Event < ApplicationRecord
  belongs_to :creator_user, class_name: 'User'
  belongs_to :route, optional: true
  has_many :attendances, dependent: :destroy
  has_many :users, through: :attendances

  enum :status, { draft: 'draft', published: 'published', canceled: 'canceled' }, validate: true

  validates :status, presence: true
  validates :start_at, presence: true
  validates :duration_min, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :duration_multiple_of_five
  validates :title, presence: true, length: { minimum: 5, maximum: 140 }
  validates :description, presence: true, length: { minimum: 20, maximum: 1000 }
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, length: { is: 3 }
  validates :location_text, presence: true, length: { maximum: 255 }

  scope :upcoming, -> { where('start_at > ?', Time.current) }
  scope :past, -> { where('start_at <= ?', Time.current) }
  scope :published, -> { where(status: 'published') }

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
      creator_user_id
      cover_image_url
      created_at
      updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[attendances creator_user route users]
  end

  def full?
    # Si vous avez un max_participants, vérifier ici
    false
  end

  private

  def duration_multiple_of_five
    return if duration_min.blank?

    errors.add(:duration_min, 'must be a multiple of 5') unless (duration_min % 5).zero?
  end
end

