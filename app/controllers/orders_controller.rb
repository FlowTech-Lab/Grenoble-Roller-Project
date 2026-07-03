class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_email_confirmed, only: [ :create ] # Exiger confirmation pour passer une commande

  # Vérification explicite de la confirmation email pour create (même en test)
  def ensure_email_confirmed
    return true unless user_signed_in?

    # Recharger l'utilisateur depuis la DB pour éviter les problèmes de cache
    # Utiliser current_user.id directement pour éviter les problèmes de cache
    user_id = current_user.id
    user = User.find(user_id)

    # Vérifier confirmed_at directement (pas confirmed? qui peut être mis en cache)
    unless user.confirmed_at.present?
      confirmation_link = view_context.link_to(
        "demandez un nouvel email de confirmation",
        new_user_confirmation_path,
        class: "alert-link"
      )
      redirect_to root_path,
                  alert: "Vous devez confirmer votre adresse email pour effectuer cette action. " \
                         "Vérifiez votre boîte mail ou #{confirmation_link}".html_safe
      return false # Arrêter l'exécution du callback (alternative à throw(:abort))
    end
    true
  end

  def index
    @orders = current_user.orders.includes(:payment, order_items: { variant: :product }).order(created_at: :desc)
  end

  # Shop checkout uses unified /checkout from the account cart.
  def new
    redirect_to new_checkout_path, notice: "Utilisez le paiement unifié depuis votre panier."
  end

  def create
    redirect_to new_checkout_path, notice: "Utilisez le paiement unifié depuis votre panier."
  end

  def show
    # Support hashid ou ID numérique
    # D'abord trouver l'order par hashid ou ID (sans scope pour hashid)
    found_order = Order.find_by_hashid(params[:id]) if params[:id].present?
    found_order ||= Order.find_by(id: params[:id]) if params[:id].present? && params[:id].match?(/\A\d+\z/)

    # Vérifier que l'order appartient à l'utilisateur
    if found_order && found_order.user_id == current_user.id
      order_scope = current_user.orders.includes(:payment, order_items: { variant: :product })
      @order = order_scope.find(found_order.id)
    else
      # Si l'order n'existe pas ou n'appartient pas à l'utilisateur, lever RecordNotFound
      raise ActiveRecord::RecordNotFound, "Couldn't find Order with 'id'=#{params[:id]}"
    end
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
      # Le stock sera libéré automatiquement via le callback handle_stock_on_status_change
      # lors du changement de statut vers "cancelled"
      # Plus besoin de restaurer manuellement le stock

      # Mettre à jour le statut (le callback va gérer la libération du stock réservé)
      @order.update!(status: "cancelled")
    end

    redirect_to order_path(@order), notice: "Commande annulée avec succès."
  rescue ActiveRecord::RecordNotFound
    raise
  rescue StandardError => e
    redirect_to order_path(@order), alert: "Erreur lors de l'annulation : #{e.message}"
  end

end
