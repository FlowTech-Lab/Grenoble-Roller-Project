# Helper pour l'authentification dans les tests request
# Utilise post user_session_path au lieu de sign_in pour éviter les erreurs
# "Could not find a valid mapping for #<User>"
module RequestAuthenticationHelper
  # Authentifie un utilisateur dans les tests request
  # @param user [User] L'utilisateur à authentifier
  # @param password [String] Le mot de passe (défaut: 'password123')
  def login_user(user, password: nil)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: password || user.password || 'password123'
      }
    }
  end

  def logout_user
    delete destroy_user_session_path
  end
end

RSpec.configure do |config|
  config.include RequestAuthenticationHelper, type: :request
end
