# frozen_string_literal: true

module AdminPanel
  module ProductsHelper
    # Badge pour le stock (accepte variant ou nombre)
    def stock_badge(stock_qty)
      qty = stock_qty.is_a?(Numeric) ? stock_qty.to_i : stock_qty.stock_qty.to_i
      if qty <= 0
        content_tag(:span, "Rupture", class: "badge bg-danger")
      elsif qty < 5
        content_tag(:span, "Faible (#{qty})", class: "badge bg-warning")
      else
        content_tag(:span, "OK (#{qty})", class: "badge bg-success")
      end
    end

    # Affichage du prix formaté
    def price_display(cents, currency = "EUR")
      number_to_currency(cents / 100.0, unit: currency == "EUR" ? "€" : currency, separator: ",", delimiter: " ")
    end

    # Badge pour le statut actif/inactif (accepte product ou boolean)
    def active_badge(is_active)
      active = is_active.is_a?(TrueClass) || is_active.is_a?(FalseClass) ? is_active : is_active.is_active?
      if active
        content_tag(:span, "Actif", class: "badge bg-success")
      else
        content_tag(:span, "Inactif", class: "badge bg-secondary")
      end
    end
  end
end
