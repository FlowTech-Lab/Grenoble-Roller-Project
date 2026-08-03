class CartsController < ApplicationController
  before_action :authenticate_user!

  def show
    CartLineService.refresh_membership_lines!(current_user)
    @cart_lines = CartLineService.list(current_user)
    @cart_items = build_cart_items_from_lines(@cart_lines)
    @event_cart_lines = CartLineService.event_lines(current_user)
    @membership_cart_lines = @cart_lines.select(&:membership?)
    @total_cents = CartLineService.total_cents(current_user)
  end

  def add_item
    variant_id = params.require(:variant_id).to_i
    quantity = params[:quantity].to_i
    quantity = 1 if quantity <= 0

    variant = ProductVariant.includes(:product, :inventory).find_by(id: variant_id)
    unless variant && variant.is_active && variant.product&.is_active
      return redirect_to shop_path, alert: "Cette variante n'est pas disponible."
    end

    add_item_to_db_cart(variant, quantity)
  end

  def update_item
    update_db_cart_item
  end

  def remove_item
    remove_db_cart_item
  end

  def clear
    CartLineService.clear!(current_user)
    flash[:notice] = "Panier vidé"
    flash[:notice_type] = "info"
    redirect_to cart_path
  end

  private

  def add_item_to_db_cart(variant, quantity)
    available_stock = CartLineService.available_stock_for(variant)
    if available_stock <= 0
      return redirect_to shop_path, alert: "Article en rupture de stock."
    end

    existing_line = CartLine.find_by(user: current_user, line_type: :product_variant, reference: variant)
    current_qty = existing_line&.quantity.to_i
    requested_total = current_qty + quantity

    line = CartLineService.add_product!(user: current_user, variant: variant, quantity: quantity)
    capped_qty = line.quantity

    if capped_qty == current_qty
      redirect_to shop_path, alert: "Stock insuffisant pour ajouter plus d'unités."
    else
      product_name = variant.product.name
      added_qty = capped_qty - current_qty

      if requested_total > available_stock
        flash[:alert] = "Stock insuffisant. Seulement #{added_qty} unité#{added_qty > 1 ? 's' : ''} ajoutée#{added_qty > 1 ? 's' : ''} au panier."
      end

      message = if added_qty == 1
        "#{product_name} ajouté au panier"
      else
        "#{added_qty}x #{product_name} ajoutés au panier"
      end
      flash[:notice] = message
      flash[:notice_type] = "success"
      flash[:show_cart_button] = true
      redirect_to shop_path
    end
  rescue CartLineService::InactiveVariantError
    redirect_to shop_path, alert: "Cette variante n'est pas disponible."
  end

  def update_db_cart_item
    if params[:cart_line_id].present?
      line = CartLine.find_by(id: params[:cart_line_id], user: current_user)
      variant = line&.reference if line&.product_variant?
    else
      variant_id = params.require(:variant_id).to_i
      variant = ProductVariant.includes(:product, :inventory).find_by(id: variant_id)
    end

    quantity = params.require(:quantity).to_i

    unless variant
      flash[:notice] = "Article retiré du panier"
      flash[:notice_type] = "info"
      return redirect_to cart_path
    end

    if quantity <= 0
      line = CartLine.find_by(user: current_user, line_type: :product_variant, reference: variant)
      line&.destroy!
      product_name = variant.product&.name || "Article"
      flash[:notice] = "#{product_name} retiré du panier"
      flash[:notice_type] = "info"
      return redirect_to cart_path
    end

    unless variant.is_active && variant.product&.is_active
      CartLine.where(user: current_user, line_type: :product_variant, reference: variant).delete_all
      return redirect_to cart_path, alert: "Cette variante n'est plus disponible et a été retirée."
    end

    max_qty = CartLineService.available_stock_for(variant)
    if max_qty <= 0
      CartLine.where(user: current_user, line_type: :product_variant, reference: variant).delete_all
      return redirect_to cart_path, alert: "Article en rupture, retiré du panier."
    end

    line = CartLineService.update_product_quantity!(current_user, variant: variant, quantity: quantity)
    new_qty = line&.quantity || 0

    if new_qty < quantity
      redirect_to cart_path, alert: "Quantité ajustée au stock disponible (#{new_qty})."
    else
      flash[:notice] = "Panier mis à jour"
      flash[:notice_type] = "info"
      redirect_to cart_path
    end
  rescue CartLineService::InactiveVariantError
    redirect_to cart_path, alert: "Cette variante n'est plus disponible et a été retirée."
  end

  def remove_db_cart_item
    if params[:cart_line_id].present?
      line = CartLine.includes(reference: :product).find_by(id: params[:cart_line_id], user: current_user)
      product_name = line&.label || "Article"
      CartLineService.remove!(current_user, cart_line_id: params[:cart_line_id]) if line
    else
      variant_id = params.require(:variant_id).to_i
      variant = ProductVariant.includes(:product).find_by(id: variant_id)
      product_name = variant&.product&.name || "Article"
      line = CartLine.find_by(user: current_user, line_type: :product_variant, reference: variant)
      line&.destroy!
    end

    flash[:notice] = "#{product_name} retiré du panier"
    flash[:notice_type] = "info"
    redirect_to cart_path
  rescue CartLineService::NotFoundError, CartLineService::UnauthorizedError
    redirect_to cart_path, alert: "Article introuvable dans le panier."
  end

  def build_cart_items_from_lines(cart_lines)
    cart_lines.filter_map do |line|
      next unless line.product_variant?

      variant = line.reference
      next unless variant

      {
        cart_line: line,
        variant: variant,
        product: variant.product,
        quantity: line.quantity,
        unit_price_cents: line.amount_cents,
        subtotal_cents: line.subtotal_cents
      }
    end
  end
end
