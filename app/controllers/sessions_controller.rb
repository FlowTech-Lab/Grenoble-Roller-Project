# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  # POST /resource/sign_in
  def create
    super do |resource|
      if resource.persisted?
        handle_confirmed_or_unconfirmed(resource)
      end
    end
  end

  # DELETE /resource/sign_out
  def destroy
    super do
      flash[:notice] = "À bientôt ! 🛼 Revenez vite pour découvrir nos prochains événements."
    end
  end

  protected

  # The path used after sign in.
  def after_sign_in_path_for(_resource)
    # Rediriger vers la page demandée ou la page d'accueil
    stored_location_for(_resource) || root_path
  end

  # The path used after sign out.
  def after_sign_out_path_for(_resource_or_scope)
    root_path
  end

  private

  def handle_confirmed_or_unconfirmed(resource)
    if resource.confirmed?
      # Email confirmé : connexion normale
      first_name = resource.first_name.presence || "membre"
      flash[:notice] = "Bonjour #{first_name} ! 👋 Bienvenue sur Grenoble Roller."
    elsif resource.confirmation_sent_at && resource.confirmation_sent_at > 2.days.ago
      # Dans période de grâce : message d'avertissement
      first_name = resource.first_name.presence || "membre"
      resend_link = view_context.link_to(
        "Renvoyer l'email de confirmation",
        new_user_confirmation_path(email: resource.email),
        class: "alert-link"
      )
      flash[:warning] = 
        "Bonjour #{first_name} ! 👋 " \
        "Votre email n'est pas encore confirmé. #{resend_link}".html_safe
    else
      # Après période de grâce : déconnecter et rediriger
      sign_out(resource)
      flash[:alert] = 
        "Votre période de confirmation est expirée. " \
        "Veuillez demander un nouveau lien de confirmation."
      redirect_to new_user_confirmation_path(email: resource.email)
      return
    end
  end
end
