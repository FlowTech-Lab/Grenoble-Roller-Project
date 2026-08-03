# frozen_string_literal: true

class CheckoutsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_checkout, only: [ :show, :status, :check_payment ]
  before_action :ensure_email_confirmed, only: [ :create ]

  # GET /checkout
  def new
    @cart_lines = CartLineService.list(current_user, include_expired: true)
    redirect_to cart_path, alert: "Votre panier est vide." and return if @cart_lines.empty?

    @subtotal_cents = @cart_lines.sum(&:subtotal_cents)
  end

  # POST /checkout
  def create
    cart_line_ids = Array(params[:cart_line_ids]).reject(&:blank?)
    donation_cents = params[:donation_cents].to_i
    donation_cents = 0 if donation_cents.negative?

    unless params[:accept_terms].present? && params[:accept_terms] == "1"
      redirect_to new_checkout_path, alert: "Vous devez accepter les conditions générales." and return
    end

    checkout = CheckoutService.build_from_cart(
      current_user,
      cart_line_ids: cart_line_ids,
      donation_cents: donation_cents
    )

    checkout_result = HelloassoService.create_unified_checkout_intent(
      checkout,
      back_url: cart_url,
      error_url: checkout_url(checkout),
      return_url: checkout_url(checkout)
    )

    unless checkout_result[:success]
      redirect_to new_checkout_path,
                  alert: "Erreur lors de l'initialisation du paiement HelloAsso (code #{checkout_result[:status]})."
      return
    end

    body = checkout_result[:body] || {}
    redirect_url = body["redirectUrl"]

    payment = Payment.create!(
      provider: "helloasso",
      provider_payment_id: body["id"].to_s,
      amount_cents: checkout.total_cents,
      currency: "EUR",
      status: "pending",
      created_at: Time.current
    )

    checkout.update!(payment: payment)

    if redirect_url.present?
      redirect_to redirect_url, allow_other_host: true
    else
      redirect_to checkout_path(checkout), notice: "Paiement HelloAsso initialisé."
    end
  rescue CheckoutService::EmptySelectionError
    redirect_to new_checkout_path, alert: "Sélectionnez au moins une ligne à payer."
  rescue CheckoutService::ExpiredLinesError => e
    redirect_to new_checkout_path, alert: "Certaines lignes ont expiré : #{e.message}"
  rescue CheckoutService::InsufficientStockError => e
    redirect_to new_checkout_path, alert: "Stock insuffisant pour : #{e.message}"
  rescue CheckoutService::ForbiddenError
    redirect_to cart_path, alert: "Sélection de panier invalide."
  rescue CheckoutService::InvalidLineError => e
    redirect_to new_checkout_path, alert: e.message
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_checkout_path, alert: "Erreur lors de la préparation du paiement : #{e.message}"
  end

  # GET /checkout/:id (return from HelloAsso)
  def show
    if @checkout.payment&.provider == "helloasso" && @checkout.payment.status == "pending"
      HelloassoService.fetch_and_update_payment(@checkout.payment)
      @checkout.reload
    end
  end

  # GET /checkout/:id/status
  def status
    if @checkout.payment&.provider == "helloasso"
      HelloassoService.fetch_and_update_payment(@checkout.payment)
      @checkout.reload
    end

    render json: { status: @checkout.status }
  rescue StandardError => e
    Rails.logger.error("[CheckoutsController#status] #{e.message}")
    render json: { status: "unknown" }, status: :internal_server_error
  end

  # POST /checkout/:id/check_payment
  def check_payment
    if @checkout.payment&.provider == "helloasso"
      HelloassoService.fetch_and_update_payment(@checkout.payment)
      @checkout.reload
      redirect_to checkout_path(@checkout), notice: "Vérification du paiement effectuée."
    else
      redirect_to checkout_path(@checkout), alert: "Aucun paiement associé à ce checkout."
    end
  end

  private

  def set_checkout
    @checkout = current_user.checkouts.includes(checkout_lines: :reference).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to cart_path, alert: "Checkout introuvable."
  end

  def ensure_email_confirmed
    user = User.find(current_user.id)
    return if user.confirmed_at.present?

    confirmation_link = view_context.link_to(
      "demandez un nouvel email de confirmation",
      new_user_confirmation_path,
      class: "alert-link"
    )
    redirect_to root_path,
                alert: "Vous devez confirmer votre adresse email pour effectuer cette action. " \
                       "Vérifiez votre boîte mail ou #{confirmation_link}".html_safe and return
  end
end
