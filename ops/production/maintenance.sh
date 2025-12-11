#!/bin/bash
###############################################################################
# Script pour activer/désactiver le mode maintenance
# Usage: ./ops/production/maintenance.sh [enable|disable|status]
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

# Charger les modules nécessaires
source "${LIB_DIR}/core/colors.sh"
source "${LIB_DIR}/core/logging.sh"
source "${LIB_DIR}/docker/containers.sh"
source "${LIB_DIR}/deployment/maintenance.sh"

CONTAINER_NAME="grenoble-roller-production"
ACTION="${1:-status}"

case "$ACTION" in
  enable|on|start)
    log "🔒 Activation du mode maintenance..."
    if enable_maintenance_mode "$CONTAINER_NAME"; then
        log_success "✅ Mode maintenance activé"
    else
        log_error "❌ Échec de l'activation"
        exit 1
    fi
    ;;
  disable|off|stop)
    log "✅ Désactivation du mode maintenance..."
    if disable_maintenance_mode "$CONTAINER_NAME"; then
        log_success "✅ Mode maintenance désactivé"
    else
        log_error "❌ Échec de la désactivation"
        exit 1
    fi
    ;;
  status|check)
    log "📊 Vérification du statut du mode maintenance..."
    local status=$(check_maintenance_status "$CONTAINER_NAME")
    if [ "$status" = "enabled" ]; then
        log_info "Mode maintenance: 🔒 ACTIVÉ"
    elif [ "$status" = "disabled" ]; then
        log_info "Mode maintenance: ✅ DÉSACTIVÉ"
    else
        log_warning "Mode maintenance: ❓ INCONNU"
    fi
    ;;
  *)
    echo "Usage: $0 [enable|disable|status]"
    echo ""
    echo "Commandes disponibles:"
    echo "  enable   - Activer le mode maintenance"
    echo "  disable  - Désactiver le mode maintenance"
    echo "  status   - Vérifier le statut (défaut)"
    exit 1
    ;;
esac

