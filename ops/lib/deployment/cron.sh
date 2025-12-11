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
    if $DOCKER_CMD exec "$container" bundle exec whenever --update-crontab --set "environment=${env}" 2>&1; then
        log_success "✅ Crontab installé/mis à jour avec succès"
        
        # Afficher les entrées installées (pour vérification)
        log_info "📋 Entrées cron installées:"
        $DOCKER_CMD exec "$container" bundle exec whenever --set "environment=${env}" 2>/dev/null | while IFS= read -r line; do
            log_info "   $line"
        done || log_warning "⚠️  Impossible d'afficher les entrées cron"
        
        return 0
    else
        log_error "❌ Échec de l'installation du crontab"
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

