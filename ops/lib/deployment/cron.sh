#!/bin/bash
###############################################################################
# Module: deployment/cron.sh
# Description: Gestion automatique du crontab via whenever
# Dependencies: 
#   - core/logging.sh
#   - core/utils.sh
#   - Variables: REPO_DIR, ENV
# Author: FlowTech Lab
# Version: 1.0.0
###############################################################################

# Installe ou met à jour le crontab depuis schedule.rb
# Utilise whenever pour générer et installer le crontab
# IMPORTANT : S'exécute depuis le conteneur (bundle/whenever disponibles uniquement dans le conteneur)
install_crontab() {
    local container=${CONTAINER_NAME:-}
    local env=${ENV:-production}
    
    if [ -z "$container" ]; then
        log_warning "⚠️  Nom du conteneur non spécifié, impossible d'installer le crontab"
        return 1
    fi
    
    log "🔄 Installation/mise à jour du crontab pour ${env}..."
    
    # Vérifier que le conteneur est running
    if ! container_is_running "$container"; then
        log_warning "⚠️  Conteneur ${container} non running, impossible d'installer le crontab"
        return 1
    fi
    
    # Vérifier que schedule.rb existe dans le conteneur
    if ! $DOCKER_CMD exec "$container" test -f /rails/config/schedule.rb 2>/dev/null; then
        log_error "config/schedule.rb introuvable dans le conteneur"
        return 1
    fi
    
    # Générer et installer le crontab depuis le conteneur
    local whenever_output
    whenever_output=$($DOCKER_CMD exec "$container" bundle exec whenever --update-crontab --set "environment=${env}" 2>&1)
    local whenever_exit_code=$?
    
    # Vérifier si whenever a réellement installé le crontab
    # Le message "your crontab file was not updated" indique un échec silencieux
    if echo "$whenever_output" | grep -q "your crontab file was not updated"; then
        log_error "❌ Échec de l'installation du crontab (whenever n'a pas pu mettre à jour le crontab)"
        log_error "   Message: your crontab file was not updated"
        log_info "   Cela peut être dû à des permissions insuffisantes ou à un accès crontab limité"
        log_info "   Tentative alternative : installation manuelle via crontab -"
        
        # Tentative alternative : générer le crontab et l'installer manuellement
        local crontab_content
        crontab_content=$($DOCKER_CMD exec "$container" bundle exec whenever --set "environment=${env}" 2>/dev/null)
        
        if [ -n "$crontab_content" ]; then
            log_info "   Installation via crontab - (pipe)..."
            # Installer le crontab via stdin
            if echo "$crontab_content" | $DOCKER_CMD exec -i "$container" crontab - 2>/dev/null; then
                log_success "✅ Crontab installé via méthode alternative"
                
                # Vérifier que le crontab est bien installé
                local installed_count
                installed_count=$($DOCKER_CMD exec "$container" crontab -l 2>/dev/null | grep -c "rails runner" || echo "0")
                if [ "$installed_count" -gt 0 ]; then
                    log_success "✅ Vérification : $installed_count entrée(s) cron installée(s)"
                    
                    # Afficher les entrées installées
                    log_info "📋 Entrées cron installées:"
                    $DOCKER_CMD exec "$container" crontab -l 2>/dev/null | while IFS= read -r line; do
                        log_info "   $line"
                    done
                    
                    return 0
                else
                    log_error "❌ Le crontab n'a pas été installé (vérification échouée)"
                    return 1
                fi
            else
                log_error "❌ Échec de l'installation alternative du crontab"
                return 1
            fi
        else
            log_error "❌ Impossible de générer le contenu du crontab"
            return 1
        fi
    elif [ $whenever_exit_code -eq 0 ]; then
        log_success "✅ Crontab installé/mis à jour avec succès"
        
        # Vérifier que le crontab est bien installé
        local installed_count
        installed_count=$($DOCKER_CMD exec "$container" crontab -l 2>/dev/null | grep -c "rails runner" || echo "0")
        if [ "$installed_count" -gt 0 ]; then
            log_success "✅ Vérification : $installed_count entrée(s) cron installée(s)"
        else
            log_warning "⚠️  Le crontab semble installé mais aucune entrée trouvée (peut être normal si vide)"
        fi
        
        # Afficher les entrées installées (pour vérification)
        log_info "📋 Entrées cron installées:"
        $DOCKER_CMD exec "$container" bundle exec whenever --set "environment=${env}" 2>/dev/null | while IFS= read -r line; do
            log_info "   $line"
        done || log_warning "⚠️  Impossible d'afficher les entrées cron"
        
        return 0
    else
        log_error "❌ Échec de l'installation du crontab (exit code: $whenever_exit_code)"
        echo "$whenever_output" | while IFS= read -r line; do
            log_error "   $line"
        done
        return 1
    fi
}

# Vérifie si le crontab est déjà installé
# Retourne 0 si installé, 1 sinon
is_crontab_installed() {
    local container=${CONTAINER_NAME:-}
    
    if [ -z "$container" ] || ! container_is_running "$container"; then
        return 1
    fi
    
    # Vérifier si whenever peut détecter des entrées existantes depuis le conteneur
    if $DOCKER_CMD exec "$container" bundle exec whenever 2>/dev/null | grep -q "EventReminderJob\|helloasso\|memberships"; then
        return 0
    else
        return 1
    fi
}

# Affiche le crontab actuel (généré par whenever)
show_crontab() {
    local container=${CONTAINER_NAME:-}
    local env=${ENV:-production}
    
    if [ -z "$container" ] || ! container_is_running "$container"; then
        log_error "Conteneur non disponible"
        return 1
    fi
    
    log "📋 Crontab actuel (généré depuis config/schedule.rb):"
    $DOCKER_CMD exec "$container" bundle exec whenever --set "environment=${env}" 2>/dev/null | while IFS= read -r line; do
        echo "   $line"
    done
}

# Supprime toutes les entrées cron générées par whenever
clear_crontab() {
    local container=${CONTAINER_NAME:-}
    
    log_warning "🗑️  Suppression du crontab..."
    
    if [ -z "$container" ] || ! container_is_running "$container"; then
        log_error "Conteneur non disponible"
        return 1
    fi
    
    if $DOCKER_CMD exec "$container" bundle exec whenever --clear-crontab; then
        log_success "✅ Crontab supprimé"
        return 0
    else
        log_error "❌ Échec de la suppression du crontab"
        return 1
    fi
}

