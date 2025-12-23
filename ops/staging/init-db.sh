#!/bin/bash
###############################################################################
# Script d'initialisation de la base de données STAGING
# Usage: ./ops/staging/init-db.sh
# Effectue: db:migrate (PostgreSQL) + db:migrate:queue (SQLite) + db:seed
#
# ⚠️  SÉPARATION DES BASES DE DONNÉES :
#    - PostgreSQL (base principale) : users, events, attendances, etc.
#    - SQLite (queue) : jobs Solid Queue (storage/solid_queue.sqlite3)
#    - Les deux bases sont COMPLÈTEMENT INDÉPENDANTES
#    - db:migrate ne touche QUE PostgreSQL
#    - db:migrate:queue ne touche QUE SQLite
#    - Aucune opération ne peut affecter les deux bases simultanément
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Charger les modules nécessaires
LIB_DIR="${SCRIPT_DIR}/../lib"
source "${LIB_DIR}/core/colors.sh"
source "${LIB_DIR}/core/logging.sh"
source "${LIB_DIR}/docker/containers.sh"

CONTAINER_NAME="grenoble-roller-staging"

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🌱 INITIALISATION BASE DE DONNÉES - STAGING"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Vérifier que le conteneur est running
if ! container_is_running "$CONTAINER_NAME"; then
    log_error "❌ Le conteneur ${CONTAINER_NAME} n'est pas en cours d'exécution"
    log_error "Démarrez-le avec: docker compose -f ops/staging/docker-compose.yml up -d"
    exit 1
fi

log_success "✅ Conteneur ${CONTAINER_NAME} est running"

# 1. Vérifier si seeds.rb a changé (comparaison MD5)
log "🔍 Vérification de seeds.rb..."
if [ -f "$REPO_DIR/db/seeds.rb" ]; then
    LOCAL_SEEDS_HASH=$(md5sum "$REPO_DIR/db/seeds.rb" 2>/dev/null | cut -d' ' -f1 || echo "")
    CONTAINER_SEEDS_HASH=$(docker exec "$CONTAINER_NAME" md5sum /rails/db/seeds.rb 2>/dev/null | cut -d' ' -f1 || echo "")
    
    if [ -n "$LOCAL_SEEDS_HASH" ] && [ -n "$CONTAINER_SEEDS_HASH" ]; then
        if [ "$LOCAL_SEEDS_HASH" != "$CONTAINER_SEEDS_HASH" ]; then
            log_warning "⚠️  seeds.rb a changé localement"
            log_warning "   Local:    ${LOCAL_SEEDS_HASH:0:8}..."
            log_warning "   Conteneur: ${CONTAINER_SEEDS_HASH:0:8}..."
            log_warning "   → Rebuild nécessaire pour prendre en compte les changements"
            log_warning "   Exécutez: ./ops/staging/deploy.sh --force"
            read -p "Continuer quand même ? (o/N) : " choice || choice="N"
            if [[ ! "$choice" =~ ^[OoYy]$ ]]; then
                log_info "Annulé"
                exit 0
            fi
        else
            log_success "✅ seeds.rb identique (pas de rebuild nécessaire)"
        fi
    fi
else
    log_error "❌ Fichier seeds.rb introuvable: $REPO_DIR/db/seeds.rb"
    exit 1
fi

# 2. Appliquer les migrations principales (PostgreSQL)
# ⚠️  IMPORTANT : db:migrate ne fait QUE appliquer les migrations en attente
#    - Ne supprime AUCUNE donnée existante
#    - Ne touche QUE la base PostgreSQL principale
#    - La queue SQLite reste complètement intacte
log "🔄 Application des migrations principales (PostgreSQL)..."
log_info "   ℹ️  db:migrate est SÉCURISÉ : applique uniquement les migrations en attente"
log_info "   ℹ️  Aucune donnée existante ne sera supprimée"
if docker exec "$CONTAINER_NAME" bin/rails db:migrate 2>&1 | tee -a /tmp/init-db.log; then
    log_success "✅ Migrations principales appliquées avec succès"
else
    log_error "❌ Échec des migrations principales"
    exit 1
fi

# 2.1. Appliquer les migrations de la queue SQLite (Solid Queue)
# ⚠️  IMPORTANT : db:migrate:queue est complètement SÉPARÉ de PostgreSQL
#    - Ne touche QUE le fichier SQLite (storage/solid_queue.sqlite3)
#    - Ne touche PAS la base PostgreSQL
#    - Les jobs en queue restent intacts
log "🔄 Application des migrations de la queue SQLite (Solid Queue)..."
log_info "   ℹ️  db:migrate:queue est SÉPARÉ : ne touche QUE SQLite, pas PostgreSQL"
log_info "   ℹ️  Les jobs en queue restent intacts"
# S'assurer que le répertoire storage existe
docker exec "$CONTAINER_NAME" mkdir -p /rails/storage 2>/dev/null || true

if docker exec "$CONTAINER_NAME" bin/rails db:migrate:queue 2>&1 | tee -a /tmp/init-db.log; then
    log_success "✅ Migrations de la queue SQLite appliquées avec succès"
else
    # Ne pas faire échouer si la queue n'est pas encore configurée (première installation)
    if docker exec "$CONTAINER_NAME" bin/rails db:migrate:queue 2>&1 | grep -qiE "database.*does not exist|no such file|queue.*not.*configured"; then
        log_warning "⚠️  Base de données queue SQLite non configurée (normal pour première installation)"
        log_info "💡 La queue SQLite sera créée automatiquement au premier usage"
    else
        log_warning "⚠️  Échec des migrations de la queue SQLite (non bloquant)"
    fi
fi

# 3. Seed de la base de données
log "🌱 Exécution du seed..."
log_warning "⚠️  Cette opération va peupler la base de données"
read -p "Continuer ? (o/N) : " choice || choice="N"
if [[ ! "$choice" =~ ^[OoYy]$ ]]; then
    log_info "Seed annulé"
    exit 0
fi

if docker exec "$CONTAINER_NAME" bin/rails db:seed 2>&1 | tee -a /tmp/init-db.log; then
    log_success "✅ Seed terminé avec succès"
    
    # Vérifier le résultat
    USER_COUNT=$(docker exec "$CONTAINER_NAME" bin/rails runner "puts User.count" 2>/dev/null | tr -d '\n\r' || echo "0")
    log_info "📊 ${USER_COUNT} utilisateur(s) créé(s)"
else
    log_error "❌ Échec du seed"
    log_error "Consultez les logs ci-dessus pour plus de détails"
    exit 1
fi

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "✅ INITIALISATION TERMINÉE"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

