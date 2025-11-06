class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :variant, class_name: "ProductVariant", foreign_key: :variant_id
end

# ça dit qu’un OrderItem appartient à une seule commande
# la table order_items a une colonne order_id