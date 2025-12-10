class Order < ApplicationRecord
  belongs_to :user
  belongs_to :payment, optional: true  # Optionnel pour l'instant, sera requis avec HelloAsso
  has_many :order_items, dependent: :destroy

  # Statuts possibles pour les commandes
  # pending: En attente de paiement
  # paid: Payée
  # preparation: En préparation
  # shipped: Expédiée
  # cancelled: Annulée
  # refund_requested: Demande de remboursement en cours
  # refunded: Remboursée
  # failed: Échouée (paiement refusé)

  # Callbacks pour gérer le stock et les notifications
  after_update :restore_stock_if_canceled, if: :saved_change_to_status?
  after_update :notify_status_change, if: :saved_change_to_status?

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
    if current_status == "cancelled" &&
       previous_status != "cancelled" &&
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

  # Envoie un email de notification lors d'un changement de statut
  def notify_status_change
    previous_status = attribute_was(:status) || status_before_last_save
    current_status = status

    # Ne pas envoyer d'email si c'est la création initiale (pas de previous_status)
    return unless previous_status.present? && previous_status != current_status

    case current_status
    when "paid", "payé"
      OrderMailer.order_paid(self).deliver_later
    when "cancelled", "annulé"
      OrderMailer.order_cancelled(self).deliver_later
    when "preparation", "en préparation", "preparing"
      OrderMailer.order_preparation(self).deliver_later
    when "shipped", "envoyé", "expédié"
      OrderMailer.order_shipped(self).deliver_later
    when "refund_requested", "remboursement_demandé"
      OrderMailer.refund_requested(self).deliver_later
    when "refunded", "remboursé"
      OrderMailer.refund_confirmed(self).deliver_later
    end
  end
end

# chaque commande (Order) appartient à un utilisateur (User).
# chaque commande est liée à un paiement précis
# chaque commande contient plusieurs articles de commande
