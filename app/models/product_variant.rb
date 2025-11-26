class ProductVariant < ApplicationRecord
  belongs_to :product
  has_many :variant_option_values, foreign_key: :variant_id, dependent: :destroy
  has_many :option_values, through: :variant_option_values

  validates :sku, presence: true, uniqueness: true, length: { maximum: 80 }
  validates :price_cents, :currency, :image_url, presence: true
  validates :currency, length: { is: 3 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id product_id sku price_cents currency stock_qty is_active created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[product option_values]
  end
end
