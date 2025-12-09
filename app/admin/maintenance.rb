# app/admin/maintenance.rb
# Page ActiveAdmin pour gérer le mode maintenance

ActiveAdmin.register_page "Maintenance" do
  menu priority: 1, label: "⚙️ Maintenance Mode", parent: false

  content title: "Gestion Mode Maintenance" do
    div class: 'maintenance-panel' do
      div class: 'status-box', style: 'padding: 30px; background: #f8f9fa; border-radius: 12px; margin-bottom: 30px;' do
        current_status = MaintenanceMode.enabled?
        status_label = current_status ? '🔴 ACTIF' : '🟢 INACTIF'
        status_color = current_status ? '#d32f2f' : '#388e3c'
        status_bg = current_status ? 'rgba(211, 47, 47, 0.1)' : 'rgba(56, 142, 60, 0.1)'

        div style: "display: flex; align-items: center; gap: 15px; margin-bottom: 20px;" do
          div style: "font-size: 48px;" do
            current_status ? '🔴' : '🟢'
          end
          div do
            h2 style: "color: #{status_color}; margin: 0; font-size: 24px; font-weight: 700;" do
              "État Actuel : #{status_label}"
            end
            p style: "color: #666; margin: 5px 0 0 0; font-size: 14px;" do
              current_status ? 'Le site est actuellement en maintenance' : 'Le site est normalement accessible'
            end
          end
        end
      end

      div class: 'action-buttons', style: 'margin-top: 30px;' do
        # Vérifier si l'utilisateur est ADMIN ou SUPERADMIN
        user = current_user
        user_is_admin = false
        if user.present? && user.respond_to?(:role) && user.role.present?
          role_code = user.role.code.to_s.upcase
          role_level = user.role.level.to_i
          # Utiliser include? au lieu de in? pour compatibilité
          user_is_admin = ['ADMIN', 'SUPERADMIN'].include?(role_code) || role_level >= 60
        end
        
        if MaintenanceMode.enabled?
          div style: 'background: #f5f5f5; padding: 20px; border-radius: 8px; border-left: 4px solid #388e3c;' do
            h3 style: 'margin: 0 0 15px 0; color: #388e3c;' do
              'Désactiver la Maintenance'
            end
            p style: 'color: #666; margin: 0 0 20px 0;' do
              'Les utilisateurs pourront à nouveau accéder au site normalement.'
            end
            text_node raw(form_tag(admin_maintenance_toggle_path, method: :post, style: 'display: inline;') {
              hidden_field_tag(:authenticity_token, form_authenticity_token) +
              submit_tag('Désactiver Maintenance ✓', 
                class: 'button',
                style: 'padding: 12px 24px; background: #388e3c; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 600; font-size: 16px; display: inline-block;')
            })
          end
        elsif user_is_admin
          # Afficher le bouton d'activation SEULEMENT si l'utilisateur est ADMIN/SUPERADMIN
          div style: 'background: #fff3e0; padding: 20px; border-radius: 8px; border-left: 4px solid #d32f2f;' do
            h3 style: 'margin: 0 0 15px 0; color: #d32f2f;' do
              'Activer la Maintenance'
            end
            p style: 'color: #666; margin: 0 0 20px 0;' do
              'Les visiteurs non connectés verront la page de maintenance. Seuls les administrateurs (ADMIN/SUPERADMIN) pourront continuer à accéder au site.'
            end
            text_node raw(form_tag(admin_maintenance_toggle_path, method: :post, style: 'display: inline;') {
              hidden_field_tag(:authenticity_token, form_authenticity_token) +
              submit_tag('Activer Maintenance 🔒', 
                class: 'button',
                style: 'padding: 12px 24px; background: #d32f2f; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 600; font-size: 16px; display: inline-block;')
            })
          end
        else
          # Utilisateur non-admin : afficher message informatif
          div style: 'background: #f8f9fa; padding: 20px; border-radius: 8px; border-left: 4px solid #6c757d;' do
            h3 style: 'margin: 0 0 15px 0; color: #6c757d;' do
              'Mode Maintenance'
            end
            p style: 'color: #666; margin: 0 0 10px 0;' do
              'Le mode maintenance est actuellement inactif. Seuls les administrateurs (ADMIN/SUPERADMIN) peuvent activer le mode maintenance.'
            end
            if Rails.env.development?
              p style: 'color: #999; font-size: 11px; margin: 10px 0 0 0;' do
                "Debug: user=#{user.present? ? 'present' : 'nil'}, role_code=#{user&.role&.code}, role_level=#{user&.role&.level}, is_admin=#{user_is_admin}"
              end
            end
          end
        end
      end

      div class: 'info-box', style: 'margin-top: 40px; padding: 25px; background: #f8f9fa; border-radius: 12px; border: 1px solid #e0e0e0;' do
        h3 style: 'margin: 0 0 20px 0; color: #333;' do
          'ℹ️ Informations'
        end
        ul style: 'margin: 0; padding-left: 20px; color: #666; line-height: 1.8;' do
          li 'En mode maintenance, seuls les administrateurs (ADMIN/SUPERADMIN) peuvent accéder au site'
          li 'Les visiteurs anonymes et utilisateurs non-admin verront une page de maintenance élégante avec les couleurs Grenoble Roller'
          li 'Le bouton "Administrateur" reste visible sur la page de maintenance pour permettre l\'accès'
          li 'Un bouton "Ancien site" est disponible temporairement pour rediriger vers l\'ancienne version'
          li 'Un bandeau rouge s\'affiche en haut de la navbar pour indiquer le mode maintenance'
          li 'Seuls les ADMIN/SUPERADMIN peuvent activer le mode maintenance'
          li 'Les changements prennent effet immédiatement (pas de redémarrage nécessaire)'
          li 'L\'état est stocké dans le cache Rails (Redis ou fichier selon configuration)'
          li 'Les routes /admin, /users/sign_in, /assets sont toujours accessibles en maintenance'
        end
      end

      div class: 'technical-info', style: 'margin-top: 30px; padding: 20px; background: #fff; border-radius: 8px; border: 1px solid #e0e0e0;' do
        h4 style: 'margin: 0 0 15px 0; color: #333; font-size: 16px;' do
          '📊 Détails Techniques'
        end
        div style: 'color: #666; font-family: monospace; font-size: 13px; line-height: 1.6;' do
          div do
            strong 'Cache Key: ' 
            span MaintenanceMode::CACHE_KEY
          end
          div style: 'margin-top: 8px;' do
            strong 'Status: ' 
            span MaintenanceMode.status
          end
          div style: 'margin-top: 8px;' do
            strong 'Middleware: ' 
            span 'MaintenanceMiddleware (insert_before ShowExceptions)'
          end
        end
      end
    end
  end

  # L'action toggle est gérée par le controller personnalisé Admin::MaintenanceController
  # pour plus de fiabilité que page_action
end

