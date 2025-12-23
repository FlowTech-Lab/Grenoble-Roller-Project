#!/bin/bash
###############################################################################
# Script d'initialisation de la base de données PRODUCTION
# Usage: ./ops/production/init-db.sh
# Effectue: db:migrate (PostgreSQL) + db:migrate:queue (SQLite) + db:seed
# ⚠️  ATTENTION: Ce script est pour PRODUCTION - utilisez avec précaution
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

CONTAINER_NAME="grenoble-roller-production"

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🌱 INITIALISATION BASE DE DONNÉES - PRODUCTION"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log_warning "⚠️  ⚠️  ⚠️  ATTENTION : ENVIRONNEMENT PRODUCTION ⚠️  ⚠️  ⚠️"
log_warning "Ce script va modifier la base de données PRODUCTION"
log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p "Confirmez-vous que vous êtes en PRODUCTION et voulez continuer ? (tapez 'PRODUCTION') : " confirmation || confirmation=""
if [ "$confirmation" != "PRODUCTION" ]; then
    log_error "Annulation - Confirmation incorrecte"
    exit 1
fi

# Vérifier que le conteneur est running
if ! container_is_running "$CONTAINER_NAME"; then
    log_error "❌ Le conteneur ${CONTAINER_NAME} n'est pas en cours d'exécution"
    log_error "Démarrez-le avec: docker compose -f ops/production/docker-compose.yml up -d"
    exit 1
fi

log_success "✅ Conteneur ${CONTAINER_NAME} est running"

# 1. Vérifier quel seed utiliser (production minimaliste ou complet)
SEEDS_FILE="seeds_production.rb"
SEEDS_FULL_FILE="seeds.rb"

log "🔍 Sélection du fichier de seed..."
if [ -f "$REPO_DIR/db/${SEEDS_FILE}" ]; then
    log_success "✅ Fichier ${SEEDS_FILE} trouvé (seed minimaliste pour production)"
    log_info "   Contenu: Rôles + Compte SuperAdmin uniquement"
    USE_SEEDS_FILE="$SEEDS_FILE"
elif [ -f "$REPO_DIR/db/${SEEDS_FULL_FILE}" ]; then
    log_warning "⚠️  ${SEEDS_FILE} non trouvé, utilisation de ${SEEDS_FULL_FILE} (seed complet)"
    log_warning "   Le seed complet contient des données de test (utilisateurs, produits, etc.)"
    read -p "Utiliser le seed complet en PRODUCTION ? (o/N) : " choice || choice="N"
    if [[ ! "$choice" =~ ^[OoYy]$ ]]; then
        log_error "❌ Annulé - Créez db/seeds_production.rb pour un seed minimaliste"
        exit 1
    fi
    USE_SEEDS_FILE="$SEEDS_FULL_FILE"
else
    log_error "❌ Aucun fichier de seed trouvé"
    log_error "   Attendu: db/${SEEDS_FILE} ou db/${SEEDS_FULL_FILE}"
    exit 1
fi

# Vérifier si le fichier de seed a changé (comparaison MD5)
log "🔍 Vérification de ${USE_SEEDS_FILE}..."
LOCAL_SEEDS_HASH=$(md5sum "$REPO_DIR/db/${USE_SEEDS_FILE}" 2>/dev/null | cut -d' ' -f1 || echo "")
CONTAINER_SEEDS_HASH=$(docker exec "$CONTAINER_NAME" md5sum "/rails/db/${USE_SEEDS_FILE}" 2>/dev/null | cut -d' ' -f1 || echo "")

if [ -n "$LOCAL_SEEDS_HASH" ] && [ -n "$CONTAINER_SEEDS_HASH" ]; then
    if [ "$LOCAL_SEEDS_HASH" != "$CONTAINER_SEEDS_HASH" ]; then
        log_warning "⚠️  ${USE_SEEDS_FILE} a changé localement"
        log_warning "   Local:    ${LOCAL_SEEDS_HASH:0:8}..."
        log_warning "   Conteneur: ${CONTAINER_SEEDS_HASH:0:8}..."
        log_warning "   → Rebuild nécessaire pour prendre en compte les changements"
        log_warning "   Exécutez: ./ops/production/rebuild.sh"
        read -p "Continuer quand même ? (o/N) : " choice || choice="N"
        if [[ ! "$choice" =~ ^[OoYy]$ ]]; then
            log_info "Annulé"
            exit 0
        fi
    else
        log_success "✅ ${USE_SEEDS_FILE} identique (pas de rebuild nécessaire)"
    fi
fi

