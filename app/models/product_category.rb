class ProductCategory < ApplicationRecord
  has_many :products, dependent: :restrict_with_exception, foreign_key: :category_id, inverse_of: :category
  validates :name, :slug, presence: true
  validates :name, length: { maximum: 100 }
  validates :slug, length: { maximum: 120 }, uniqueness: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name slug created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[products]
  end
end
