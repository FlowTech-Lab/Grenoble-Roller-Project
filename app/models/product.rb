class Product < ApplicationRecord
  include Hashid::Rails
  
  belongs_to :category, class_name: "ProductCategory"
  has_many :product_variants, dependent: :destroy

  # Active Storage attachments
  has_one_attached :image

  # Validation: image_url OU image attaché (pour transition)
  validates :name, :slug, :price_cents, :currency, presence: true
  validate :image_or_image_url_present
  validates :name, length: { maximum: 140 }
  validates :slug, length: { maximum: 160 }, uniqueness: true
  validates :currency, length: { is: 3 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id category_id name slug description price_cents currency stock_qty is_active image_url created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[category product_variants]
  end

  private

  def image_or_image_url_present
    return if image.attached? || image_url.present?
    errors.add(:base, "Une image (upload ou URL) est requise")
  end
end
