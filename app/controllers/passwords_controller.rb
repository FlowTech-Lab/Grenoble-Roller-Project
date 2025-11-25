class PasswordsController < Devise::PasswordsController
  # Ce controller gère :
  # 1. "Mot de passe oublié" (reset via email) pour utilisateurs NON connectés
  # 2. "Changer le mot de passe" pour utilisateurs connectés (via formulaire séparé)
  
  # ÉTAPE 1: Surcharger require_no_authentication pour permettre edit/update aux utilisateurs connectés
  def require_no_authentication
    # Si l'utilisateur est connecté ET accède à edit ou update, on ne fait RIEN
    # (pas de redirection, pas de message)
    return if user_signed_in? && (action_name == 'edit' || action_name == 'update')
    
    # Pour toutes les autres actions (new, create), comportement par défaut de Devise
    super
  end
  
  # ÉTAPE 2: Override edit pour gérer les deux cas
  def edit
    if user_signed_in?
      # Utilisateur connecté : formulaire avec current_password
      self.resource = current_user
      @minimum_password_length = Devise.password_length.min
      render :edit
    else
      # Utilisateur NON connecté : réinitialisation via email (comportement par défaut)
      super
    end
  end
  
  # ÉTAPE 3: Override update pour gérer les deux cas
  def update
    if user_signed_in?
      # Utilisateur connecté : changer le mot de passe avec current_password
      if current_user.update_with_password(password_params)
        bypass_sign_in(current_user)
        redirect_to edit_user_registration_path, notice: "Votre mot de passe a été modifié avec succès."
      else
        self.resource = current_user
        @minimum_password_length = Devise.password_length.min
        render :edit, status: :unprocessable_entity
      end
    else
      # Utilisateur NON connecté : réinitialisation via email (comportement par défaut)
      super
    end
  end
  
  private
  
  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end

