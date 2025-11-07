class Event < ApplicationRecord
  belongs_to :creator_user, class_name: 'User'
  belongs_to :route, optional: true
  has_many :attendances, dependent: :destroy
  has_many :users, through: :attendances

  enum :status, { draft: 'draft', published: 'published', canceled: 'canceled' }, validate: true

  validates :status, presence: true
  validates :start_at, presence: true
  validates :duration_min, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :duration_min, numericality: { multiple_of: 5 }, if: -> { duration_min.present? }
  validates :title, presence: true, length: { minimum: 5, maximum: 140 }
  validates :description, presence: true, length: { minimum: 20, maximum: 1000 }
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, length: { is: 3 }
  validates :location_text, presence: true, length: { maximum: 255 }

  scope :upcoming, -> { where('start_at > ?', Time.current) }
  scope :past, -> { where('start_at <= ?', Time.current) }
  scope :published, -> { where(status: 'published') }

  def full?
    # Si vous avez un max_participants, vérifier ici
    false
  end
end

