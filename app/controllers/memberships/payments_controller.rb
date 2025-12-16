# frozen_string_literal: true

module Memberships
  class PaymentsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_membership

    # POST /memberships/:membership_id/payments
    def create
      # Vérifier que l'adhésion est bien pending
      if @membership.status != "pending"
        redirect_to membership_path(@membership), notice: "Cette adhésion n'est plus en attente de paiement."
        return
      end

      # Vérifier que le questionnaire de santé est complété
      unless @membership.health_questionnaire_complete?
        redirect_to edit_membership_path(@membership), alert: "Le questionnaire de santé doit être complété avant de procéder au paiement."
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
      result = HelloassoService.create_membership_checkout_intent(
        @membership,
        back_url: membership_url(@membership),
        error_url: membership_url(@membership),
        return_url: membership_url(@membership)
      )

      unless result[:success] && result[:body]["id"]
        Rails.logger.error("[Memberships::PaymentsController] Échec création checkout-intent : #{result.inspect}")
        redirect_to membership_path(@membership), alert: "Erreur lors de l'initialisation du paiement HelloAsso. Veuillez réessayer."
        return
      end

      checkout_id = result[:body]["id"].to_s
      redirect_url = result[:body]["redirectUrl"]

      unless redirect_url
        Rails.logger.error("[Memberships::PaymentsController] Pas de redirectUrl dans la réponse : #{result.inspect}")
        redirect_to membership_path(@membership), alert: "Erreur lors de l'initialisation du paiement HelloAsso. Veuillez réessayer."
        return
      end

      # Créer ou mettre à jour le Payment
      if @membership.payment
        @membership.payment.update!(
          provider_payment_id: checkout_id,
          status: "pending",
          amount_cents: @membership.total_amount_cents
        )
      else
        payment = Payment.create!(
          provider: "helloasso",
          provider_payment_id: checkout_id,
          status: "pending",
          amount_cents: @membership.total_amount_cents,
          currency: @membership.currency || "EUR"
        )
        @membership.update!(payment: payment)
      end

      @membership.update!(provider_order_id: checkout_id)

      redirect_to redirect_url, allow_other_host: true
    rescue => e
      Rails.logger.error("[Memberships::PaymentsController] Erreur lors du paiement : #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      redirect_to membership_path(@membership), alert: "Erreur lors de l'initialisation du paiement : #{e.message}"
    end

    # GET /memberships/:membership_id/payments/status (collection)
    # ou GET /payments/:id (shallow) - mais on utilise la collection pour le statut
    def show
      if @membership.payment
        # Vérifier le statut réel via HelloAsso
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
      # Rails envoie membership_ids[] comme un array
      membership_ids = params[:membership_ids] || params["membership_ids"] || []
      # Normaliser en array si c'est une string
      membership_ids = [ membership_ids ] unless membership_ids.is_a?(Array)
      membership_ids = membership_ids.reject(&:blank?)

      if membership_ids.empty?
        redirect_to memberships_path, alert: "Aucune adhésion sélectionnée."
        return
      end

      # Récupérer les adhésions enfants pending de l'utilisateur
      memberships = current_user.memberships.where(
        id: membership_ids,
        is_child_membership: true,
        status: "pending"
      )

      if memberships.empty?
        redirect_to memberships_path, alert: "Aucune adhésion enfant en attente de paiement trouvée."
        return
      end

      # Créer un paiement groupé HelloAsso
      begin
        result = HelloassoService.create_multiple_memberships_checkout_intent(
          memberships.to_a,
          back_url: memberships_url(host: request.host_with_port, protocol: request.protocol),
          error_url: memberships_url(host: request.host_with_port, protocol: request.protocol),
          return_url: memberships_url(host: request.host_with_port, protocol: request.protocol)
        )

        unless result[:success] && result[:body]["redirectUrl"]
          Rails.logger.error("[Memberships::PaymentsController] Échec création checkout-intent groupé : #{result.inspect}")
          redirect_to memberships_path, alert: "Erreur lors de l'initialisation du paiement HelloAsso. Veuillez réessayer."
          return
        end

        checkout_id = result[:body]["id"].to_s
        redirect_url = result[:body]["redirectUrl"]

        # Créer un Payment unique pour toutes les adhésions
        total_amount = memberships.sum(&:total_amount_cents)
        payment = Payment.create!(
          provider: "helloasso",
          provider_payment_id: checkout_id,
          status: "pending",
          amount_cents: total_amount,
          currency: "EUR"
        )

        # Lier le paiement à toutes les adhésions
        memberships.each do |membership|
          membership.update!(
            payment: payment,
            provider_order_id: checkout_id
          )
        end

        redirect_to redirect_url, allow_other_host: true
      rescue => e
        Rails.logger.error("[Memberships::PaymentsController] Erreur lors du paiement groupé : #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        redirect_to memberships_path, alert: "Erreur lors de l'initialisation du paiement : #{e.message}"
      end
    end

    private

    def set_membership
      @membership = current_user.memberships.find(params[:membership_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to memberships_path, alert: "Adhésion introuvable."
    end
  end
end
