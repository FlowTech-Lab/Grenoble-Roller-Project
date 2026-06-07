# frozen_string_literal: true

module AdminPanel
  class BaseController < ApplicationController
    # Pagy 43 : La méthode pagy() est disponible directement, plus besoin d'inclure Pagy::Backend

    # Pundit est déjà inclus dans ApplicationController
    # before_action :authenticate_user! est géré par Devise
    before_action :authenticate_admin_user!
    before_action :set_pagy_options

    layout "admin"

    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

    private

    def authenticate_admin_user!
      unless user_signed_in?
        redirect_to new_user_session_path, alert: "Vous devez être connecté pour accéder à cette page."
        return
      end

      user_level = current_user&.role&.level.to_i
      min_level = required_admin_panel_level

      return if user_level >= min_level

      redirect_to root_path, alert: min_level >= 60 ? "Accès admin requis" : "Accès non autorisé"
    end

    def required_admin_panel_level
      case controller_name
      when "initiations", "homepage_carousels", "homepage_announcements"
        30
      when "dashboard", "events"
        40
      else
        60
      end
    end

    def set_pagy_options
      @pagy_options = { items: 25 }
    end

    def user_not_authorized(exception)
      flash[:alert] = "Vous n'êtes pas autorisé"
      redirect_to admin_panel_root_path
    end
  end
end
