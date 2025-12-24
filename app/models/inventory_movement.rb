class InventoryMovement < ApplicationRecord
  belongs_to :inventory
  belongs_to :user, optional: true
  
  REASONS = %w[
    initial_stock
    purchase
    adjustment
    damage
    loss
    return
    reserved
    released
    order_fulfilled
  ].freeze
  
  validates :reason, inclusion: { in: REASONS }
  validates :quantity, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_reason, ->(reason) { where(reason: reason) }
  
  def self.ransackable_attributes(_auth_object = nil)
    %w[id inventory_id user_id quantity reason reference created_at]
  end
  
  def self.ransackable_associations(_auth_object = nil)
    %w[inventory user]
  end
end

