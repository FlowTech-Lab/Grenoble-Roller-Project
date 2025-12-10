# frozen_string_literal: true

class OrderMailer < ApplicationMailer
  # Email envoyé quand une commande est créée (pending)
  def order_confirmation(order)
    @order = order
    @user = order.user

    mail(
      to: @user.email,
      subject: "✅ Commande ##{@order.id} - Confirmation de commande"
    )
  end

  # Email envoyé quand une commande est payée
  def order_paid(order)
    @order = order
    @user = order.user

    mail(
      to: @user.email,
      subject: "💳 Commande ##{@order.id} - Paiement confirmé"
    )
  end

  # Email envoyé quand une commande est annulée
  def order_cancelled(order)
    @order = order
    @user = order.user

    mail(
      to: @user.email,
      subject: "❌ Commande ##{@order.id} - Commande annulée"
    )
  end

  # Email envoyé quand une commande est en préparation
  def order_preparation(order)
    @order = order
    @user = order.user

    mail(
      to: @user.email,
      subject: "⚙️ Commande ##{@order.id} - En préparation"
    )
  end

  # Email envoyé quand une commande est expédiée
  def order_shipped(order)
    @order = order
    @user = order.user

    mail(
      to: @user.email,
      subject: "📦 Commande ##{@order.id} - Expédiée"
    )
  end

  # Email envoyé quand une demande de remboursement est créée
  def refund_requested(order)
    @order = order
    @user = order.user

    mail(
      to: @user.email,
      subject: "🔄 Commande ##{@order.id} - Demande de remboursement en cours"
    )
  end

  # Email envoyé quand un remboursement est confirmé
  def refund_confirmed(order)
    @order = order
    @user = order.user

    mail(
      to: @user.email,
      subject: "✅ Commande ##{@order.id} - Remboursement confirmé"
    )
  end
end
