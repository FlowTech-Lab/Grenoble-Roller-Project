# frozen_string_literal: true

# Helper pour la gestion du consentement aux cookies
# Conforme RGPD 2025
module CookieConsentHelper
  # Vérifier si l'utilisateur a donné son consentement pour un type de cookie
  def cookie_consent?(type)
    return false unless cookies[:cookie_consent]

    begin
      consent_data = JSON.parse(cookies[:cookie_consent])
      consent_data[type.to_s] == true
    rescue JSON::ParserError
      false
    end
  end

  # Vérifier si le consentement a été donné
  def has_cookie_consent?
    cookies[:cookie_consent].present?
  end

  # Obtenir les préférences de cookies
  def cookie_preferences
    return {} unless cookies[:cookie_consent]

    begin
      JSON.parse(cookies[:cookie_consent])
    rescue JSON::ParserError
      {}
    end
  end
end

