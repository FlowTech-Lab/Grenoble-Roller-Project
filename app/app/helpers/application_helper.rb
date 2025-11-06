module ApplicationHelper
  def cart_items_count
    return 0 unless session[:cart]
    session[:cart].values.sum(&:to_i)
  end
end
