class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?

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

  # Vérifier que l'email est confirmé pour les actions critiques
  def ensure_email_confirmed
    return unless user_signed_in?

    # En développement et en test, on ne bloque pas les actions pour faciliter les tests
    return if Rails.env.development? || Rails.env.test?

    unless current_user.confirmed?
      redirect_to root_path,
                  alert: "Vous devez confirmer votre adresse email pour effectuer cette action. Vérifiez votre boîte mail ou demandez un nouvel email de confirmation.",
                  status: :forbidden
    end
  end
end
