#!/bin/bash
# Script de déploiement automatique PRODUCTION
# Usage: ./ops/production/deploy.sh
# Auto-configuré pour l'environnement PRODUCTION

set -euo pipefail  # Mode strict : erreur, variable non définie, pipefail

# Configuration PRODUCTION
ENV="production"
BRANCH="main"
PORT="3002"
CONTAINER_NAME="grenoble-roller-prod"
DB_CONTAINER="grenoble-roller-db-prod"
DB_NAME="grenoble_roller_production"
ROLLBACK_ENABLED=true

# Chemins (détection automatique depuis le dossier ops/production)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
BACKUP_DIR="${REPO_DIR}/backups/production"
LOG_FILE="${REPO_DIR}/logs/deploy-production.log"

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
    
    # Utiliser ${SLACK_WEBHOOK:-} pour éviter l'erreur "unbound variable" avec set -u
    if [ -n "${SLACK_WEBHOOK:-}" ]; then
        curl -X POST "${SLACK_WEBHOOK}" \
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
    
    # 🔍 Vérification critique : Migrations en attente même si Git est à jour
    # Ceci évite le drift DB/code non détecté (best practice DevOps production-grade)
    log "🔍 Vérification des migrations en attente..."
    if container_is_running "$CONTAINER_NAME"; then
        MIGRATION_STATUS=$(docker exec "$CONTAINER_NAME" bin/rails db:migrate:status 2>&1)
        PENDING_COUNT=$(echo "$MIGRATION_STATUS" | grep -c "^\s*down" || echo "0")
        PENDING_LIST=$(echo "$MIGRATION_STATUS" | grep "^\s*down" | sed 's/^\s*down\s*//' || echo "")
        
        if [ "$PENDING_COUNT" -gt 0 ]; then
            log_warning "⚠️  $PENDING_COUNT migration(s) en attente détectée(s)"
            if [ -n "$PENDING_LIST" ]; then
                log_warning "Migrations en attente :"
                echo "$PENDING_LIST" | while read -r migration; do
                    log_warning "  - $migration"
                done
            fi
            log "🔄 Continuation du déploiement pour exécuter les migrations..."
            # Ne pas exit, continuer vers la phase de migrations
        else
            log "✅ Aucune migration en attente - Base de données synchronisée"
            exit 0
        fi
    else
        log_warning "⚠️  Impossible de vérifier les migrations (conteneur non running)"
        log_info "Sortie sans vérification - les migrations seront vérifiées au prochain déploiement"
        exit 0
    fi
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
VOLUME_NAME="grenoble-roller-prod-data"
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
log "🗄️ Préparation des migrations..."

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

# 🔍 SAFEGUARD 1 : Analyse des migrations en attente pour détecter les migrations destructives
log "🔍 Analyse des migrations en attente pour détecter les risques..."
MIGRATION_STATUS=$(docker exec "${CONTAINER_NAME}" bin/rails db:migrate:status 2>&1)
PENDING_MIGRATIONS=$(echo "$MIGRATION_STATUS" | grep "^\s*down" || echo "")

if [ -n "$PENDING_MIGRATIONS" ]; then
    # Patterns destructifs étendus (couvre plus de cas Rails)
    DESTRUCTIVE_PATTERNS="Remove|Drop|Destroy|Delete|Truncate|Clear|Rename.*Column|Change.*Column.*Type"
    DESTRUCTIVE_MIGRATIONS=$(echo "$PENDING_MIGRATIONS" | grep -iE "$DESTRUCTIVE_PATTERNS" || echo "")
    
    if [ -n "$DESTRUCTIVE_MIGRATIONS" ]; then
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "⚠️  ⚠️  ⚠️  MIGRATIONS DESTRUCTIVES DÉTECTÉES ⚠️  ⚠️  ⚠️"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "Les migrations suivantes peuvent supprimer ou modifier définitivement des données :"
        echo "$DESTRUCTIVE_MIGRATIONS" | while read -r migration; do
            log_error "  🔴 $migration"
        done
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "🔴 PRODUCTION : Approbation manuelle requise"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "Action requise : Exécuter manuellement après vérification"
        log_error "Commande : docker exec ${CONTAINER_NAME} bin/rails db:migrate"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "Déploiement arrêté pour sécurité. Rollback du code..."
        rollback "$CURRENT_COMMIT"
        exit 1
    else
        log_success "✅ Aucune migration destructive détectée"
    fi
    
    # Détecter aussi les migrations de données (potentiellement longues)
    DATA_PATTERNS="find_each|update_all|destroy_all|\.each"
    DATA_MIGRATIONS=$(echo "$PENDING_MIGRATIONS" | grep -iE "$DATA_PATTERNS" || echo "")
    
    if [ -n "$DATA_MIGRATIONS" ]; then
        log_warning "⚠️  Migrations de données détectées (potentiellement longues) :"
        echo "$DATA_MIGRATIONS" | while read -r migration; do
            log_warning "  🟡 $migration"
        done
        log_warning "Ces migrations peuvent prendre du temps sur de gros volumes de données"
    fi
