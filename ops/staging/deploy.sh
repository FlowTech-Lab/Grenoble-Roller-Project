#!/bin/bash
# Script de déploiement automatique STAGING
# Usage: ./ops/staging/deploy.sh
# Auto-configuré pour l'environnement STAGING

set -euo pipefail  # Mode strict : erreur, variable non définie, pipefail

# Configuration STAGING
ENV="staging"
BRANCH="staging"
PORT="3001"
CONTAINER_NAME="grenoble-roller-staging"
DB_CONTAINER="grenoble-roller-db-staging"
DB_NAME="grenoble_roller_production"
ROLLBACK_ENABLED=true

# Chemins (détection automatique depuis le dossier ops/staging)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
BACKUP_DIR="${REPO_DIR}/backups/staging"
LOG_FILE="${REPO_DIR}/logs/deploy-staging.log"

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

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a "$LOG_FILE"
}

# Fonction pour vérifier l'état d'un conteneur
container_is_running() {
    local container_name=$1
    docker ps --format '{{.Names}}' | grep -q "^${container_name}$" 2>/dev/null || return 1
}

container_is_healthy() {
    local container_name=$1
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "none")
    [ "$health_status" = "healthy" ]
}

# Fonction pour attendre qu'un conteneur soit running
wait_for_container_running() {
    local container_name=$1
    local max_wait=${2:-60}  # 60 secondes par défaut
    local wait_time=0
    local stable_time=0
    local stable_required=5  # Le conteneur doit rester running pendant 5 secondes
    
    log_info "Attente que le conteneur ${container_name} soit running..."
    
    while [ $wait_time -lt $max_wait ]; do
        if container_is_running "$container_name"; then
            stable_time=$((stable_time + 2))
            if [ $stable_time -ge $stable_required ]; then
                log_success "Conteneur ${container_name} est running et stable (${stable_time}s)"
                return 0
            fi
            log_info "Conteneur running, vérification stabilité... (${stable_time}s/${stable_required}s)"
        else
            # Le conteneur s'est arrêté, réinitialiser le compteur
            if [ $stable_time -gt 0 ]; then
                log_warning "Le conteneur ${container_name} s'est arrêté après avoir démarré (était stable ${stable_time}s)"
                show_container_logs "$container_name" 30
            fi
            stable_time=0
        fi
        sleep 2
        wait_time=$((wait_time + 2))
        log_info "Attente... (${wait_time}s/${max_wait}s)"
    done
    
    log_error "Timeout : le conteneur ${container_name} n'est pas running après ${max_wait}s"
    # Afficher les logs si le conteneur existe mais n'est pas running
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$" 2>/dev/null; then
        show_container_logs "$container_name" 50
    fi
    return 1
}

# Fonction pour attendre qu'un conteneur soit healthy
wait_for_container_healthy() {
    local container_name=$1
    local max_wait=${2:-120}  # 120 secondes par défaut
    local wait_time=0
    
    log_info "Attente que le conteneur ${container_name} soit healthy..."
    
    while [ $wait_time -lt $max_wait ]; do
        if container_is_healthy "$container_name"; then
            log_success "Conteneur ${container_name} est healthy"
            return 0
        fi
        
        # Vérifier si le conteneur est toujours running
        if ! container_is_running "$container_name"; then
            log_error "Le conteneur ${container_name} s'est arrêté"
            return 1
        fi
        
        sleep 5
        wait_time=$((wait_time + 5))
        log_info "Attente healthcheck... (${wait_time}s/${max_wait}s)"
    done
    
    log_error "Timeout : le conteneur ${container_name} n'est pas healthy après ${max_wait}s"
    return 1
}

# Fonction pour afficher les logs d'un conteneur en cas d'erreur
show_container_logs() {
    local container_name=$1
    local lines=${2:-50}
    
    log_error "=== Dernières ${lines} lignes des logs de ${container_name} ==="
    docker logs --tail "$lines" "$container_name" 2>&1 | tee -a "$LOG_FILE" || true
    log_error "=== Fin des logs ==="
}

