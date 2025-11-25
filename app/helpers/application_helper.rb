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
end
