# frozen_string_literal: true

module AdminPanel
  class BaseController < ApplicationController
    include Pagy::Backend
    
    # Pundit est déjà inclus dans ApplicationController
    # before_action :authenticate_user! est géré par Devise
    before_action :authenticate_admin_user!
    before_action :set_pagy_options
    
    layout 'admin'
    
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
    
    private
    
    def authenticate_admin_user!
      unless user_signed_in?
        redirect_to new_user_session_path, alert: 'Vous devez être connecté pour accéder à cette page.'
        return
      end
      
      user_level = current_user&.role&.level.to_i
      
      # Les initiations sont accessibles pour level >= 40 (INITIATION, MODERATOR, ADMIN, SUPERADMIN)
      # INITIATION (40) est forcément membre Grenoble Roller
      # ORGANIZER (30) peut être n'importe qui, donc pas accès aux initiations
      # Toutes les autres ressources nécessitent level >= 60 (ADMIN, SUPERADMIN)
      if controller_name == 'initiations'
        unless user_level >= 40
          redirect_to root_path, alert: 'Accès non autorisé'
        end
      else
        unless user_level >= 60 # ADMIN (60) ou SUPERADMIN (70)
          redirect_to root_path, alert: 'Accès admin requis'
        end
      end
    end
    
    def set_pagy_options
      @pagy_options = { items: 25 }
    end
    
    def user_not_authorized(exception)
      flash[:alert] = 'Vous n\'êtes pas autorisé'
      redirect_to admin_panel_initiations_path
    end
  end
end
