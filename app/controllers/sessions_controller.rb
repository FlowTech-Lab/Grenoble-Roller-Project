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
    # Si l'email n'est pas confirmé, bloquer la connexion
    unless resource.confirmed?
      sign_out(resource)
      confirmation_link = view_context.link_to(
        "demandez un nouvel email de confirmation",
        new_user_confirmation_path(email: resource.email),
        class: "alert-link"
      )
      flash[:alert] = 
        "Vous devez confirmer votre adresse email pour vous connecter. " \
        "Vérifiez votre boîte mail ou #{confirmation_link}".html_safe
      redirect_to new_user_confirmation_path(email: resource.email)
      return
    end

    # Email confirmé : connexion normale
    first_name = resource.first_name.presence || "membre"
    flash[:notice] = "Bonjour #{first_name} ! 👋 Bienvenue sur Grenoble Roller."
  end
end
