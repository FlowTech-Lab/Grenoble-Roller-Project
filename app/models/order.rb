class Order < ApplicationRecord
  belongs_to :user
  belongs_to :payment, optional: true  # Optionnel pour l'instant, sera requis avec HelloAsso
  has_many :order_items, dependent: :destroy

  def self.ransackable_attributes(_auth_object = nil)
    %w[id user_id payment_id status total_cents currency created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user payment order_items]
  end
end

# chaque commande (Order) appartient à un utilisateur (User).
# chaque commande est liée à un paiement précis
# chaque commande contient plusieurs articles de commande