# 2. Copier le fichier de seed dans le conteneur si nécessaire
if [ "$USE_SEEDS_FILE" = "seeds_production.rb" ]; then
    log "📋 Copie de ${USE_SEEDS_FILE} dans le conteneur..."
    if docker cp "$REPO_DIR/db/${USE_SEEDS_FILE}" "${CONTAINER_NAME}:/rails/db/${USE_SEEDS_FILE}"; then
        log_success "✅ Fichier copié dans le conteneur"
    else
        log_error "❌ Échec de la copie du fichier"
        exit 1
    fi
fi

# 3. Appliquer les migrations principales (PostgreSQL)
# ⚠️  IMPORTANT : db:migrate ne fait QUE appliquer les migrations en attente
#    - Ne supprime AUCUNE donnée existante
#    - Ne touche QUE la base PostgreSQL principale
#    - La queue SQLite reste complètement intacte
log "🔄 Application des migrations principales (PostgreSQL)..."
log_info "   ℹ️  db:migrate est SÉCURISÉ : applique uniquement les migrations en attente"
log_info "   ℹ️  Aucune donnée existante ne sera supprimée"
if docker exec "$CONTAINER_NAME" bin/rails db:migrate 2>&1 | tee -a /tmp/init-db-prod.log; then
    log_success "✅ Migrations principales appliquées avec succès"
else
    log_error "❌ Échec des migrations principales"
    exit 1
fi

# 3.1. Appliquer les migrations de la queue SQLite (Solid Queue)
# ⚠️  IMPORTANT : db:migrate:queue est complètement SÉPARÉ de PostgreSQL
#    - Ne touche QUE le fichier SQLite (storage/solid_queue.sqlite3)
#    - Ne touche PAS la base PostgreSQL
#    - Les jobs en queue restent intacts
log "🔄 Application des migrations de la queue SQLite (Solid Queue)..."
log_info "   ℹ️  db:migrate:queue est SÉPARÉ : ne touche QUE SQLite, pas PostgreSQL"
log_info "   ℹ️  Les jobs en queue restent intacts"
# S'assurer que le répertoire storage existe
docker exec "$CONTAINER_NAME" mkdir -p /rails/storage 2>/dev/null || true

if docker exec "$CONTAINER_NAME" bin/rails db:migrate:queue 2>&1 | tee -a /tmp/init-db-prod.log; then
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

# 4. Seed de la base de données
log "🌱 Exécution du seed (${USE_SEEDS_FILE})..."
if [ "$USE_SEEDS_FILE" = "seeds_production.rb" ]; then
    log_info "   Mode: Seed minimaliste (Rôles + SuperAdmin uniquement)"
else
    log_warning "⚠️  ⚠️  ⚠️  ATTENTION : Seed complet avec données de test ⚠️  ⚠️  ⚠️"
    log_warning "Assurez-vous que c'est bien ce que vous voulez faire !"
    read -p "Confirmez le seed complet en PRODUCTION ? (tapez 'OUI' en majuscules) : " seed_confirmation || seed_confirmation=""
    if [ "$seed_confirmation" != "OUI" ]; then
        log_info "Seed annulé"
        exit 0
    fi
fi

# Exécuter le seed avec le fichier spécifique
if [ "$USE_SEEDS_FILE" = "seeds_production.rb" ]; then
    # Seed production via runner (car Rails ne charge pas seeds_production.rb par défaut)
    if docker exec "$CONTAINER_NAME" bin/rails runner "load Rails.root.join('db', 'seeds_production.rb')" 2>&1 | tee -a /tmp/init-db-prod.log; then
        log_success "✅ Seed production terminé avec succès"
    else
        log_error "❌ Échec du seed production"
        log_error "Consultez les logs ci-dessus pour plus de détails"
        exit 1
    fi
else
    # Seed complet via db:seed standard
    if docker exec "$CONTAINER_NAME" bin/rails db:seed 2>&1 | tee -a /tmp/init-db-prod.log; then
        log_success "✅ Seed terminé avec succès"
    else
        log_error "❌ Échec du seed"
        log_error "Consultez les logs ci-dessus pour plus de détails"
        exit 1
    fi
fi

# Vérifier le résultat
ROLE_COUNT=$(docker exec "$CONTAINER_NAME" bin/rails runner "puts Role.count" 2>/dev/null | tr -d '\n\r' || echo "0")
USER_COUNT=$(docker exec "$CONTAINER_NAME" bin/rails runner "puts User.count" 2>/dev/null | tr -d '\n\r' || echo "0")
log_info "📊 Résultat:"
log_info "   - Rôles: ${ROLE_COUNT}"
log_info "   - Utilisateurs: ${USER_COUNT}"

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "✅ INITIALISATION TERMINÉE"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

