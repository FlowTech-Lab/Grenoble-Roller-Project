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

    session[:cart][variant_id] = (session[:cart][variant_id] || 0) + quantity
    redirect_to cart_path, notice: 'Item added to cart.'
  end

  def update_item
    variant_id = params.require(:variant_id).to_i
    quantity = params.require(:quantity).to_i

    if quantity <= 0
      session[:cart].delete(variant_id)
    else
      session[:cart][variant_id] = quantity
    end
    redirect_to cart_path, notice: 'Cart updated.'
  end

  def remove_item
    variant_id = params.require(:variant_id).to_i
    session[:cart].delete(variant_id)
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


