class OptionValue < ApplicationRecord
  belongs_to :option_type
  has_many :variant_option_values, dependent: :destroy
  has_many :product_variants, through: :variant_option_values, source: :variant
  validates :value, presence: true, length: { maximum: 50 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id option_type_id value created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[option_type variant_option_values product_variants]
  end
end
