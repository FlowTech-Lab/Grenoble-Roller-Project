# frozen_string_literal: true

# Concern pour gérer les réponses API JSON dans les contrôleurs
# Utilisé pour les applications mobiles
module ApiResponder
  extend ActiveSupport::Concern

  included do
    # Définir le format par défaut pour les requêtes API
    before_action :set_default_response_format, if: :api_request?

    # Gérer les erreurs d'authentification pour les requêtes API
    rescue_from Devise::FailureApp, with: :handle_api_authentication_error
  end

  private

  # Détecter si c'est une requête API (format JSON ou header Accept: application/json)
  def api_request?
    request.format.json? || 
    request.headers["Accept"]&.include?("application/json") ||
    params[:format] == "json"
  end

  # Définir le format de réponse par défaut
  def set_default_response_format
    request.format = :json unless request.format.json?
  end

  # Gérer les erreurs d'authentification pour les requêtes API
  def handle_api_authentication_error(exception)
    if api_request?
      render json: { 
        error: "Non authentifié", 
        message: "Vous devez être connecté pour accéder à cette ressource" 
      }, status: :unauthorized
    else
      raise exception
    end
  end

  # Helper pour répondre en JSON avec un format standardisé
  def render_json_success(data = {}, status: :ok)
    render json: { success: true, data: data }, status: status
  end

  def render_json_error(message, errors: {}, status: :unprocessable_entity)
    render json: { 
      success: false, 
      error: message, 
      errors: errors 
    }, status: status
  end
end

