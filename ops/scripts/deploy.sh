#!/bin/bash
# Script de déploiement automatique local
# Usage: ./ops/scripts/deploy.sh dev|staging|production

set -e

ENV=${1:-staging}
COMPOSE_FILE="ops/${ENV}/docker-compose.yml"
BACKUP_DIR="/backups/${ENV}"
LOG_FILE="/var/log/grenoble-roller/deploy-${ENV}.log"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Configuration par environnement
case "$ENV" in
  dev)
    BRANCH="Dev"
    PORT="3000"
    CONTAINER_NAME="grenoble-roller-dev"
    DB_CONTAINER="grenoble-roller-db-dev"
    DB_NAME="grenoble_roller_development"
    ROLLBACK_ENABLED=false
    ;;
  staging)
    BRANCH="staging"
    PORT="3001"
    CONTAINER_NAME="grenoble-roller-staging"
    DB_CONTAINER="grenoble-roller-db-staging"
    DB_NAME="grenoble_roller_production"
    ROLLBACK_ENABLED=true
    ;;
  production)
    BRANCH="main"
    PORT="3002"
    CONTAINER_NAME="grenoble-roller-prod"
    DB_CONTAINER="grenoble-roller-db-prod"
    DB_NAME="grenoble_roller_production"
    ROLLBACK_ENABLED=true
    ;;
  *)
    echo "❌ Environnement invalide: $ENV (dev|staging|production)"
    exit 1
    ;;
esac

# Couleurs pour logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}" | tee -a "$LOG_FILE"
}

# Notification Slack (optionnel)
notify_slack() {
    local status=$1
    local message=$2
    
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST "$SLACK_WEBHOOK" \
            -H 'Content-type: application/json' \
            -d "{\"text\":\"[${ENV}] ${status}: ${message}\"}" \
            --silent --show-error > /dev/null 2>&1 || true
    fi
}

# Vérifier qu'on est dans le bon répertoire
cd "$REPO_DIR" || exit 1

if [ ! -f "$COMPOSE_FILE" ]; then
    log_error "Fichier $COMPOSE_FILE introuvable. Êtes-vous dans le bon répertoire ?"
    exit 1
fi

# Créer les dossiers nécessaires
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Charger les variables d'environnement du serveur (optionnel)
if [ -f "${REPO_DIR}/.env.server" ]; then
    source "${REPO_DIR}/.env.server"
fi

# Séparateur de log
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🚀 DEPLOYMENT START - ${ENV} - $(date '+%Y-%m-%d %H:%M:%S')"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Vérifier s'il y a des mises à jour
log "📥 Vérification des mises à jour (branche: ${BRANCH})..."
git fetch origin

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/${BRANCH}" 2>/dev/null || echo "$LOCAL")

if [ "$LOCAL" = "$REMOTE" ]; then
    log "✅ Déjà à jour (commit: ${LOCAL:0:7})"
    exit 0
fi

log "🆕 Nouvelle version détectée (${LOCAL:0:7} → ${REMOTE:0:7})"

# 2. Backup base de données
log "📦 Backup base de données..."
DB_BACKUP="${BACKUP_DIR}/db_$(date +%Y%m%d_%H%M%S).sql"
if docker exec "${DB_CONTAINER}" pg_dump -U postgres "${DB_NAME}" > "$DB_BACKUP" 2>/dev/null; then
    log_success "Backup DB créé: $DB_BACKUP"
    # Garder seulement les 20 derniers backups
    ls -t "${BACKUP_DIR}"/db_*.sql 2>/dev/null | tail -n +21 | xargs rm -f 2>/dev/null || true
else
    log_error "Échec du backup DB"
    exit 1
fi

# 3. Backup volumes (optionnel)
log "📦 Backup volumes..."
VOLUME_NAME="grenoble-roller-${ENV}-data"
VOLUME_BACKUP="${BACKUP_DIR}/volumes_$(date +%Y%m%d_%H%M%S).tar.gz"
if docker run --rm \
    -v "${VOLUME_NAME}:/data:ro" \
    -v "$BACKUP_DIR":/backup \
    alpine tar czf "/backup/volumes_$(date +%Y%m%d_%H%M%S).tar.gz" -C /data . 2>/dev/null; then
    log_success "Backup volumes créé"
    ls -t "${BACKUP_DIR}"/volumes_*.tar.gz 2>/dev/null | tail -n +21 | xargs rm -f 2>/dev/null || true
