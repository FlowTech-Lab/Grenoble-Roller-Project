class ProductCategory < ApplicationRecord
  has_many :products, dependent: :restrict_with_exception, foreign_key: :category_id, inverse_of: :category
  validates :name, :slug, presence: true
  validates :name, length: { maximum: 100 }
  validates :slug, length: { maximum: 120 }, uniqueness: true
end
