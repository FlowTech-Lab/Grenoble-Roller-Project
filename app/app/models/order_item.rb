class OrderItem < ApplicationRecord
  belongs_to :order
end

# ça dit qu’un OrderItem appartient à une seule commande
# la table order_items a une colonne order_id