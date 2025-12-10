#!/bin/bash
###############################################################################
# Script de rebuild rapide PRODUCTION (sans déploiement complet)
# Usage: ./ops/production/rebuild.sh
# Effectue: rebuild sans cache + redémarrage
# ⚠️  ATTENTION: Ce script est pour PRODUCTION - utilisez avec précaution
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Charger les modules nécessaires
LIB_DIR="${SCRIPT_DIR}/../lib"
source "${LIB_DIR}/core/colors.sh"
source "${LIB_DIR}/core/logging.sh"
source "${LIB_DIR}/docker/compose.sh"

COMPOSE_FILE="${REPO_DIR}/ops/production/docker-compose.yml"
CONTAINER_NAME="grenoble-roller-production"

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🔨 REBUILD RAPIDE - PRODUCTION"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log_warning "⚠️  ⚠️  ⚠️  ATTENTION : ENVIRONNEMENT PRODUCTION ⚠️  ⚠️  ⚠️"
log_warning "Ce script va rebuilder l'image PRODUCTION sans cache"
log_warning "Cela peut prendre 10-15 minutes et causer un downtime"
log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p "Confirmez-vous que vous êtes en PRODUCTION et voulez continuer ? (tapez 'PRODUCTION') : " confirmation || confirmation=""
if [ "$confirmation" != "PRODUCTION" ]; then
    log_error "Annulation - Confirmation incorrecte"
    exit 1
fi

# Rebuild sans cache
log "🔨 Rebuild sans cache en cours..."
if force_rebuild_without_cache "$COMPOSE_FILE" "$CONTAINER_NAME"; then
    log_success "✅ Rebuild terminé avec succès"
    log_info "💡 Pour initialiser la DB: ./ops/production/init-db.sh"
else
    log_error "❌ Échec du rebuild"
    exit 1
fi

