# frozen_string_literal: true

module AdminPanel
  module OrdersHelper
    # Badge pour le statut de la commande
    def status_badge(order)
      case order.status
      when "pending"
        content_tag(:span, "En attente", class: "badge bg-warning")
      when "paid"
        content_tag(:span, "Payée", class: "badge bg-info")
      when "preparation"
        content_tag(:span, "En préparation", class: "badge bg-primary")
      when "shipped"
        content_tag(:span, "Expédiée", class: "badge bg-success")
      when "cancelled", "canceled"
        content_tag(:span, "Annulée", class: "badge bg-danger")
      when "refund_requested"
        content_tag(:span, "Remboursement demandé", class: "badge bg-warning")
      when "refunded"
        content_tag(:span, "Remboursée", class: "badge bg-secondary")
      when "failed"
        content_tag(:span, "Échouée", class: "badge bg-danger")
      else
        content_tag(:span, order.status.humanize, class: "badge bg-secondary")
      end
    end

    # Affichage du montant total formaté
    def total_display(order)
      number_to_currency(order.total_cents / 100.0, unit: order.currency == "EUR" ? "€" : order.currency, separator: ",", delimiter: " ")
    end
  end
end
