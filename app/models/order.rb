class Order < ApplicationRecord
  belongs_to :user
  belongs_to :payment, optional: true  # Optionnel pour l'instant, sera requis avec HelloAsso
  has_many :order_items, dependent: :destroy

  # Callbacks pour gérer le stock
  after_update :restore_stock_if_canceled, if: :saved_change_to_status?

  def self.ransackable_attributes(_auth_object = nil)
    %w[id user_id payment_id status total_cents currency created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user payment order_items]
  end

  private

  # Remet les articles en stock si la commande est annulée
  # IMPORTANT : Le stock est géré uniquement au niveau des variantes (ProductVariant),
  # pas au niveau du produit (Product)
  def restore_stock_if_canceled
    # Vérifier si le statut vient de passer à "cancelled"
    previous_status = attribute_was(:status) || status_before_last_save
    current_status = status
    
    # Si le statut est passé à "cancelled" et qu'il était différent avant
    if current_status == 'cancelled' && 
       previous_status != 'cancelled' &&
       previous_status.present?
      
      order_items.includes(:variant).each do |item|
        variant = item.variant
        next unless variant

        # Remettre la quantité en stock de la variante uniquement
        # Le stock est géré uniquement au niveau des variantes
        variant.increment!(:stock_qty, item.quantity)
      end
    end
  end
end

# chaque commande (Order) appartient à un utilisateur (User).
# chaque commande est liée à un paiement précis
# chaque commande contient plusieurs articles de commande