class ProductVariant < ApplicationRecord
  belongs_to :product
  has_many :variant_option_values, foreign_key: :variant_id, dependent: :destroy
  has_many :option_values, through: :variant_option_values

  validates :sku, presence: true, uniqueness: true, length: { maximum: 80 }
  validates :price_cents, :currency, presence: true
  validates :currency, length: { is: 3 }
end
