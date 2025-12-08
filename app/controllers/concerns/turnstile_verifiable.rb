# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

# Concern pour vérifier Cloudflare Turnstile côté serveur
# Documentation: https://developers.cloudflare.com/turnstile/
module TurnstileVerifiable
  extend ActiveSupport::Concern

  private

  # Vérifier le token Turnstile
  # Retourne true si vérification réussie, false sinon
  def verify_turnstile
    # En test, toujours retourner true (skip verification)
    return true if Rails.env.test?

    # Récupérer le token depuis les paramètres
    # Turnstile ajoute automatiquement le token dans un champ caché avec ce nom
    token = params['cf-turnstile-response'] || params[:'cf-turnstile-response']

    # Si pas de token, la vérification échoue
    if token.blank?
      Rails.logger.warn(
        "Turnstile verification failed: No token provided for IP #{request.remote_ip}. " \
        "Available params keys: #{params.keys.grep(/turnstile|cf-/).inspect}"
      )
      return false
    end

    # Vérifier avec l'API Cloudflare
    verify_with_cloudflare(token)
  end

  # Vérifier le token avec l'API Cloudflare
  def verify_with_cloudflare(token)
    secret_key = Rails.application.credentials.dig(:turnstile, :secret_key) ||
                 ENV.fetch("TURNSTILE_SECRET_KEY", "")

    # Si pas de clé secrète configurée, skip verification en dev
    # MAIS logger un avertissement pour indiquer que la vérification est désactivée
    if secret_key.blank? && Rails.env.development?
      Rails.logger.warn(
        "Turnstile verification SKIPPED in development (no secret_key configured). " \
        "This is UNSAFE - Turnstile should be configured even in development!"
      )
      return true
    end

    return false if secret_key.blank?

    # Faire la requête à l'API Cloudflare
    uri = URI("https://challenges.cloudflare.com/turnstile/v0/siteverify")
    response = Net::HTTP.post_form(uri, {
      secret: secret_key,
      response: token,
      remoteip: request.remote_ip
    })

    result = JSON.parse(response.body)

    # Log en cas d'échec pour debugging
    unless result['success']
      Rails.logger.warn(
        "Turnstile verification failed: #{result['error-codes']&.join(', ')} " \
        "for IP #{request.remote_ip}. Response: #{result.inspect}"
      )
    else
      Rails.logger.debug("Turnstile verification successful for IP #{request.remote_ip}")
    end

    result['success'] == true
  rescue => e
    # En cas d'erreur, log et retourner false pour sécurité
    Rails.logger.error("Turnstile verification error: #{e.message}")
    false
  end
end

