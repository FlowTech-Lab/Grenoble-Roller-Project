# frozen_string_literal: true

class ConfirmationsController < Devise::ConfirmationsController
  # ============ RENVOI EMAIL ============

  def create
    email = confirmation_params[:email]&.downcase&.strip

    return render :new, alert: "Email requis" if email.blank?

    @user = User.find_by(email: email)

    case handle_resend_confirmation(email, @user)
    when :rate_limited
      render :new, alert: "Trop de demandes. Réessayez dans 1 heure."
    when :already_confirmed
      redirect_to root_path, notice: "Cet email est déjà confirmé ✓"
    when :not_found
      # Anti-énumération : même réponse si user existe ou non
      render :confirmed, notice: i18n_success_message
    when :success
      render :confirmed, notice: i18n_success_message(@user)
    end
  end

  # ============ CONFIRMATION VIA LIEN ============

  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.errors.empty?
      set_flash_message! :notice, :confirmed
      sign_in(resource_name, resource)
      redirect_to after_confirmation_path_for(resource)
    else
      handle_confirmation_error(resource)
    end
  end

  private

  def handle_resend_confirmation(email, user)
    # Rate limiting (vérifie côté contrôleur aussi, en plus de Rack::Attack)
    return :rate_limited if rate_limit_exceeded?(email)

    # Email déjà confirmé
    return :already_confirmed if user&.confirmed?

    # Email non trouvé (anti-énumération : on ne révèle pas l'existence)
    return :not_found unless user

    # Envoyer email
    user.send_confirmation_instructions
    :success
  end

  def rate_limit_exceeded?(email)
    cache_key = "resend_confirmation:#{email}:#{Time.current.hour}"
    count = Rails.cache.increment(cache_key, 1, expires_in: 1.hour) || 1
    count > 5 # Max 5 renvois par heure par email
  end

  def handle_confirmation_error(resource)
    if resource.respond_to?(:confirmation_token_expired?) && resource.confirmation_token_expired?
      redirect_to new_user_confirmation_path,
                  alert: "Lien expiré (> 3 jours). Veuillez demander un nouveau lien."
    elsif resource.errors.any?
      redirect_to new_user_confirmation_path,
                  alert: "Lien invalide ou déjà utilisé."
    end
  end

  def confirmation_params
    params.require(:user).permit(:email)
  end

  def i18n_success_message(user = nil)
    "Si l'email existe dans notre système, " \
    "vous recevrez les instructions de confirmation sous peu."
  end

  def after_confirmation_path_for(resource)
    if user_signed_in? && current_user == resource
      root_path
    else
      new_user_session_path
    end
  end
end
