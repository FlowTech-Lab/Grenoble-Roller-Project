class Route < ApplicationRecord
  include Hashid::Rails
  
  has_many :events, dependent: :nullify

  # Active Storage attachments
  has_one_attached :map_image

  validates :name, presence: true, length: { maximum: 140 }
  validates :difficulty, inclusion: { in: %w[easy medium hard] }, allow_nil: true
  validates :distance_km, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :elevation_m, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name difficulty distance_km elevation_m gpx_url map_image_url safety_notes created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[events]
  end
end