fi

# 🕐 SAFEGUARD 2 : Configuration du timeout pour les migrations
# Timeout : 10 minutes pour production (plus long car migrations peuvent être plus complexes)
MIGRATION_TIMEOUT=600  # 10 minutes en production

log "🕐 Timeout migration configuré : ${MIGRATION_TIMEOUT}s (${ENV})"

# Détecter la version de timeout pour gérer les codes de sortie correctement
TIMEOUT_CMD=""
TIMEOUT_EXIT_CODE=124  # GNU timeout par défaut

if command -v timeout > /dev/null 2>&1; then
    # Tester si c'est GNU timeout (Linux) ou BSD timeout (macOS)
    if timeout --version 2>&1 | grep -q "GNU\|coreutils"; then
        TIMEOUT_CMD="timeout"
        TIMEOUT_EXIT_CODE=124  # GNU timeout
    elif timeout 1 sleep 0 2>&1 | grep -q "usage"; then
        TIMEOUT_CMD="timeout"
        TIMEOUT_EXIT_CODE=143  # BSD timeout
    elif command -v gtimeout > /dev/null 2>&1; then
        # macOS avec coreutils installé
        TIMEOUT_CMD="gtimeout"
        TIMEOUT_EXIT_CODE=124
    else
        log_warning "⚠️  Version de timeout non reconnue, utilisation par défaut"
        TIMEOUT_CMD="timeout"
    fi
fi

# En production, utiliser db:migrate (ne JAMAIS utiliser db:reset qui supprime les données)
log "🗄️ Exécution des migrations (timeout: ${MIGRATION_TIMEOUT}s)..."
MIGRATION_START_TIME=$(date +%s)

# Utiliser timeout pour limiter la durée d'exécution
if [ -n "$TIMEOUT_CMD" ]; then
    MIGRATION_OUTPUT=$($TIMEOUT_CMD ${MIGRATION_TIMEOUT} docker exec "${CONTAINER_NAME}" bin/rails db:migrate 2>&1)
    MIGRATION_EXIT_CODE=$?
else
    # Fallback si timeout n'est pas disponible
    log_warning "⚠️  Commande 'timeout' non disponible, exécution sans timeout"
    MIGRATION_OUTPUT=$(docker exec "${CONTAINER_NAME}" bin/rails db:migrate 2>&1)
    MIGRATION_EXIT_CODE=$?
fi

MIGRATION_END_TIME=$(date +%s)
MIGRATION_DURATION=$((MIGRATION_END_TIME - MIGRATION_START_TIME))

echo "$MIGRATION_OUTPUT" | tee -a "$LOG_FILE"

# Vérifier si timeout a été déclenché (gérer codes 124, 143 ET 137)
if [ $MIGRATION_EXIT_CODE -eq 124 ] || [ $MIGRATION_EXIT_CODE -eq 143 ] || [ $MIGRATION_EXIT_CODE -eq 137 ]; then
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_error "⏱️  TIMEOUT : Migration a dépassé ${MIGRATION_TIMEOUT}s"
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_error "⚠️  RISQUE CRITIQUE : Migration partielle possible"
    log_error "La migration a peut-être été partiellement exécutée, vérifiez l'état de la DB"
    log_error "Durée réelle : ${MIGRATION_DURATION}s"
    log_error ""
    log_error "🔧 SOLUTIONS POSSIBLES :"
    log_error "  1. Vérifier l'état : docker exec ${CONTAINER_NAME} bin/rails db:migrate:status"
    log_error "  2. Si migration bloquée : redémarrer le conteneur DB"
    log_error "  3. Si migration partielle : restaurer backup puis corriger migration"
    log_error "  4. Augmenter timeout si migration légitime : MIGRATION_TIMEOUT=1200 (20min)"
    log_error ""
    log_error "Action : Rollback du code et vérification manuelle immédiate de la DB"
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    show_container_logs "$CONTAINER_NAME" 50
    rollback "$CURRENT_COMMIT"
    exit 1
