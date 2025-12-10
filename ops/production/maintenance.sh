#!/bin/bash
###############################################################################
# Script pour activer/désactiver le mode maintenance
# Usage: ./ops/production/maintenance.sh [enable|disable|status]
###############################################################################

set -euo pipefail

CONTAINER_NAME="grenoble-roller-production"
ACTION="${1:-status}"

case "$ACTION" in
  enable|on|start)
    echo "🔒 Activation du mode maintenance..."
    sudo docker exec "$CONTAINER_NAME" bin/rails runner "MaintenanceMode.enable!"
    echo "✅ Mode maintenance activé"
    ;;
  disable|off|stop)
    echo "✅ Désactivation du mode maintenance..."
    sudo docker exec "$CONTAINER_NAME" bin/rails runner "MaintenanceMode.disable!"
    echo "✅ Mode maintenance désactivé"
    ;;
  status|check)
    echo "📊 Vérification du statut du mode maintenance..."
    sudo docker exec "$CONTAINER_NAME" bin/rails runner "puts 'Mode maintenance: ' + MaintenanceMode.status"
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

