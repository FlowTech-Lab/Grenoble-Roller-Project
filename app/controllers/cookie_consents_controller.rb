# frozen_string_literal: true

# Controller pour la gestion du consentement aux cookies
# Conforme au RGPD et à la directive ePrivacy
class CookieConsentsController < ApplicationController
  # Pas besoin d'authentification pour la gestion des cookies
  # Le token CSRF est inclus dans les requêtes fetch via les headers

  # Afficher les préférences de cookies
  def preferences
    @page_title = "Gestion des Cookies"
    @page_description = "Gérez vos préférences de cookies sur le site Grenoble Roller"
  end

  # Configuration des cookies selon les standards 2025 (RGPD, ePrivacy)
  def cookie_options
    {
      value: nil, # Sera défini dans chaque méthode
      expires: 13.months.from_now, # Durée maximale recommandée RGPD
      httponly: false, # Nécessaire pour être lu par JavaScript
      secure: Rails.env.production?, # Secure uniquement en production (HTTPS)
      same_site: :lax # Protection CSRF, compatible avec les redirections
    }
  end

  # Accepter tous les cookies
  def accept
    consent_data = {
      necessary: true,
      preferences: true,
      analytics: false,
      timestamp: Time.current.iso8601
    }

    options = cookie_options.merge(value: consent_data.to_json)
    cookies[:cookie_consent] = options
    
    respond_to do |format|
      format.json { render json: { status: 'accepted', preferences: consent_data } }
      format.html { redirect_back(fallback_location: root_path, notice: 'Vos préférences de cookies ont été enregistrées.') }
    end
  end

  # Rejeter les cookies non essentiels
  def reject
    consent_data = {
      necessary: true,
      preferences: false,
      analytics: false,
      timestamp: Time.current.iso8601
    }

    options = cookie_options.merge(value: consent_data.to_json)
    cookies[:cookie_consent] = options
    
    respond_to do |format|
      format.json { render json: { status: 'rejected', preferences: consent_data } }
      format.html { redirect_back(fallback_location: root_path, notice: 'Vos préférences de cookies ont été enregistrées.') }
    end
  end

  # Mettre à jour les préférences de cookies
  def update
    consent_data = {
      necessary: true, # Toujours nécessaire
      preferences: params[:preferences] == 'true',
      analytics: params[:analytics] == 'true',
      timestamp: Time.current.iso8601
    }

    options = cookie_options.merge(value: consent_data.to_json)
    cookies[:cookie_consent] = options
    
    respond_to do |format|
      format.json { render json: { status: 'updated', preferences: consent_data } }
      format.html { redirect_back(fallback_location: preferences_cookie_consent_path, notice: 'Vos préférences de cookies ont été mises à jour.') }
    end
  end
end

