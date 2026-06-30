# frozen_string_literal: true

module AdminPanelHelper
  # Afficher le breadcrumb sauf sur le dashboard
  def show_breadcrumb?
    !(controller_name == "dashboard" && action_name == "index")
  end

  # Vérifier si l'utilisateur est admin
  # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
  def admin_user?
    return false unless current_user&.role

    current_user.role.level.to_i >= 60
  end

  # Helper pour vérifier les permissions sidebar par niveau
  # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
  def can_access_admin_panel?(min_level = 60)
    return false unless current_user&.role

    current_user.role.level.to_i >= min_level
  end

  # Helper pour vérifier si on peut voir les initiations (level >= 40)
  # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
  def can_view_initiations?
    can_access_admin_panel?(40)
  end

  # Helper pour vérifier si on peut voir les randos dans le panel (level >= 40)
  def can_view_events?
    can_access_admin_panel?(40)
  end

  # Helper pour vérifier si on peut voir la boutique (level >= 60)
  def can_view_boutique?
    can_access_admin_panel?(60)
  end

  # Whether the current admin may edit/delete the given user (role hierarchy).
  def can_manage_admin_panel_user?(target_user)
    return false unless current_user

    RoleAssignmentService.can_manage_user?(assigner: current_user, target_user: target_user)
  end

  # Whether the role field should be read-only (super admin target, admin actor, or self super admin).
  def admin_panel_user_role_read_only?(target_user)
    return false unless target_user&.role&.level && current_user&.role&.level

    if target_user == current_user &&
       target_user.role.level.to_i >= RoleAssignmentService::SUPERADMIN_LEVEL
      return true
    end

    target_user.role.level.to_i >= RoleAssignmentService::SUPERADMIN_LEVEL &&
      current_user.role.level.to_i < RoleAssignmentService::SUPERADMIN_LEVEL
  end

  # Helper pour vérifier si un controller est actif dans AdminPanel
  def admin_panel_active?(controller_name, action_name = nil)
    return false unless controller.class.name.start_with?("AdminPanel::")

    if action_name
      controller_name.to_s == controller.controller_name && action_name.to_s == controller.action_name
    else
      controller_name.to_s == controller.controller_name
    end
  end

  # Traduit les statuts d'attendance en français (délègue à I18n)
  def attendance_status_fr(status)
    human_status(:attendance, status)
  end

  # Traduit les statuts de waitlist en français (délègue à I18n)
  def waitlist_status_fr(status)
    human_status(:waitlist_entry, status)
  end

  # Parse les arguments JSON d'un job ActionMailer pour extraire mailer et méthode
  # SolidQueue peut stocker les arguments comme String JSON ou déjà désérialisés (Array/Hash)
  # Format ActiveJob: { "arguments": ["MailerClass", "method_name", "deliver_now", {...}] }
  # Format direct: ["MailerClass", "method_name", "deliver_now", {...}]
  def parse_mailer_info(arguments_data)
    info = EmailLog::Parser.call(arguments_data)
    { mailer: info[:mailer], method: info[:method] }
  end
end
