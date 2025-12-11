class EventLoopRoute < ApplicationRecord
  belongs_to :event
  belongs_to :route

  validates :loop_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :distance_km, presence: true, numericality: { greater_than_or_equal_to: 0.1 }
  validates :loop_number, uniqueness: { scope: :event_id }

  # Ransack pour ActiveAdmin
  def self.ransackable_attributes(_auth_object = nil)
    %w[id event_id route_id loop_number distance_km created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[event route]
  end
end