# Fonction de rollback
rollback() {
    local current_commit=$1
    log_warning "🔄 Début du rollback vers commit ${current_commit:0:7}..."
    
    # Restaurer le code
    if git checkout "$current_commit" 2>/dev/null; then
        log_info "Code restauré vers ${current_commit:0:7}"
    else
        log_error "Échec du checkout vers ${current_commit:0:7}"
    fi
    
    # Rebuild et restart
    log_info "Rebuild et restart avec l'ancienne version..."
    if docker compose -f "$COMPOSE_FILE" up -d --build; then
        log_info "Conteneurs redémarrés"
    else
        log_error "Échec du rebuild/restart lors du rollback"
    fi
    
    # Restaurer la DB si nécessaire
    log_info "📦 Restauration de la base de données..."
    LATEST_BACKUP=$(ls -t "${BACKUP_DIR}"/db_*.sql 2>/dev/null | head -1)
    if [ -n "$LATEST_BACKUP" ] && [ -f "$LATEST_BACKUP" ]; then
        if container_is_running "$DB_CONTAINER"; then
            if cat "$LATEST_BACKUP" | docker exec -i "${DB_CONTAINER}" psql -U postgres "${DB_NAME}" 2>/dev/null; then
                log_success "Base de données restaurée"
            else
                log_error "Échec de la restauration de la base de données"
            fi
        else
            log_warning "Le conteneur DB n'est pas running, impossible de restaurer"
        fi
    else
        log_warning "Aucun backup DB trouvé pour restauration"
    fi
    
    log_error "Rollback terminé - Déploiement échoué"
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

# Aller dans le répertoire du projet
cd "$REPO_DIR" || exit 1

# Créer automatiquement les dossiers nécessaires
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Charger les variables d'environnement du serveur (optionnel)
if [ -f "${REPO_DIR}/.env.server" ]; then
    source "${REPO_DIR}/.env.server"
fi

# Vérifier qu'on est sur la bonne branche
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
    log "⚠️ Branche actuelle: ${CURRENT_BRANCH}, passage sur ${BRANCH}..."
    git checkout "$BRANCH" || {
        log_error "Impossible de passer sur la branche ${BRANCH}"
        exit 1
    }
fi

# Vérifier l'accès Git
if ! git fetch origin > /dev/null 2>&1; then
    log_error "Impossible d'accéder à GitHub. Vérifiez votre configuration SSH/HTTPS."
    log_error "Pour configurer SSH: ssh-keygen -t ed25519 -f ~/.ssh/github_deploy -N \"\""
    exit 1
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
VOLUME_NAME="grenoble-roller-staging-data"
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
if ! git pull origin "$BRANCH"; then
    log_error "Échec du git pull"
    exit 1
fi

# 6. Build et restart
log "🔨 Build et redémarrage..."
if ! docker compose -f "$COMPOSE_FILE" up -d --build; then
    log_error "Échec du build/restart"
    rollback "$CURRENT_COMMIT"
    exit 1
fi

# 7. Attendre que le conteneur web démarre
log "⏳ Attente du démarrage du conteneur..."
if ! wait_for_container_running "$CONTAINER_NAME" 60; then
    log_error "Le conteneur web n'a pas démarré"
    show_container_logs "$CONTAINER_NAME"
    rollback "$CURRENT_COMMIT"
    exit 1
fi

# 8. Attendre que le conteneur soit healthy (si healthcheck configuré)
if docker inspect --format='{{.State.Health}}' "$CONTAINER_NAME" 2>/dev/null | grep -q "Status"; then
    if ! wait_for_container_healthy "$CONTAINER_NAME" 120; then
        log_error "Le conteneur web n'est pas devenu healthy"
        show_container_logs "$CONTAINER_NAME"
        rollback "$CURRENT_COMMIT"
        exit 1
    fi
else
    log_info "Pas de healthcheck configuré, attente supplémentaire de 10s avec vérification continue..."
    for i in {1..10}; do
        if ! container_is_running "$CONTAINER_NAME"; then
            log_error "Le conteneur web s'est arrêté pendant l'attente"
            show_container_logs "$CONTAINER_NAME"
            rollback "$CURRENT_COMMIT"
            exit 1
        fi
        sleep 1
    done
fi

# 9. Vérifier que le conteneur est toujours running avant migrations
if ! container_is_running "$CONTAINER_NAME"; then
    log_error "Le conteneur web s'est arrêté avant les migrations"
    show_container_logs "$CONTAINER_NAME"
    rollback "$CURRENT_COMMIT"
    exit 1
fi

# 10. Migrations - Vérification finale avant exécution
log "🗄️ Exécution des migrations..."
# Double vérification juste avant l'exécution
if ! container_is_running "$CONTAINER_NAME"; then
    log_error "Le conteneur web s'est arrêté juste avant les migrations"
    show_container_logs "$CONTAINER_NAME"
    rollback "$CURRENT_COMMIT"
    exit 1
fi

# Afficher les logs récents pour debug
log_info "État du conteneur avant migrations :"
docker ps -a --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.State}}" | tee -a "$LOG_FILE" || true

if ! docker exec "${CONTAINER_NAME}" bin/rails db:migrate; then
    log_error "Échec des migrations"
    show_container_logs "$CONTAINER_NAME"
    # Vérifier l'état du conteneur après l'échec
    if ! container_is_running "$CONTAINER_NAME"; then
        log_error "Le conteneur s'est arrêté pendant les migrations"
        log_info "État du conteneur après échec :"
        docker ps -a --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.State}}" | tee -a "$LOG_FILE" || true
    fi
    rollback "$CURRENT_COMMIT"
    exit 1
fi

# 11. Health check HTTP (double vérification)
log "🏥 Health check HTTP (port: ${PORT})..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f "http://localhost:${PORT}/up" > /dev/null 2>&1; then
        log_success "Health check HTTP réussi !"
        log_success "✅ Déploiement ${ENV} terminé avec succès (commit: ${REMOTE:0:7})"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "✅ DEPLOYMENT SUCCESS"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        notify_slack "✅" "Deployment successful (commit: ${REMOTE:0:7})"
        exit 0
    fi
    
    # Vérifier que le conteneur est toujours running
    if ! container_is_running "$CONTAINER_NAME"; then
        log_error "Le conteneur web s'est arrêté pendant le health check"
        show_container_logs "$CONTAINER_NAME"
        rollback "$CURRENT_COMMIT"
        exit 1
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    log_info "Tentative health check HTTP $RETRY_COUNT/$MAX_RETRIES..."
    sleep 2
done

# 12. Rollback si health check échoue
log_error "Health check HTTP échoué après $MAX_RETRIES tentatives"
show_container_logs "$CONTAINER_NAME"
rollback "$CURRENT_COMMIT"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "❌ DEPLOYMENT FAILED - ROLLBACK EXECUTED"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
notify_slack "❌" "Deployment failed - rollback executed (commit: ${CURRENT_COMMIT:0:7})"
exit 1

