class OptionValue < ApplicationRecord
  belongs_to :option_type
  has_many :variant_option_values, dependent: :destroy
  has_many :product_variants, through: :variant_option_values
  validates :value, presence: true, length: { maximum: 50 }
end
