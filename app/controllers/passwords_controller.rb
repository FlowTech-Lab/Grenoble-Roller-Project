class PasswordsController < Devise::PasswordsController
  # Ce controller gère :
  # 1. "Mot de passe oublié" (reset via email) pour utilisateurs NON connectés
  # 2. "Changer le mot de passe" pour utilisateurs connectés (via formulaire séparé)

  # ÉTAPE 1: Surcharger require_no_authentication pour permettre edit/update aux utilisateurs connectés
  def require_no_authentication
    # Si l'utilisateur est connecté ET accède à edit ou update, on ne fait RIEN
    # (pas de redirection, pas de message)
    return if user_signed_in? && (action_name == "edit" || action_name == "update")

    # Pour toutes les autres actions (new, create), comportement par défaut de Devise
    super
  end

  # ÉTAPE 2: Override edit pour gérer les deux cas
  def edit
    # Si un token de réinitialisation est présent, c'est une réinitialisation (même si connecté)
    if params[:reset_password_token].present?
      # Réinitialisation via email (comportement par défaut de Devise)
      super
    elsif user_signed_in?
      # Utilisateur connecté SANS token : rediriger vers le profil (le formulaire est déjà là)
      redirect_to edit_user_registration_path, notice: "Vous pouvez modifier votre mot de passe dans votre profil."
    else
      # Utilisateur NON connecté SANS token : rediriger vers la demande de réinitialisation
      redirect_to new_user_password_path, alert: "Lien de réinitialisation invalide. Veuillez demander un nouveau lien."
    end
  end

  # ÉTAPE 3: Override update pour gérer les deux cas
  def update
    # Si un token de réinitialisation est présent, c'est une réinitialisation
    if params[:user][:reset_password_token].present?
      # Réinitialisation via email (comportement par défaut de Devise)
      super
    elsif user_signed_in?
      # Utilisateur connecté SANS token : ne devrait pas arriver (redirection dans edit)
      # Mais au cas où, rediriger vers le profil
      redirect_to edit_user_registration_path, notice: "Veuillez modifier votre mot de passe depuis votre profil."
    else
      # Utilisateur NON connecté SANS token : réinitialisation via email (comportement par défaut)
      super
    end
  end

  private

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
