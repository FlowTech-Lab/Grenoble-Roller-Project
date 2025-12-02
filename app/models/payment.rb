class Payment < ApplicationRecord
  has_many :orders, dependent: :nullify
  has_many :attendances, dependent: :nullify
  has_one :membership, dependent: :nullify # Pour adhésions personnelles (1 paiement = 1 adhésion)
  has_many :memberships, dependent: :nullify # Pour adhésions enfants groupées (1 paiement = plusieurs adhésions)

  # Paiements HelloAsso en attente récents (24h) – utilisés pour le polling
  scope :pending_helloasso, lambda {
    where(provider: "helloasso", status: "pending")
      .where("created_at > ?", 24.hours.ago)
  }

  # Polling simplifié des paiements HelloAsso en attente
  def self.check_and_update_helloasso_orders
    pending_helloasso.find_each do |payment|
      HelloassoService.fetch_and_update_payment(payment)
    rescue StandardError => e
      Rails.logger.error(
        "[Payment] Polling HelloAsso failed for payment ##{payment.id}: " \
        "#{e.class} - #{e.message}"
      )
    end
  end
end

# Un paiement peut être associé à plusieurs commandes et attendances
# Toutes les orders/attendances qui avaient ce payment_id verront leur payment_id remis à nil
# Ça évite l'erreur FK (foreign key) tout en préservant les commandes/attendances (tu ne veux pas les effacer juste parce que le paiement a disparu).
