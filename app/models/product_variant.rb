class ProductVariant < ApplicationRecord
  belongs_to :product
  has_many :variant_option_values, foreign_key: :variant_id, dependent: :destroy
  has_many :option_values, through: :variant_option_values

  # Active Storage attachments - Images multiples
  has_many_attached :images

  # Relation avec inventaire
  has_one :inventory, dependent: :destroy

  # VALIDATIONS
  validates :sku, presence: true, uniqueness: true,
            format: { with: /\A[A-Z0-9-]+\z/, message: 'format invalide' }
  validates :price_cents, numericality: { greater_than: 0 }
  validates :stock_qty, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, length: { is: 3 }
  validate :image_present
  validate :has_required_option_values

  # NOUVEAU : Héritage prix/stock
  attr_accessor :inherit_price, :inherit_stock

  before_save :apply_inheritance
  after_create :create_inventory_record

  # SCOPES
  scope :active, -> { where(is_active: true) }
  scope :by_sku, ->(sku) { where(sku: sku) }
  scope :by_option, ->(option_value_id) {
    joins(:variant_option_values)
      .where(variant_option_values: { option_value_id: option_value_id })
  }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id product_id sku price_cents currency stock_qty is_active created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[product option_values]
  end

  private

  def has_required_option_values
    # Si le produit a plusieurs variantes, celle-ci doit avoir des options
    return if variant_option_values.any? || product.product_variants.count <= 1
    errors.add(:base, 'Les variantes doivent avoir des options de catégorisation')
  end

  def apply_inheritance
    self.price_cents = product.price_cents if inherit_price.present?
    self.stock_qty = 0 if inherit_stock.present?
  end

  def image_present
    return if images.attached?
    errors.add(:base, "Une image (upload fichier) est requise")
  end

  def create_inventory_record
    Inventory.create!(
      product_variant: self,
      stock_qty: stock_qty || 0,
      reserved_qty: 0
    )
  end
end
