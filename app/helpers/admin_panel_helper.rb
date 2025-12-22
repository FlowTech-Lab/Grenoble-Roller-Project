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
