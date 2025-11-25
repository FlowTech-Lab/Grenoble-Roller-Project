# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  # POST /resource/sign_in
  def create
    super do |resource|
      # Le bloc ne s'exécute que si la connexion réussit
      # Message de connexion personnalisé avec le prénom
      first_name = resource.first_name.presence || "membre"
      flash[:notice] = "Bonjour #{first_name} ! 👋 Bienvenue sur Grenoble Roller."
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
end
