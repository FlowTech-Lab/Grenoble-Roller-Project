class RollerStock < ApplicationRecord
  include Hashid::Rails
  
  # Tailles de rollers courantes (en EU)
  SIZES = %w[28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48].freeze
  
  validates :size, presence: true, uniqueness: true, inclusion: { in: SIZES }
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :is_active, inclusion: { in: [ true, false ] }
  
  scope :active, -> { where(is_active: true) }
  scope :available, -> { active.where("quantity > 0") }
  scope :ordered_by_size, -> { order(Arel.sql("CAST(size AS INTEGER)")) }
  
  def available?
    is_active? && quantity > 0
  end
  
  def out_of_stock?
    quantity <= 0
  end
  
  def size_with_stock
    "#{size} (#{quantity} disponible#{'s' if quantity > 1})"
  end
  
  def self.ransackable_attributes(_auth_object = nil)
    %w[id size quantity is_active created_at updated_at]
  end
  
  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
