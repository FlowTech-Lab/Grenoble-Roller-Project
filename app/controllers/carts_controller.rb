class CartsController < ApplicationController
  before_action :ensure_cart

  def show
    @cart_items = build_cart_items
    @total_cents = @cart_items.sum { |ci| ci[:subtotal_cents] }
  end

  def add_item
    variant_id = params.require(:variant_id).to_i
    quantity = params[:quantity].to_i
    quantity = 1 if quantity <= 0

    variant = ProductVariant.includes(:product).find_by(id: variant_id)
    unless variant && variant.is_active && variant.product&.is_active
      return redirect_to cart_path, alert: 'Cette variante n’est pas disponible.'
    end
    if variant.stock_qty.to_i <= 0
      return redirect_to cart_path, alert: 'Article en rupture de stock.'
    end

    key = variant_id.to_s
    current_qty = (session[:cart][key] || 0).to_i
    capped_qty = [current_qty + quantity, variant.stock_qty.to_i].min
    session[:cart][key] = capped_qty

    if capped_qty == current_qty
      redirect_to cart_path, alert: "Stock insuffisant pour ajouter plus d’unités."
    else
      redirect_to cart_path, notice: 'Article ajouté au panier.'
    end
  end

  def update_item
    variant_id = params.require(:variant_id).to_i
    quantity = params.require(:quantity).to_i

    key = variant_id.to_s
    if quantity <= 0
      session[:cart].delete(key)
      return redirect_to cart_path, notice: 'Article retiré du panier.'
    end

    variant = ProductVariant.includes(:product).find_by(id: variant_id)
    unless variant && variant.is_active && variant.product&.is_active
      session[:cart].delete(key)
      return redirect_to cart_path, alert: 'Cette variante n’est plus disponible et a été retirée.'
    end

    max_qty = variant.stock_qty.to_i
    if max_qty <= 0
      session[:cart].delete(key)
      return redirect_to cart_path, alert: 'Article en rupture, retiré du panier.'
    end

    new_qty = [quantity, max_qty].min
    session[:cart][key] = new_qty
    if new_qty < quantity
      redirect_to cart_path, alert: "Quantité ajustée au stock disponible (#{new_qty})."
    else
      redirect_to cart_path, notice: 'Panier mis à jour.'
    end
  end

  def remove_item
    variant_id = params.require(:variant_id).to_i
    key = variant_id.to_s
    session[:cart].delete(key)
    redirect_to cart_path, notice: 'Item removed.'
  end

  def clear
    session[:cart] = {}
    redirect_to cart_path, notice: 'Cart cleared.'
  end

  private

  def ensure_cart
    session[:cart] ||= {}
  end

  def build_cart_items
    variant_ids = session[:cart].keys
    return [] if variant_ids.empty?
    variants = ProductVariant.where(id: variant_ids).includes(:product).index_by(&:id)
    session[:cart].map do |vid, qty|
      variant = variants[vid.to_i]
      next nil unless variant
      price_cents = variant.price_cents
      {
        variant: variant,
        product: variant.product,
        quantity: qty.to_i,
        unit_price_cents: price_cents,
        subtotal_cents: price_cents * qty.to_i
      }
    end.compact
  end
end


