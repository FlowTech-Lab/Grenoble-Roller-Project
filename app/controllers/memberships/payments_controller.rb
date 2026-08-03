# frozen_string_literal: true

module Memberships
  class PaymentsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_membership, except: [ :create_multiple ]

    # POST /memberships/:membership_id/payments
    def create
      unless @membership.status == "pending"
        redirect_to membership_path(@membership), notice: "Cette adhésion n'est plus en attente de paiement."
        return
      end

      unless @membership.health_questionnaire_complete?
        redirect_to edit_membership_path(@membership), alert: "Le questionnaire de santé doit être complété avant de procéder au paiement."
        return
      end

      was_in_cart = CartLineService.membership_in_cart?(current_user, @membership)
      wrong_season = !@membership.sale_season_aligned?
      CartLineService.add_membership!(current_user, membership: @membership)
      flash[:notice] = if was_in_cart && wrong_season
        "Adhésion corrigée pour la saison #{@membership.reload.season} et mise à jour dans votre panier."
      elsif was_in_cart
        "Cette adhésion est déjà dans votre panier."
      else
        "Adhésion ajoutée au panier"
      end
      flash[:notice_type] = "success"
      flash[:show_cart_button] = true
      redirect_to cart_path
    end

    # GET /memberships/:membership_id/payments/status (collection)
    # ou GET /payments/:id (shallow) - mais on utilise la collection pour le statut
    def show
      if @membership.payment
        HelloassoService.fetch_and_update_payment(@membership.payment)
        @membership.reload
      end

      status = @membership.status
      status = "pending" if status == "pending" && @membership.payment.nil?

      render json: { status: status }
    rescue => e
      Rails.logger.error("[Memberships::PaymentsController] Erreur lors de la vérification du statut : #{e.message}")
      render json: { status: "unknown" }, status: 500
    end

    # POST /memberships/payments/create_multiple (collection)
    def create_multiple
      membership_ids = params[:membership_ids] || params["membership_ids"] || []
      membership_ids = [ membership_ids ] unless membership_ids.is_a?(Array)
      membership_ids = membership_ids.reject(&:blank?)

      memberships = current_user.memberships.where(
        id: membership_ids,
        is_child_membership: true,
        status: "pending"
      )

      incomplete = memberships.reject(&:health_questionnaire_complete?)
      if incomplete.any?
        names = incomplete.map(&:child_full_name).join(", ")
        redirect_to memberships_path, alert: "Le questionnaire de santé doit être complété pour #{names} avant de procéder au paiement."
        return
      end

      memberships.find_each do |membership|
        next if CartLineService.membership_in_cart?(current_user, membership)

        CartLineService.add_membership!(current_user, membership: membership)
      end

      flash[:notice] = "Adhésions ajoutées au panier"
      flash[:notice_type] = "success"
      flash[:show_cart_button] = true
      redirect_to cart_path
    end

    private

    def set_membership
      @membership = current_user.memberships.find(params[:membership_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to memberships_path, alert: "Adhésion introuvable."
    end
  end
end
