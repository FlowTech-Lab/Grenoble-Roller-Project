class Route < ApplicationRecord
  has_many :events, dependent: :nullify

  validates :name, presence: true, length: { maximum: 140 }
  validates :difficulty, inclusion: { in: %w[easy medium hard] }, allow_nil: true
  validates :distance_km, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :elevation_m, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end

