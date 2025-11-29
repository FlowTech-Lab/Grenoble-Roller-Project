# frozen_string_literal: true

class MembershipMailer < ApplicationMailer
  # Email envoyé quand une adhésion est activée (paiement confirmé)
  def activated(membership)
    @membership = membership
    @user = membership.user

    mail(
      to: @user.email,
      subject: "✅ Adhésion Saison #{@membership.season} - Bienvenue !"
    )
  end

  # Email envoyé quand une adhésion expire
  def expired(membership)
    @membership = membership
    @user = membership.user

    mail(
      to: @user.email,
      subject: "⏰ Adhésion Saison #{@membership.season} - Expirée"
    )
  end

  # Email envoyé 30 jours avant l'expiration (rappel de renouvellement)
  def renewal_reminder(membership)
    @membership = membership
    @user = membership.user

    mail(
      to: @user.email,
      subject: "🔄 Renouvellement d'adhésion - Dans 30 jours"
    )
  end

  # Email envoyé quand un paiement échoue
  def payment_failed(membership)
    @membership = membership
    @user = membership.user

    mail(
      to: @user.email,
      subject: "❌ Paiement adhésion Saison #{@membership.season} - Échec"
    )
  end
end
