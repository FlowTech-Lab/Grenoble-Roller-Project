class PasswordsController < Devise::PasswordsController
  # Override to allow logged in users to access password change page
  skip_before_action :require_no_authentication, only: [:edit, :update]
  
  # Override edit action to handle both cases:
  # - User coming from email (with reset_password_token)
  # - Logged in user (without token, using current_password)
  
  def edit
    if user_signed_in?
      # For logged in users, set up the resource
      self.resource = current_user
      @minimum_password_length = Devise.password_length.min
    else
      # For password reset from email, use default Devise behavior
      super
    end
  end
  
  def update
    if user_signed_in?
      # For logged in users, update password with current_password
      if current_user.update_with_password(password_params)
        bypass_sign_in(current_user)
        redirect_to edit_user_registration_path, notice: "Votre mot de passe a été modifié avec succès."
      else
        self.resource = current_user
        @minimum_password_length = Devise.password_length.min
        render :edit, status: :unprocessable_entity
      end
    else
      # For password reset from email, use default Devise behavior
      super
    end
  end
  
  private
  
  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end

