# frozen_string_literal: true

module AdminPanelHelper
  # Afficher le breadcrumb sauf sur le dashboard
  def show_breadcrumb?
    !(controller_name == 'dashboard' && action_name == 'index')
  end

  # Vérifier si l'utilisateur est admin
  def admin_user?
    return false unless current_user&.role

    current_user.role.code.in?(%w[ADMIN SUPERADMIN])
  end
end
