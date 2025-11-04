class Product < ApplicationRecord
  belongs_to :category, class_name: "ProductCategory"
  has_many :product_variants, dependent: :destroy

  validates :name, :slug, :price_cents, :currency, presence: true
  validates :name, length: { maximum: 140 }
  validates :slug, length: { maximum: 160 }, uniqueness: true
  validates :currency, length: { is: 3 }
end
