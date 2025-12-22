# frozen_string_literal: true

module AdminPanelHelper
  # Afficher le breadcrumb sauf sur le dashboard
  def show_breadcrumb?
    !(controller_name == 'dashboard' && action_name == 'index')
  end

  # Vérifier si l'utilisateur est admin
  def admin_user?
    return false unless current_user&.role

    current_user.role.level.to_i >= 60 # ADMIN (60) ou SUPERADMIN (70)
  end

  # Helper pour vérifier les permissions sidebar par niveau
  def can_access_admin_panel?(min_level = 60)
    return false unless current_user&.role

    current_user.role.level.to_i >= min_level
  end

  # Helper pour vérifier si on peut voir les initiations (level >= 30)
  def can_view_initiations?
    can_access_admin_panel?(30)
  end

  # Helper pour vérifier si on peut voir la boutique (level >= 60)
  def can_view_boutique?
    can_access_admin_panel?(60)
  end

  # Helper pour vérifier si un controller est actif dans AdminPanel
  def admin_panel_active?(controller_name, action_name = nil)
    return false unless controller.class.name.start_with?('AdminPanel::')

    if action_name
      controller_name.to_s == controller.controller_name && action_name.to_s == controller.action_name
    else
      controller_name.to_s == controller.controller_name
    end
  end

  # Traduit les statuts d'attendance en français
  def attendance_status_fr(status)
    case status.to_s
    when 'pending'
      'En attente'
    when 'registered'
      'Inscrit'
    when 'paid'
      'Payé'
    when 'present'
      'Présent'
    when 'absent'
      'Absent'
    when 'no_show'
      'No-show'
    when 'canceled'
      'Annulé'
    else
      status.to_s.humanize
    end
  end

  # Traduit les statuts de waitlist en français
  def waitlist_status_fr(status)
    case status.to_s
    when 'pending'
      'En attente'
    when 'notified'
      'Notifié'
    when 'converted'
      'Converti'
    when 'cancelled'
      'Annulé'
    else
      status.to_s.humanize
    end
  end
end
