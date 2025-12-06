class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_email_confirmation_status, if: :user_signed_in?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def configure_permitted_parameters
    # Permet ces champs lors de l'inscription (4 champs : email, prénom, password, skill_level)
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :first_name,
      :skill_level,
      :role_id
    ])

    # Permet ces champs lors de la modification du profil
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :first_name,
      :last_name,
      :bio,
      :phone,
      :avatar_url,
      :avatar,
      :skill_level,
      :email,
      :password,
      :password_confirmation,
      :current_password,  # OBLIGATOIRE pour toute modification
      :date_of_birth,
      :address,
      :postal_code,
      :city,
      :wants_whatsapp,
      :wants_email_info
    ])
  end

  private

  def user_not_authorized(_exception)
    redirect_to(request.referer || root_path, alert: "Vous n'êtes pas autorisé·e à effectuer cette action.")
  end

  def active_admin_access_denied(exception)
    user_not_authorized(exception)
  end

  helper_method :current_user_has_attendance?

  def current_user_has_attendance?(event)
    return false unless current_user

    event.attendances.exists?(user_id: current_user.id)
  end

  # Vérifier le statut de confirmation de l'email (gestion générale)
  def check_email_confirmation_status
    return if current_user.confirmed?
    return if skip_confirmation_check?

    # Après période de grâce : bloquer certaines actions
    if current_user.confirmation_sent_at && current_user.confirmation_sent_at < 2.days.ago
      sign_out(current_user)
      redirect_to root_path,
                  alert: "Merci de confirmer votre email pour continuer.",
                  status: :forbidden
    end
  end

  # Vérifier que l'email est confirmé pour les actions critiques
  def ensure_email_confirmed
    return unless user_signed_in?

    # En développement et en test, on ne bloque pas les actions pour faciliter les tests
    return if Rails.env.development? || Rails.env.test?

    unless current_user.confirmed?
      confirmation_link = view_context.link_to(
        "demandez un nouvel email de confirmation",
        new_user_confirmation_path,
        class: "alert-link"
      )
      redirect_to root_path,
                  alert: "Vous devez confirmer votre adresse email pour effectuer cette action. " \
                         "Vérifiez votre boîte mail ou #{confirmation_link}".html_safe,
                  status: :forbidden
    end
  end

  def skip_confirmation_check?
    # Routes où confirmation n'est pas requise
    skipped_routes = %w[
      sessions#destroy
      confirmations#show
      confirmations#create
      passwords#new
      passwords#create
    ]

    controller_action = "#{controller_name}##{action_name}"
    skipped_routes.include?(controller_action)
  end
end
