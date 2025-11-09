class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :variant, class_name: "ProductVariant", foreign_key: :variant_id

  def self.ransackable_attributes(_auth_object = nil)
    %w[id order_id variant_id quantity unit_price_cents created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[order variant]
  end
end

# ça dit qu’un OrderItem appartient à une seule commande
# la table order_items a une colonne order_id