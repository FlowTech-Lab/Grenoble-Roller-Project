class Product < ApplicationRecord
  belongs_to :category, class_name: "ProductCategory"
  has_many :product_variants, dependent: :destroy

  validates :name, :slug, :price_cents, :currency, :image_url, presence: true
  validates :name, length: { maximum: 140 }
  validates :slug, length: { maximum: 160 }, uniqueness: true
  validates :currency, length: { is: 3 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id category_id name slug description price_cents currency stock_qty is_active image_url created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[category product_variants]
  end
end
