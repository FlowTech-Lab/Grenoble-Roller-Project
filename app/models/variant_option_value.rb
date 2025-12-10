class VariantOptionValue < ApplicationRecord
  belongs_to :variant, class_name: "ProductVariant"
  belongs_to :option_value
  validates :variant_id, uniqueness: { scope: :option_value_id } # index unique en DB aussi

  def self.ransackable_attributes(_auth_object = nil)
    %w[id variant_id option_value_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[variant option_value]
  end
end
