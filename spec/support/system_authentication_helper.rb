# Helper pour l'authentification dans les tests system/feature
module SystemAuthenticationHelper
  def login_as(user)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Mot de passe', with: user.password || 'password123'
    click_button 'Se connecter'
    # Attendre que la connexion soit effective (pas d'erreur visible)
    expect(page).not_to have_content('Email ou mot de passe invalide')
  end
end

RSpec.configure do |config|
  config.include SystemAuthenticationHelper, type: :system
end
