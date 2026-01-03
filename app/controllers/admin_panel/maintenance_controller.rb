# frozen_string_literal: true

module AdminPanel
  class MaintenanceController < BaseController
    before_action :authorize_maintenance, only: [:toggle]

    # PATCH /admin-panel/maintenance/toggle
    def toggle
      user_email = current_user.email

      if MaintenanceMode.enabled?
        MaintenanceMode.disable!
        message = "Mode maintenance DÉSACTIVÉ"
        Rails.logger.info("🔓 MAINTENANCE DÉSACTIVÉE par #{user_email}")
        flash[:notice] = message
      else
        MaintenanceMode.enable!
        message = "Mode maintenance ACTIVÉ"
        Rails.logger.warn("🔒 MAINTENANCE ACTIVÉE par #{user_email}")
        flash[:notice] = message
      end

      redirect_to admin_panel_root_path
    end

    private

    def authorize_maintenance
      # Utiliser un objet symbolique pour Pundit (MaintenanceMode n'est pas un modèle ActiveRecord)
      authorize :maintenance, policy_class: AdminPanel::MaintenancePolicy
    end
  end
end
