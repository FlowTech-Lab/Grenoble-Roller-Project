#!/bin/bash
###############################################################################
# Script de rebuild rapide STAGING (sans déploiement complet)
# Usage: ./ops/staging/rebuild.sh
# Effectue: rebuild sans cache + redémarrage
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Charger les modules nécessaires
LIB_DIR="${SCRIPT_DIR}/../lib"
source "${LIB_DIR}/core/colors.sh"
source "${LIB_DIR}/core/logging.sh"
source "${LIB_DIR}/docker/compose.sh"

COMPOSE_FILE="${REPO_DIR}/ops/staging/docker-compose.yml"
CONTAINER_NAME="grenoble-roller-staging"

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🔨 REBUILD RAPIDE - STAGING"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log_warning "⚠️  Ce script va rebuilder l'image sans cache"
log_warning "   Cela peut prendre 5-10 minutes"
read -p "Continuer ? (o/N) : " choice || choice="N"
if [[ ! "$choice" =~ ^[OoYy]$ ]]; then
    log_info "Annulé"
    exit 0
fi

# Rebuild sans cache
log "🔨 Rebuild sans cache en cours..."
if force_rebuild_without_cache "$COMPOSE_FILE" "$CONTAINER_NAME"; then
    log_success "✅ Rebuild terminé avec succès"
    log_info "💡 Pour initialiser la DB: ./ops/staging/init-db.sh"
else
    log_error "❌ Échec du rebuild"
    exit 1
fi

