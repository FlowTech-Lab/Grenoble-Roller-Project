# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  # Inclure TurnstileVerifiable explicitement car RegistrationsController n'hérite pas de ApplicationController
  include TurnstileVerifiable
  # POST /resource
  def create
    # Vérifier le consentement RGPD avant création
    unless params[:accept_terms] == "1"
      build_resource(sign_up_params)
      resource.errors.add(:base, "Vous devez accepter les Conditions Générales d'Utilisation et la Politique de Confidentialité pour créer un compte.")
      render :new, status: :unprocessable_entity
      return
    end

    # Vérifier Turnstile (protection anti-bot) AVANT création
    # Si échec, bloquer immédiatement et ne PAS créer l'utilisateur
    unless verify_turnstile
      Rails.logger.warn(
        "RegistrationsController#create - Turnstile verification FAILED - BLOCKING registration for IP: #{request.remote_ip}"
      )
      build_resource(sign_up_params)
      resource.errors.add(:base, "Vérification de sécurité échouée. Veuillez réessayer.")
      # IMPORTANT: Ne pas créer l'utilisateur, bloquer complètement
      render :new, status: :unprocessable_entity
      return
    end

    Rails.logger.info("RegistrationsController#create - Turnstile verification PASSED, proceeding with registration")

    build_resource(sign_up_params)

    if resource.save
      # Gérer l'opt-in newsletter (futur)
      # TODO: Implémenter newsletter subscription si params[:newsletter_subscription] == "1"

      # Message de bienvenue personnalisé avec demande de confirmation email
      if resource.first_name.present?
        flash[:notice] = "Bienvenue #{resource.first_name} ! 🎉 " \
                        "Votre compte a été créé avec succès. " \
                        "Un email de confirmation vous a été envoyé. " \
                        "Veuillez confirmer votre adresse email pour accéder à toutes les fonctionnalités."
        flash[:type] = 'success'
      else
        flash[:notice] = "Bienvenue ! 🎉 " \
                        "Votre compte a été créé avec succès. " \
                        "Un email de confirmation vous a été envoyé. " \
                        "Veuillez confirmer votre adresse email pour accéder à toutes les fonctionnalités."
        flash[:type] = 'success'
      end

      # Ne PAS connecter l'utilisateur automatiquement - il DOIT confirmer son email
      # Utiliser after_inactive_sign_up_path_for car le compte n'est pas actif (non confirmé)
      sign_out(resource) if user_signed_in?
      redirect_to after_inactive_sign_up_path_for(resource)
    else
      # En cas d'erreur, rester sur la page d'inscription (ne pas rediriger)
      render :new, status: :unprocessable_entity
    end
  end

  protected

  # The path used after sign up.
  def after_sign_up_path_for(_resource)
    # Rediriger vers la page de confirmation email
    # L'utilisateur ne peut pas accéder à l'application sans confirmer
    new_user_confirmation_path
  end

  # The path used after sign up for inactive accounts (non confirmés).
  def after_inactive_sign_up_path_for(_resource)
    # Rediriger vers la page de confirmation email
    new_user_confirmation_path
  end

  # The path used after updating the account.
  def after_update_path_for(_resource)
    edit_user_registration_path
  end

  # Override update_resource pour gérer le changement de mot de passe
  # BONNE PRATIQUE DEVISE : Toujours exiger current_password pour toute modification
  def update_resource(resource, params)
    # Gérer les paramètres de date de naissance (3 menus déroulants)
    if params[:date_of_birth].blank? && params[:date_of_birth_day].present? && params[:date_of_birth_month].present? && params[:date_of_birth_year].present?
      day = params[:date_of_birth_day].to_i
      month = params[:date_of_birth_month].to_i
      year = params[:date_of_birth_year].to_i
      
      begin
        date_of_birth = Date.new(year, month, day)
        params[:date_of_birth] = date_of_birth.to_s
      rescue ArgumentError
        resource.errors.add(:date_of_birth, "est invalide")
        return false
      end
    end
    
    # Supprimer les paramètres temporaires
    params.delete(:date_of_birth_day)
    params.delete(:date_of_birth_month)
    params.delete(:date_of_birth_year)
    
    # VALIDATION : current_password est TOUJOURS requis (bonne pratique sécurité)
    if params[:current_password].blank?
      resource.errors.add(:current_password, "est requis pour toute modification")
      return false
    end
    
    # Vérifier que current_password est correct
    unless resource.valid_password?(params[:current_password])
      resource.errors.add(:current_password, "est incorrect")
      return false
    end
    
    # Si password et password_confirmation sont vides, mise à jour sans changer le mot de passe
    if params[:password].blank? && params[:password_confirmation].blank?
      # Supprimer current_password de params (update_without_password ne l'accepte pas)
      params.delete(:current_password)
      resource.update_without_password(params.except(:password, :password_confirmation))
    else
      # Si l'utilisateur veut changer le mot de passe, utiliser update_with_password
      # Cette méthode exige current_password (bonne pratique Devise)
      resource.update_with_password(params)
    end
  end
end
