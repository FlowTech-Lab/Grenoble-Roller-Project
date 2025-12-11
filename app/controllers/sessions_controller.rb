# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  # Inclure TurnstileVerifiable explicitement car SessionsController n'hérite pas de ApplicationController
  include TurnstileVerifiable
  # GET /resource/sign_in
  # Permettre l'accès à la page de connexion même si déjà connecté (pour tester)
  def new
    # En développement, permettre de voir la page même si connecté
    if Rails.env.development? && user_signed_in?
      flash.now[:info] = "Vous êtes déjà connecté·e. Déconnectez-vous pour tester la connexion."
    end
    super
  end

  # POST /resource/sign_in
  def create
    # ⚠️ LOG CRITIQUE - DOIT TOUJOURS APPARAÎTRE
    Rails.logger.error("=" * 80)
    Rails.logger.error("🔵 SessionsController#create DEBUT - IP: #{request.remote_ip}")
    Rails.logger.error("   Params keys: #{params.keys.inspect}")
    Rails.logger.error("   Turnstile params: #{params.keys.grep(/turnstile|cf-/).inspect}")
    Rails.logger.error("   Token present: #{params['cf-turnstile-response'].present?}")
    Rails.logger.error("=" * 80)

    # Vérifier Turnstile (protection anti-bot) AVANT toute authentification
    # Si échec, bloquer immédiatement et ne PAS appeler super
    begin
      turnstile_result = verify_turnstile
      Rails.logger.error("🔵 Turnstile verification result: #{turnstile_result.inspect}")
    rescue => e
      Rails.logger.error("❌ ERREUR dans verify_turnstile: #{e.class} - #{e.message}")
      Rails.logger.error("   Backtrace: #{e.backtrace.first(5).join(' | ')}")
      turnstile_result = false
    end

    unless turnstile_result
      Rails.logger.error("=" * 80)
      Rails.logger.error("🔴 Turnstile verification FAILED - BLOCKING authentication")
      Rails.logger.error("   IP: #{request.remote_ip}")
      Rails.logger.error("   Ne PAS appeler super - Blocage complet")
      Rails.logger.error("=" * 80)

      self.resource = resource_class.new(sign_in_params)
      resource.errors.add(:base, "Vérification de sécurité échouée. Veuillez réessayer.")
      flash.now[:alert] = "Vérification de sécurité échouée. Veuillez réessayer."
      # IMPORTANT: Ne pas appeler super, bloquer complètement l'authentification
      # Utiliser render au lieu de respond_with pour éviter tout appel à Devise
      render :new, status: :unprocessable_entity
      Rails.logger.error("🔴 RENDER :new terminé, RETURN immédiat")
      return # Retourner immédiatement, ne JAMAIS continuer
    end

    Rails.logger.error("=" * 80)
    Rails.logger.error("🟢 Turnstile verification PASSED - Proceeding with authentication")
    Rails.logger.error("=" * 80)

    # Turnstile OK, procéder avec l'authentification Devise
    super do |resource|
      if resource.persisted?
        # Vérifier si l'email est confirmé APRÈS authentification réussie
        if resource.confirmed?
          # Email confirmé : connexion normale
          first_name = resource.first_name.presence || "membre"
          flash[:notice] = "Bonjour #{first_name} ! 👋 Bienvenue sur Grenoble Roller."
        else
          # Email non confirmé : déconnecter et rediriger vers page de confirmation
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
    # Toujours rediriger vers la page d'accueil après connexion
    # (sauf si une destination spécifique est stockée et qu'elle n'est pas /activeadmin)
    stored_location = stored_location_for(_resource)

    # Si la location stockée est /activeadmin, ignorer et rediriger vers l'accueil
    # Sinon, utiliser la location stockée ou la page d'accueil
    if stored_location&.start_with?("/activeadmin")
      root_path
    else
      stored_location || root_path
    end
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
