module AdminPanel
  class BaseController < ApplicationController
    before_action :authenticate_admin_user!
    layout 'admin'
    
    private
    
    def authenticate_admin_user!
      unless current_user&.role&.code.in?(%w[ADMIN SUPERADMIN])
        redirect_to root_path, alert: 'Accès administrateur requis'
      end
    end
    
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
    
    def user_not_authorized
      flash[:alert] = 'Vous n\'êtes pas autorisé à effectuer cette action'
      redirect_to admin_panel_root_path
    end
  end
end