fi

if [ $MIGRATION_EXIT_CODE -ne 0 ]; then
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_error "❌ Échec des migrations (durée: ${MIGRATION_DURATION}s)"
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Détecter les erreurs spécifiques
    if echo "$MIGRATION_OUTPUT" | grep -q "does not exist\|UndefinedTable"; then
        log_error "⚠️ ERREUR CRITIQUE DÉTECTÉE : Table manquante lors d'une migration"
        log_error "Cela indique probablement un problème d'ORDRE DES MIGRATIONS"
        log_error "Vérifiez que les migrations créant les tables sont exécutées AVANT celles qui les modifient"
        log_error "Action requise : Corriger l'ordre des migrations avant de redéployer"
    fi
    
    if echo "$MIGRATION_OUTPUT" | grep -qi "lock\|deadlock\|timeout"; then
        log_error "⚠️ ERREUR CRITIQUE DÉTECTÉE : Verrouillage de base de données"
        log_error "La migration a peut-être causé un lock sur une table en production"
        log_error "Vérifiez les processus PostgreSQL en cours et les locks actifs"
        log_error "Commande : docker exec ${DB_CONTAINER} psql -U postgres -c \"SELECT * FROM pg_locks WHERE NOT granted;\""
    fi
    
    show_container_logs "$CONTAINER_NAME" 50
    
    # Vérifier l'état du conteneur après l'échec
    if ! container_is_running "$CONTAINER_NAME"; then
        log_error "Le conteneur s'est arrêté pendant les migrations"
        log_info "État du conteneur après échec :"
        docker ps -a --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.State}}" | tee -a "$LOG_FILE" || true
    fi
    
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_error "Rollback du code en cours..."
    rollback "$CURRENT_COMMIT"
    exit 1
fi

# Migration réussie
log_success "✅ Migrations exécutées avec succès (durée: ${MIGRATION_DURATION}s)"

# ✅ SAFEGUARD 3 : Vérification post-migration (pas de pending restant)
log "🔍 Vérification post-migration..."
POST_MIGRATION_STATUS=$(docker exec "${CONTAINER_NAME}" bin/rails db:migrate:status 2>&1)
POST_PENDING_COUNT=$(echo "$POST_MIGRATION_STATUS" | grep -c "^\s*down" || echo "0")

if [ "$POST_PENDING_COUNT" -gt 0 ]; then
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_error "⚠️  ANOMALIE : $POST_PENDING_COUNT migration(s) encore en attente après db:migrate"
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$POST_MIGRATION_STATUS" | grep "^\s*down" | while read -r migration; do
        log_error "  🔴 $migration"
    done
    log_error "Cela indique probablement une migration échouée silencieusement"
    log_error "Vérifiez manuellement : docker exec ${CONTAINER_NAME} bin/rails db:migrate:status"
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    show_container_logs "$CONTAINER_NAME" 100
    rollback "$CURRENT_COMMIT"
    exit 1
fi

log_success "✅ Toutes les migrations ont été appliquées correctement"

# Log performance pour monitoring
if [ "$MIGRATION_DURATION" -gt 60 ]; then
    log_warning "⚠️  Migration longue détectée : ${MIGRATION_DURATION}s (> 1min)"
    log_warning "Considérez l'optimisation de cette migration pour éviter les locks en prod"
elif [ "$MIGRATION_DURATION" -gt 300 ]; then
    log_error "🔴 Migration TRÈS longue : ${MIGRATION_DURATION}s (> 5min)"
    log_error "Cette migration causerait un downtime significatif en production"
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

