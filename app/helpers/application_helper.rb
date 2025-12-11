module ApplicationHelper
  def cart_items_count
    return 0 unless session[:cart]
    session[:cart].values.sum(&:to_i)
  end

  def format_price(amount_cents)
    amount = amount_cents / 100.0
    # Formater sans décimales si c'est un nombre entier
    formatted = amount == amount.to_i ? amount.to_i.to_s : sprintf("%.2f", amount)
    formatted.gsub(".", ",") + "€"
  end

  # Formater le prix d'un événement selon les règles françaises
  # - Si 0.00 → "Gratuit"
  # - Sinon : montant sans décimales si .00, avec "euros" après
  # - Format : "15 euros" ou "15,50 euros" (pas de "EUR" avant)
  def format_event_price(price_cents)
    return "Gratuit" if price_cents.nil? || price_cents == 0
    
    amount = price_cents / 100.0
    
    # Formater sans décimales si c'est un nombre entier
    if amount == amount.to_i
      "#{amount.to_i} euros"
    else
      # Formater avec 2 décimales et remplacer le point par une virgule
      formatted = sprintf("%.2f", amount).gsub(".", ",")
      # Enlever les zéros inutiles à la fin (ex: "15,50" → "15,5" si on veut, mais on garde 2 décimales pour cohérence)
      "#{formatted} euros"
    end
  end
end
