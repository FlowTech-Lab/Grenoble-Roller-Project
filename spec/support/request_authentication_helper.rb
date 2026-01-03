# Helper pour l'authentification dans les tests request
# Utilise post user_session_path au lieu de sign_in pour éviter les erreurs
# "Could not find a valid mapping for #<User>"
module RequestAuthenticationHelper
  # Authentifie un utilisateur dans les tests request
  # @param user [User] L'utilisateur à authentifier
  # @param password [String] Le mot de passe (défaut: 'password123')
  # @param confirm_user [Boolean] Si true, confirme l'utilisateur automatiquement (défaut: true)
  def login_user(user, password: nil, confirm_user: true)
    # Utiliser directement POST pour la session (plus fiable dans les tests request)
    # S'assurer que l'utilisateur a un mot de passe
    user_password = password || user.password || 'password123'
    unless user.encrypted_password.present?
      user.update!(password: user_password, password_confirmation: user_password)
    end
    # S'assurer que l'utilisateur est confirmé (sauf si confirm_user: false)
    if confirm_user
      user.update_column(:confirmed_at, Time.current) unless user.confirmed?
    end
    
    post user_session_path, params: {
      user: {
        email: user.email,
        password: user_password
      }
    }
    # Ne pas vérifier le statut ici, laisser les tests le faire si nécessaire
  end

  def logout_user
    delete destroy_user_session_path
  end
end

RSpec.configure do |config|
  config.include RequestAuthenticationHelper, type: :request
end
