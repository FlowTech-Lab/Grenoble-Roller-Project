class OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    @orders = current_user.orders.includes(order_items: { variant: :product }).order(created_at: :desc)
  end

  def new
    @cart_items = build_cart_items
    redirect_to cart_path, alert: 'Votre panier est vide.' and return if @cart_items.empty?
    @total_cents = @cart_items.sum { |ci| ci[:subtotal_cents] }
  end

  def create
    cart_items = build_cart_items
    return redirect_to cart_path, alert: 'Votre panier est vide.' if cart_items.empty?

    total_cents = cart_items.sum { |ci| ci[:subtotal_cents] }

    order = Order.create!(
      user: current_user,
      status: 'pending',
      total_cents: total_cents,
      currency: 'EUR'
    )

    cart_items.each do |ci|
      OrderItem.create!(
        order: order,
        variant_id: ci[:variant].id,
        quantity: ci[:quantity],
        unit_price_cents: ci[:unit_price_cents]
      )
    end

    session[:cart] = {}
    redirect_to order_path(order), notice: 'Commande créée avec succès.'
  rescue ActiveRecord::RecordInvalid => e
    redirect_to cart_path, alert: "Erreur lors de la création de la commande: #{e.message}"
  end

  def show
    @order = current_user.orders.includes(order_items: { variant: :product }).find(params[:id])
  end

  private

  def build_cart_items
    session[:cart] ||= {}
    variant_ids = session[:cart].keys
    return [] if variant_ids.empty?
    variants = ProductVariant.where(id: variant_ids).includes(:product).index_by { |v| v.id.to_s }
    session[:cart].map do |vid, qty|
      variant = variants[vid]
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


