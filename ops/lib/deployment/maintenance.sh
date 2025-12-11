#!/bin/bash
###############################################################################
# Module: deployment/maintenance.sh
# Description: Gestion du mode maintenance (activation/désactivation)
# Dependencies: 
#   - core/logging.sh
#   - docker/containers.sh (container_is_running)
#   - Variables: CONTAINER_NAME, DOCKER_CMD
# Author: FlowTech Lab
# Version: 1.0.0
###############################################################################

# Activer le mode maintenance
enable_maintenance_mode() {
    local container=${1:-${CONTAINER_NAME:-}}
    
    if [ -z "$container" ]; then
        log_error "Nom du conteneur non spécifié"
        return 1
    fi
    
    if ! container_is_running "$container"; then
        log_warning "⚠️  Conteneur ${container} non running, impossible d'activer le mode maintenance"
        return 1
    fi
    
    log_info "🔒 Activation du mode maintenance..."
    if $DOCKER_CMD exec "$container" bin/rails runner "MaintenanceMode.enable!" 2>/dev/null; then
        log_success "✅ Mode maintenance activé"
        return 0
    else
        log_error "❌ Échec de l'activation du mode maintenance"
        return 1
    fi
}

# Désactiver le mode maintenance
disable_maintenance_mode() {
    local container=${1:-${CONTAINER_NAME:-}}
    
    if [ -z "$container" ]; then
        log_error "Nom du conteneur non spécifié"
        return 1
    fi
    
    if ! container_is_running "$container"; then
        log_warning "⚠️  Conteneur ${container} non running, impossible de désactiver le mode maintenance"
        return 1
    fi
    
    log_info "✅ Désactivation du mode maintenance..."
    if $DOCKER_CMD exec "$container" bin/rails runner "MaintenanceMode.disable!" 2>/dev/null; then
        log_success "✅ Mode maintenance désactivé"
        return 0
    else
        log_error "❌ Échec de la désactivation du mode maintenance"
        return 1
    fi
}

# Vérifier le statut du mode maintenance
check_maintenance_status() {
    local container=${1:-${CONTAINER_NAME:-}}
    
    if [ -z "$container" ]; then
        log_error "Nom du conteneur non spécifié"
        return 1
    fi
    
    if ! container_is_running "$container"; then
        log_warning "⚠️  Conteneur ${container} non running"
        return 1
    fi
    
    local status=$($DOCKER_CMD exec "$container" bin/rails runner "puts MaintenanceMode.enabled? ? 'enabled' : 'disabled'" 2>/dev/null || echo "unknown")
    echo "$status"
    return 0
}

# Vérifier si le mode maintenance est activé
is_maintenance_enabled() {
    local container=${1:-${CONTAINER_NAME:-}}
    local status=$(check_maintenance_status "$container")
    [ "$status" = "enabled" ]
}

