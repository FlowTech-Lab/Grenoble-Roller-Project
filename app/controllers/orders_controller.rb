class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_email_confirmed, only: [ :create ] # Exiger confirmation pour passer une commande

  def index
    @orders = current_user.orders.includes(:payment, order_items: { variant: :product }).order(created_at: :desc)
  end

  def new
    @cart_items = build_cart_items
    redirect_to cart_path, alert: "Votre panier est vide." and return if @cart_items.empty?
    @total_cents = @cart_items.sum { |ci| ci[:subtotal_cents] }
  end

  def create
    cart_items = build_cart_items
    return redirect_to cart_path, alert: "Votre panier est vide." if cart_items.empty?

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

    # Récupérer le don (en centimes) depuis les params
    donation_cents = params[:donation_cents].to_i
    donation_cents = 0 if donation_cents < 0 # Sécurité : pas de don négatif

    # Le total de la commande inclut le don
    order_total_cents = total_cents + donation_cents

    # Transaction pour garantir la cohérence des données locales (order + stock)
    order = Order.transaction do
      order = Order.create!(
        user: current_user,
        status: "pending",
        total_cents: order_total_cents, # Total inclut le don
        donation_cents: donation_cents, # Stocker le don séparément
        currency: "EUR"
      )

      # Envoyer l'email de confirmation de commande (après création)
      OrderMailer.order_confirmation(order).deliver_later

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
      order
    end

    # Vider le panier local une fois la commande créée
    session[:cart] = {}

    # Initialiser un checkout HelloAsso avec le don
    checkout_result = HelloassoService.create_checkout_intent(
      order,
      donation_cents: donation_cents,
      back_url: shop_url,
      error_url: order_url(order),
      return_url: order_url(order)
    )

    if checkout_result[:success]
      body = checkout_result[:body] || {}

      payment = Payment.create!(
        provider: "helloasso",
        provider_payment_id: body["id"].to_s,
        amount_cents: order_total_cents, # Montant total inclut le don
        currency: "EUR",
        status: "pending",
        created_at: Time.current
      )

      order.update!(payment: payment)

      redirect_url = body["redirectUrl"]

      if redirect_url.present?
        # URL externe (HelloAsso sandbox/production) → autoriser l'hôte externe explicitement
        redirect_to redirect_url, allow_other_host: true
      else
        redirect_to order_path(order), notice: "Commande créée avec succès (paiement HelloAsso initialisé)."
      end
    else
      # Fallback : si HelloAsso ne renvoie pas d'URL ou renvoie une erreur,
      # on garde la commande en pending et on affiche un message.
      redirect_to order_path(order), alert: "Commande créée mais paiement HelloAsso non initialisé (code #{checkout_result[:status]})."
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to cart_path, alert: "Erreur lors de la création de la commande: #{e.message}"
  rescue => e
    redirect_to cart_path, alert: "Erreur : #{e.message}"
  end

  def show
    @order = current_user.orders.includes(:payment, order_items: { variant: :product }).find(params[:id])
  end

  def check_payment
    @order = current_user.orders.includes(:payment).find(params[:id])

    if @order.payment&.provider == "helloasso"
      HelloassoService.fetch_and_update_payment(@order.payment)
      @order.reload
      redirect_to order_path(@order), notice: "✅ Vérification du paiement effectuée"
    else
      redirect_to order_path(@order), alert: "Aucun paiement associé à cette commande."
    end
  end

  def payment_status
    @order = current_user.orders.includes(:payment).find(params[:id])

    # Si pas de payment mais commande pending → considérer comme pending
    if @order.payment.nil?
      order_status = @order.status.downcase
      if [ "pending", "en attente" ].include?(order_status)
        render json: { status: "pending" }
        return
      else
        render json: { status: "unknown" }
        return
      end
    end

    # Si le paiement est pending et HelloAsso, faire un check réel
    if @order.payment.provider == "helloasso" && @order.payment.status == "pending"
      HelloassoService.fetch_and_update_payment(@order.payment)
      @order.reload
      @order.payment.reload
    end

    render json: { status: @order.payment.status || "unknown" }
  end

  def pay
    @order = current_user.orders.includes(:payment, order_items: :variant).find(params[:id])

    payment = @order.payment

    # CHECK OBLIGATOIRE : Vérifier le statut réel avec HelloAsso AVANT de créer un nouveau checkout-intent
    if payment&.provider == "helloasso" && payment.status == "pending"
      HelloassoService.fetch_and_update_payment(payment)
      @order.reload
      payment.reload
    end

    # Vérifier les conditions APRÈS le check
    order_status = @order.status&.downcase
    is_cancelled = [ "cancelled", "annulé", "canceled" ].include?(order_status)
    is_pending = order_status == "pending"

    # Permettre le paiement si : commande pending + non annulée + (pas de payment OU payment pending helloasso)
    can_pay = is_pending &&
              !is_cancelled &&
              (payment.nil? || (payment.provider == "helloasso" && payment.status == "pending"))

    unless can_pay
      # Si déjà payé, annulé ou autre statut, rediriger vers la liste des commandes à jour
      message = if is_cancelled
        "Cette commande est annulée et ne peut plus être payée."
      else
        "Le statut de cette commande a été mis à jour. " \
        "Statut actuel : #{@order.status} / #{payment&.status || 'pas de paiement'}"
      end
      redirect_to orders_path, notice: message
      return
    end

    # Créer un nouveau checkout-intent (plus fiable que de réutiliser l'ancien qui peut expirer)
    # Utiliser le don stocké dans l'order
    begin
      checkout_result = HelloassoService.create_checkout_intent(
        @order,
        donation_cents: @order.donation_cents || 0,
        back_url: orders_url,
        error_url: order_url(@order),
        return_url: order_url(@order)
      )
    rescue => e
      Rails.logger.error("[OrdersController#pay] Erreur lors de la création du checkout-intent : #{e.class} - #{e.message}")

      # Message d'erreur adapté selon le type d'erreur
      error_message = if e.message.include?("429") || e.message.include?("Rate limit")
        "Les serveurs HelloAsso sont temporairement surchargés. " \
        "Merci de réessayer dans quelques minutes."
      elsif e.message.include?("access_token")
        "Erreur de configuration HelloAsso. " \
        "Merci de contacter l'association."
      else
        "Erreur lors de l'initialisation du paiement HelloAsso. " \
        "Merci de réessayer plus tard ou de contacter l'association."
      end

      redirect_to order_path(@order), alert: error_message
      return
    end

    if checkout_result[:success]
      body = checkout_result[:body] || {}
      redirect_url = body["redirectUrl"]

      # Créer ou mettre à jour le payment avec le nouveau checkout-intent ID
      if body["id"].present?
        if payment.nil?
          # Créer un nouveau payment si il n'existe pas
          payment = Payment.create!(
            provider: "helloasso",
            provider_payment_id: body["id"].to_s,
            amount_cents: @order.total_cents,
            currency: "EUR",
            status: "pending",
            created_at: Time.current
          )
          @order.update!(payment: payment)
        else
          # Mettre à jour le payment existant avec le nouveau checkout-intent ID
          payment.update!(
            provider_payment_id: body["id"].to_s
          )
        end
      end

      if redirect_url.present?
        redirect_to redirect_url, allow_other_host: true
      else
        redirect_to order_path(@order),
                    alert: "Impossible de récupérer l'URL de paiement HelloAsso. " \
                           "Merci de réessayer plus tard ou de contacter l'association."
      end
    else
      redirect_to order_path(@order),
                  alert: "Erreur lors de l'initialisation du paiement HelloAsso. " \
                         "Merci de réessayer plus tard ou de contacter l'association."
    end
  end

  def cancel
    @order = current_user.orders.includes(:payment, order_items: :variant).find(params[:id])

    # CHECK OBLIGATOIRE : Si la commande est payée via HelloAsso, vérifier le statut réel
    if @order.payment&.provider == "helloasso" && @order.payment.status != "pending"
      HelloassoService.fetch_and_update_payment(@order.payment)
      @order.reload
    end

    # Vérifier que la commande peut être annulée
    unless [ "pending", "en attente", "preparation", "en préparation", "preparing" ].include?(@order.status.downcase)
      if @order.status.downcase == "paid" || @order.status.downcase == "payé"
        redirect_to order_path(@order),
                    alert: "Cette commande est déjà payée. " \
                           "Pour un remboursement, veuillez contacter l'association. " \
                           "Le remboursement sera effectué manuellement."
      else
        redirect_to order_path(@order), alert: "Cette commande ne peut pas être annulée."
      end
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
      @order.update!(status: "cancelled")
    end

    redirect_to order_path(@order), notice: "Commande annulée avec succès."
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
