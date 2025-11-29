class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_email_confirmed, only: [ :create ]
  before_action :set_membership, only: [ :show, :pay, :payment_status ]

  def index
    @memberships = current_user.memberships.includes(:payment).order(created_at: :desc)
  end

  def new
    # Vérifier si l'utilisateur a déjà une adhésion active pour la saison courante
    current_season = Membership.current_season_name
    existing_membership = current_user.memberships.find_by(season: current_season)
    
    if existing_membership&.active?
      redirect_to membership_path(existing_membership), notice: "Vous avez déjà une adhésion active pour cette saison."
      return
    end

    @season = current_season
    @start_date, @end_date = Membership.current_season_dates
    @categories = {
      adult: { name: "Adulte", price_cents: 5000, description: "Adhésion standard" },
      student: { name: "Étudiant", price_cents: 2500, description: "Sur présentation d'une carte étudiante" },
      family: { name: "Famille", price_cents: 8000, description: "Pour toute la famille" }
    }
  end

  def create
    category = params[:category]
    
    unless Membership.categories.key?(category)
      redirect_to new_membership_path, alert: "Catégorie d'adhésion invalide."
      return
    end

    # Vérifier si l'utilisateur a déjà une adhésion active pour la saison courante
    current_season = Membership.current_season_name
    existing_membership = current_user.memberships.find_by(season: current_season)
    
    if existing_membership&.active?
      redirect_to membership_path(existing_membership), notice: "Vous avez déjà une adhésion active pour cette saison."
      return
    end

    start_date, end_date = Membership.current_season_dates
    amount_cents = Membership.price_for_category(category)

    # Créer l'adhésion en pending
    membership = Membership.create!(
      user: current_user,
      category: category,
      status: :pending,
      start_date: start_date,
      end_date: end_date,
      amount_cents: amount_cents,
      currency: "EUR",
      season: current_season,
      is_minor: current_user.is_minor?
    )

    # Créer le paiement HelloAsso
    redirect_url = HelloassoService.membership_checkout_redirect_url(
      membership,
      back_url: new_membership_url,
      error_url: membership_url(membership),
      return_url: membership_url(membership)
    )

    unless redirect_url
      membership.destroy
      redirect_to new_membership_path, alert: "Erreur lors de l'initialisation du paiement HelloAsso. Veuillez réessayer."
      return
    end

    # Créer le Payment
    payment = Payment.create!(
      provider: "helloasso",
      provider_payment_id: nil, # Sera mis à jour après création du checkout-intent
      status: "pending",
      amount_cents: amount_cents,
      currency: "EUR"
    )

    # Mettre à jour le provider_payment_id avec l'ID du checkout-intent
    # On doit récupérer l'ID depuis la réponse HelloAsso
    result = HelloassoService.create_membership_checkout_intent(
      membership,
      back_url: new_membership_url,
      error_url: membership_url(membership),
      return_url: membership_url(membership)
    )

    if result[:success] && result[:body]["id"]
      payment.update!(provider_payment_id: result[:body]["id"].to_s)
      membership.update!(payment: payment, provider_order_id: result[:body]["id"].to_s)
    end

    redirect_to redirect_url, allow_other_host: true
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la création de l'adhésion : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to new_membership_path, alert: "Erreur lors de la création de l'adhésion : #{e.message}"
  end

  def show
    @membership = @membership || current_user.memberships.find(params[:id])
  end

  def pay
    # Vérifier que l'adhésion est bien pending
    if @membership.status != "pending"
      redirect_to membership_path(@membership), notice: "Cette adhésion n'est plus en attente de paiement."
      return
    end

    # Vérifier le statut réel via HelloAsso
    if @membership.payment
      HelloassoService.fetch_and_update_payment(@membership.payment)
      @membership.reload
      
      if @membership.status != "pending"
        redirect_to membership_path(@membership), notice: "Le statut de votre adhésion a été mis à jour."
        return
      end
    end

    # Créer un nouveau checkout-intent (les anciens peuvent expirer)
    redirect_url = HelloassoService.membership_checkout_redirect_url(
      @membership,
      back_url: membership_url(@membership),
      error_url: membership_url(@membership),
      return_url: membership_url(@membership)
    )

    unless redirect_url
      redirect_to membership_path(@membership), alert: "Erreur lors de l'initialisation du paiement HelloAsso. Veuillez réessayer."
      return
    end

    # Mettre à jour le provider_payment_id si nécessaire
    result = HelloassoService.create_membership_checkout_intent(
      @membership,
      back_url: membership_url(@membership),
      error_url: membership_url(@membership),
      return_url: membership_url(@membership)
    )

    if result[:success] && result[:body]["id"]
      checkout_id = result[:body]["id"].to_s
      if @membership.payment
        @membership.payment.update!(provider_payment_id: checkout_id)
      else
        payment = Payment.create!(
          provider: "helloasso",
          provider_payment_id: checkout_id,
          status: "pending",
          amount_cents: @membership.amount_cents,
          currency: @membership.currency
        )
        @membership.update!(payment: payment, provider_order_id: checkout_id)
      end
    end

    redirect_to redirect_url, allow_other_host: true
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors du paiement : #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    redirect_to membership_path(@membership), alert: "Erreur lors de l'initialisation du paiement : #{e.message}"
  end

  def payment_status
    if @membership.payment
      # Vérifier le statut réel via HelloAsso
      HelloassoService.fetch_and_update_payment(@membership.payment)
      @membership.reload
    end

    status = @membership.status
    status = "pending" if status == "pending" && @membership.payment.nil?

    render json: { status: status }
  rescue => e
    Rails.logger.error("[MembershipsController] Erreur lors de la vérification du statut : #{e.message}")
    render json: { status: "unknown" }, status: 500
  end

  private

  def set_membership
    @membership = current_user.memberships.find(params[:id])
  end
end
