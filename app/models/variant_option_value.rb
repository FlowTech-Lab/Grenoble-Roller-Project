class VariantOptionValue < ApplicationRecord
  belongs_to :variant, class_name: "ProductVariant"
  belongs_to :option_value
  validates :variant_id, uniqueness: { scope: :option_value_id } # index unique en DB aussi
end
