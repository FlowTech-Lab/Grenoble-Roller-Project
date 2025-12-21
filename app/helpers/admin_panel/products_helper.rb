# frozen_string_literal: true

module AdminPanel
  module ProductsHelper
    # Badge pour le stock
    def stock_badge(variant)
      if variant.stock_qty.to_i <= 0
        content_tag(:span, "Rupture", class: "badge bg-danger")
      elsif variant.stock_qty.to_i < 5
        content_tag(:span, "Faible", class: "badge bg-warning")
      else
        content_tag(:span, "OK", class: "badge bg-success")
      end
    end

    # Affichage du prix formaté
    def price_display(cents, currency = "EUR")
      number_to_currency(cents / 100.0, unit: currency == "EUR" ? "€" : currency, separator: ",", delimiter: " ")
    end

    # Badge pour le statut actif/inactif
    def active_badge(product)
      if product.is_active?
        content_tag(:span, "Actif", class: "badge bg-success")
      else
        content_tag(:span, "Inactif", class: "badge bg-secondary")
      end
    end
  end
end
