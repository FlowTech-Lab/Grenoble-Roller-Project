class Order < ApplicationRecord
  belongs_to :user
  belongs_to :payment
  has_many :order_items, dependent: :destroy
end

# chaque commande (Order) appartient à un utilisateur (User).
# chaque commande est liée à un paiement précis
# chaque commande contient plusieurs articles de commande