else
    log "⚠️ Backup volumes échoué (non critique)"
fi

# 4. Sauvegarder le commit actuel (pour rollback)
CURRENT_COMMIT=$(git rev-parse HEAD)
log "💾 Commit actuel sauvegardé: ${CURRENT_COMMIT:0:7}"

# 5. Git pull
log "📥 Mise à jour du code..."
if ! git checkout "$BRANCH" && git pull origin "$BRANCH"; then
    log_error "Échec du git pull"
    exit 1
fi

# 6. Build et restart
log "🔨 Build et redémarrage..."
if ! docker compose -f "$COMPOSE_FILE" up -d --build; then
    log_error "Échec du build/restart"
    if [ "$ROLLBACK_ENABLED" = true ]; then
        log "🔄 Rollback..."
        git checkout "$CURRENT_COMMIT"
        docker compose -f "$COMPOSE_FILE" up -d --build
    else
        log "⚠️ Rollback désactivé en dev - laissez le conteneur en erreur pour debug"
    fi
    exit 1
fi

# 7. Attendre que le conteneur démarre
log "⏳ Attente du démarrage du conteneur..."
sleep 15

# 8. Migrations
log "🗄️ Exécution des migrations..."
if ! docker exec "${CONTAINER_NAME}" bin/rails db:migrate; then
    log_error "Échec des migrations"
    if [ "$ROLLBACK_ENABLED" = true ]; then
        log "🔄 Rollback..."
        git checkout "$CURRENT_COMMIT"
        docker compose -f "$COMPOSE_FILE" up -d --build
    else
        log "⚠️ Rollback désactivé en dev - laissez le conteneur en erreur pour debug"
    fi
    exit 1
fi

# 9. Health check
log "🏥 Health check (port: ${PORT})..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f "http://localhost:${PORT}/up" > /dev/null 2>&1; then
        log_success "Health check réussi !"
        log_success "✅ Déploiement ${ENV} terminé avec succès (commit: ${REMOTE:0:7})"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "✅ DEPLOYMENT SUCCESS"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        notify_slack "✅" "Deployment successful (commit: ${REMOTE:0:7})"
        exit 0
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    log "⏳ Tentative $RETRY_COUNT/$MAX_RETRIES..."
    sleep 2
done

# 10. Rollback si health check échoue (uniquement si activé)
log_error "Health check échoué après $MAX_RETRIES tentatives"

if [ "$ROLLBACK_ENABLED" = true ]; then
    log "🔄 Rollback vers commit ${CURRENT_COMMIT:0:7}..."
    
    git checkout "$CURRENT_COMMIT"
    docker compose -f "$COMPOSE_FILE" up -d --build
    
    # Restaurer la DB si nécessaire
    log "📦 Restauration de la base de données..."
    LATEST_BACKUP=$(ls -t "${BACKUP_DIR}"/db_*.sql 2>/dev/null | head -1)
    if [ -f "$LATEST_BACKUP" ]; then
        cat "$LATEST_BACKUP" | docker exec -i "${DB_CONTAINER}" psql -U postgres "${DB_NAME}"
        log_success "Base de données restaurée"
    fi
    
    log_error "Rollback effectué - Déploiement échoué"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "❌ DEPLOYMENT FAILED - ROLLBACK EXECUTED"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    notify_slack "❌" "Deployment failed - rollback executed (commit: ${CURRENT_COMMIT:0:7})"
else
    log "⚠️ Rollback désactivé en dev - laissez le conteneur en erreur pour debug"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "❌ DEPLOYMENT FAILED - NO ROLLBACK (dev environment)"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    notify_slack "❌" "Deployment failed in dev - no rollback (commit: ${CURRENT_COMMIT:0:7})"
fi
exit 1

