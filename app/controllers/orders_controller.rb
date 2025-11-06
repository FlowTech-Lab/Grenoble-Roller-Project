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

    # Vérifier le stock avant de créer la commande
    stock_errors = []
    cart_items.each do |ci|
      variant = ci[:variant]
      requested_qty = ci[:quantity]
      available_stock = variant.stock_qty.to_i
      
      if !variant.is_active || !variant.product&.is_active
        stock_errors << "#{variant.product.name} (#{variant.sku}) n'est plus disponible"
      elsif available_stock < requested_qty
        stock_errors << "#{variant.product.name} (#{variant.sku}) : stock insuffisant (#{requested_qty} demandé, #{available_stock} disponible)"
      end
    end

    if stock_errors.any?
      return redirect_to cart_path, alert: "Stock insuffisant : #{stock_errors.join('; ')}"
    end

    total_cents = cart_items.sum { |ci| ci[:subtotal_cents] }

    # Transaction pour garantir la cohérence
    Order.transaction do
      order = Order.create!(
        user: current_user,
        status: 'pending',
        total_cents: total_cents,
        currency: 'EUR'
      )

      cart_items.each do |ci|
        variant = ci[:variant]
        OrderItem.create!(
          order: order,
          variant_id: variant.id,
          quantity: ci[:quantity],
          unit_price_cents: ci[:unit_price_cents]
        )
        
        # Déduire le stock
        variant.decrement!(:stock_qty, ci[:quantity])
      end

      session[:cart] = {}
      redirect_to order_path(order), notice: 'Commande créée avec succès.'
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to cart_path, alert: "Erreur lors de la création de la commande: #{e.message}"
  rescue => e
    redirect_to cart_path, alert: "Erreur : #{e.message}"
  end

  def show
    @order = current_user.orders.includes(order_items: { variant: :product }).find(params[:id])
  end

  def cancel
    @order = current_user.orders.includes(order_items: :variant).find(params[:id])
    
    # Vérifier que la commande peut être annulée
    unless ['pending', 'en attente', 'preparation', 'en préparation', 'preparing'].include?(@order.status.downcase)
      redirect_to order_path(@order), alert: 'Cette commande ne peut pas être annulée.'
      return
    end

    # Transaction pour garantir la cohérence
    Order.transaction do
      # Restaurer le stock
      @order.order_items.each do |item|
        variant = item.variant
        if variant
          variant.increment!(:stock_qty, item.quantity)
        end
      end

      # Mettre à jour le statut
      @order.update!(status: 'cancelled')
    end
    
    redirect_to order_path(@order), notice: 'Commande annulée avec succès. Le stock a été restauré.'
  rescue => e
    redirect_to order_path(@order), alert: "Erreur lors de l'annulation : #{e.message}"
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


