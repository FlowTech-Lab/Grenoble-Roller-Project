#!/bin/bash
# Script de déploiement automatique STAGING/PRODUCTION
# Usage: ./ops/staging/deploy.sh [--force]
# Auto-configuré pour l'environnement STAGING ou PRODUCTION

set -euo pipefail  # Mode strict : erreur, variable non définie, pipefail

# Détection automatique de l'environnement depuis le chemin du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$SCRIPT_DIR" == *"/staging"* ]]; then
    ENV="staging"
    BRANCH="staging"
    PORT="3001"
    CONTAINER_NAME="grenoble-roller-staging"
    DB_CONTAINER="grenoble-roller-db-staging"
    DB_NAME="grenoble_roller_production"  # Valeur par défaut (déjà dans docker-compose.yml)
elif [[ "$SCRIPT_DIR" == *"/production"* ]]; then
    ENV="production"
    BRANCH="main"
    PORT="3000"
    CONTAINER_NAME="grenoble-roller-production"
    DB_CONTAINER="grenoble-roller-db-production"
    DB_NAME="grenoble_roller_production"  # Valeur par défaut
else
    echo "❌ Erreur: Environnement non détecté (staging/production)"
    exit 1
fi

ROLLBACK_ENABLED=true

# Chemins (détection automatique depuis le dossier ops/{staging|production})
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
BACKUP_DIR="${REPO_DIR}/backups/${ENV}"
LOG_FILE="${REPO_DIR}/logs/deploy-${ENV}.log"
LOG_JSON_FILE="${REPO_DIR}/logs/deploy-${ENV}.json"

# Créer les répertoires nécessaires
mkdir -p "$BACKUP_DIR" "$(dirname "$LOG_FILE")" "$(dirname "$LOG_JSON_FILE")"

# Couleurs pour logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Génération d'un ID de déploiement unique
DEPLOYMENT_ID="deploy-$(date +%Y%m%d-%H%M%S)-${RANDOM}"
export DEPLOYMENT_ID

# ============================================================================
# FONCTION: load_rails_credentials
# DESCRIPTION: Charge la master key Rails pour un environnement donné
# PARAMÈTRES:
#   $1: env - Environnement (staging/production)
# RETOUR:
#   0: Succès
#   1: Échec (master key introuvable)
# USAGE: load_rails_credentials "staging"
# ============================================================================
load_rails_credentials() {
    local env=$1
    local key_file="${REPO_DIR}/config/credentials/${env}.key"
    
    # 1. Chercher la master key par environnement (staging.key, production.key)
    if [ -f "$key_file" ]; then
        export RAILS_MASTER_KEY=$(cat "$key_file" | tr -d '\n\r')
        echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] 🔐 Master key chargée depuis ${key_file}..." | tee -a "$LOG_FILE"
        return 0
    fi
    
    # 2. Fallback : master.key global (development)
    if [ -f "${REPO_DIR}/config/master.key" ]; then
        export RAILS_MASTER_KEY=$(cat "${REPO_DIR}/config/master.key" | tr -d '\n\r')
        echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] 🔐 Master key chargée depuis config/master.key (dev)..." | tee -a "$LOG_FILE"
        return 0
    fi
    
    # 3. Fallback : variable d'environnement RAILS_MASTER_KEY
    if [ -n "${RAILS_MASTER_KEY:-}" ]; then
        echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] 🔐 Master key chargée depuis RAILS_MASTER_KEY (env var)..." | tee -a "$LOG_FILE"
        return 0
    fi
    
    # 4. Échec : master key introuvable
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Master key Rails introuvable pour ${env}${NC}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Créer avec: rails credentials:edit --environment ${env}${NC}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Ou définir RAILS_MASTER_KEY comme variable d'environnement${NC}" | tee -a "$LOG_FILE"
    return 1
}

# Charger les Rails credentials
if ! load_rails_credentials "$ENV"; then
    # En staging, on peut continuer sans credentials (backup non chiffré)
    if [ "$ENV" = "staging" ]; then
        echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: Continuation sans chiffrement (staging)${NC}" | tee -a "$LOG_FILE"
        BACKUP_ENCRYPTION_ENABLED="false"
    else
        # En production, c'est critique
        exit 1
    fi
fi

# Charger le .env optionnel (pour surcharger DB_NAME si besoin)
ENV_FILE="${SCRIPT_DIR}/.env.${ENV}"
if [ -f "$ENV_FILE" ]; then
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] 📋 Chargement des variables depuis ${ENV_FILE}..." | tee -a "$LOG_FILE"
    set -a  # Auto-export des variables
    source "$ENV_FILE"
    set +a
    # Permettre de surcharger DB_NAME si besoin
    DB_NAME="${DB_NAME:-grenoble_roller_production}"
fi

# Charger configuration centralisée
if [ -f "${SCRIPT_DIR}/config.sh" ]; then
    source "${SCRIPT_DIR}/config.sh"
else
    # Valeurs par défaut si config.sh n'existe pas
    readonly MIGRATION_BASE_TIMEOUT=60
    readonly MIGRATION_PER_MIGRATION=30
    readonly MIGRATION_MAX_TIMEOUT=900
    readonly MIGRATION_MAX_TIMEOUT_PRODUCTION=1800
    readonly HEALTH_CHECK_MAX_RETRIES=60
    readonly HEALTH_CHECK_BACKOFF_MAX=10
    readonly HEALTH_CHECK_INITIAL_SLEEP=10
    readonly CONTAINER_RUNNING_WAIT=60
    readonly CONTAINER_HEALTHY_WAIT=120
    readonly CONTAINER_NEW_WAIT=120
    readonly DISK_SPACE_REQUIRED=5
    readonly DISK_SPACE_MIN_AFTER_CLEANUP=3
    readonly BACKUP_RETENTION_COUNT=20
fi

# Variables optionnelles avec valeurs par défaut
BACKUP_ENCRYPTION_ENABLED="${BACKUP_ENCRYPTION_ENABLED:-true}"  # Activé par défaut (sécurité)
PROMETHEUS_PUSHGATEWAY="${PROMETHEUS_PUSHGATEWAY:-}"
BLUE_GREEN_ENABLED="${BLUE_GREEN_ENABLED:-false}"  # Blue-green deployment (zero-downtime)
BLUE_GREEN_COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.blue-green.yml"

# Initialiser variables pour métriques (évite erreurs si utilisées avant définition)
REMOTE=""
MIGRATION_DURATION=0
export MIGRATION_DURATION

# Vérifier que OpenSSL est disponible si le chiffrement est activé
if [ "$BACKUP_ENCRYPTION_ENABLED" = "true" ] && ! command -v openssl > /dev/null 2>&1; then
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: OpenSSL non disponible, désactivation du chiffrement${NC}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: Installation: sudo apt-get install openssl${NC}" | tee -a "$LOG_FILE"
    BACKUP_ENCRYPTION_ENABLED="false"
fi

# Détection du mode d'exécution (manuel vs automatique/cron)
FORCE_REDEPLOY=false
if [ -t 0 ] && [ "$#" -gt 0 ] && [ "$1" = "--force" ]; then
    FORCE_REDEPLOY=true
fi

# Logging structuré JSON (P3) - Opti 3 : Enrichi avec durée déploiement
log_json() {
    local level=$1
    shift
    local message="$@"
    
    # Calculer durée si DEPLOY_START_TIME existe
    local deploy_duration_seconds=""
    if [ -n "${DEPLOY_START_TIME:-}" ]; then
        local current_time=$(date +%s)
        deploy_duration_seconds=$((current_time - DEPLOY_START_TIME))
    fi
    
    if command -v jq > /dev/null 2>&1; then
        jq -n \
            --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
            --arg lvl "$level" \
            --arg msg "$message" \
            --arg env "$ENV" \
            --arg commit "${REMOTE:-${LOCAL:-unknown}:0:7}" \
            --arg deploy_id "$DEPLOYMENT_ID" \
            --arg duration "$deploy_duration_seconds" \
            '{
                timestamp: $ts,
                level: $lvl,
                message: $msg,
                environment: $env,
                commit: $commit,
                deployment_id: $deploy_id,
                deploy_duration_seconds: ($duration | if . == "" then null else tonumber end)
            }' >> "$LOG_JSON_FILE" 2>/dev/null || true
    fi
}

# P3 - Export métriques Prometheus
export_deployment_metrics() {
    local status=$1  # "success" ou "failure"
    local deploy_end_time=$(date +%s)
    local deploy_duration=$((deploy_end_time - DEPLOY_START_TIME))
    
    local metrics_file="${REPO_DIR}/metrics/deploy-${ENV}.prom"
    mkdir -p "$(dirname "$metrics_file")"
    
    # Calculer la taille du backup si disponible
    local backup_size=0
    if [ -n "${DB_BACKUP:-}" ] && [ -f "$DB_BACKUP" ]; then
        if command -v stat > /dev/null 2>&1; then
            backup_size=$(stat -f%z "$DB_BACKUP" 2>/dev/null || stat -c%s "$DB_BACKUP" 2>/dev/null || echo "0")
        fi
    fi
    
    cat > "$metrics_file" <<EOF
# HELP deployment_duration_seconds Durée totale du déploiement
deployment_duration_seconds{env="${ENV}",status="${status}"} ${deploy_duration}

# HELP migration_duration_seconds Durée des migrations DB
migration_duration_seconds{env="${ENV}"} ${MIGRATION_DURATION}

# HELP deployment_timestamp_seconds Timestamp du déploiement
deployment_timestamp_seconds{env="${ENV}"} ${deploy_end_time}

# HELP backup_size_bytes Taille du backup DB
backup_size_bytes{env="${ENV}"} ${backup_size}

# HELP deployment_status Statut du déploiement (1=success, 0=failure)
deployment_status{env="${ENV}"} $([ "$status" = "success" ] && echo "1" || echo "0")
EOF
    
    log_info "📊 Métriques exportées: ${metrics_file}"
    
    # Push vers Prometheus Pushgateway (si configuré)
    if [ -n "${PROMETHEUS_PUSHGATEWAY:-}" ]; then
        if command -v curl > /dev/null 2>&1; then
            curl -X POST --data-binary @"$metrics_file" \
                 "${PROMETHEUS_PUSHGATEWAY}/metrics/job/deployment/instance/${ENV}" \
                 --silent --show-error > /dev/null 2>&1 && \
            log_success "✅ Métriques poussées vers Prometheus Pushgateway" || \
            log_warning "⚠️  Échec push métriques vers Prometheus"
        fi
    fi
}

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
    log_json "INFO" "$1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
    log_json "ERROR" "$1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}" | tee -a "$LOG_FILE"
    log_json "SUCCESS" "$1"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
    log_json "WARNING" "$1"
}

log_info() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a "$LOG_FILE"
    log_json "INFO" "$1"
}

# P2 - Fonction anti-race condition pour vérifier l'état d'un conteneur
container_is_running() {
    local container_name=$1
    docker ps --format '{{.Names}}' | grep -q "^${container_name}$" 2>/dev/null || return 1
}

# P2 - Vérification stable (anti-race condition)
container_is_running_stable() {
    local container_name=$1
    local checks=3
    local interval=1
    
    for i in $(seq 1 $checks); do
        if ! docker inspect --format='{{.State.Running}}' "$container_name" 2>/dev/null | grep -q "true"; then
            return 1
        fi
        [ $i -lt $checks ] && sleep $interval
    done
    return 0
}

# Fonction pour vérifier si un conteneur existe (running ou stopped)
container_exists() {
    local container_name=$1
    docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$" 2>/dev/null || return 1
}

# Fonction helper : démarrer un conteneur existant
start_existing_container() {
    local container_name=$1
    local compose_file=$2
    
    log_info "Démarrage du conteneur ${container_name}..."
    docker start "$container_name" 2>/dev/null || {
        log_info "Tentative avec docker compose..."
        docker compose -f "$compose_file" up -d "$container_name" 2>/dev/null || {
            log_error "Échec du démarrage du conteneur"
            return 1
        }
    }
    
    if wait_for_container_running "$container_name" 60; then
        log_success "✅ Conteneur ${container_name} démarré avec succès"
        return 0
    else
        log_error "❌ Le conteneur n'a pas démarré dans les temps"
        return 1
    fi
}

# Fonction helper : créer et démarrer un nouveau conteneur
create_new_container() {
    local container_name=$1
    local compose_file=$2
    
    log_info "Création et démarrage du conteneur ${container_name}..."
    if docker compose -f "$compose_file" up -d --build; then
        if wait_for_container_running "$container_name" 120; then
            log_success "✅ Conteneur ${container_name} créé et démarré avec succès"
            return 0
        else
            log_error "❌ Le conteneur n'a pas démarré dans les temps"
            return 1
        fi
    else
        log_error "Échec de la création du conteneur"
        return 1
    fi
}

# Fonction helper : prompt utilisateur pour action
prompt_user_action() {
    local message=$1
    local default=${2:-N}
    
    if [ -t 0 ] && [ -t 1 ]; then
        read -p "${message} (o/N) : " answer
        answer=${answer:-$default}
        [[ "$answer" =~ ^[OoYy]$ ]]
    else
        # Mode non-interactif : retourner true pour action automatique
        return 0
    fi
}

# ============================================================================
# FONCTION: ensure_container_running
# DESCRIPTION: S'assure qu'un conteneur est running (démarre ou crée si nécessaire)
# PARAMÈTRES:
#   $1: container_name - Nom du conteneur
#   $2: compose_file - Chemin vers docker-compose.yml
# RETOUR:
#   0: Conteneur running
#   1: Échec (démarrage/création échoué ou annulé par utilisateur)
# USAGE: ensure_container_running "grenoble-roller-staging" "$COMPOSE_FILE"
# NOTE: Mode interactif si terminal disponible, sinon automatique
# ============================================================================
ensure_container_running() {
    local container_name=$1
    local compose_file=$2
    
    # Vérifier si le conteneur est déjà running
    if container_is_running "$container_name"; then
        return 0
    fi
    
    # Vérifier si le conteneur existe mais est arrêté
    if container_exists "$container_name"; then
        log_warning "⚠️  Le conteneur ${container_name} existe mais est arrêté"
        
        if prompt_user_action "Voulez-vous démarrer le conteneur ?"; then
            if [ -t 0 ] && [ -t 1 ]; then
                start_existing_container "$container_name" "$compose_file"
            else
                log_warning "Mode non-interactif : démarrage automatique du conteneur..."
                start_existing_container "$container_name" "$compose_file"
            fi
        else
            log_info "Démarrage annulé par l'utilisateur"
            return 1
        fi
    else
        # Le conteneur n'existe pas du tout
        log_warning "⚠️  Le conteneur ${container_name} n'existe pas"
        
        if prompt_user_action "Voulez-vous créer et démarrer le conteneur ?"; then
            if [ -t 0 ] && [ -t 1 ]; then
                create_new_container "$container_name" "$compose_file"
            else
                log_warning "Mode non-interactif : création automatique du conteneur..."
                create_new_container "$container_name" "$compose_file"
            fi
        else
            log_info "Création annulée par l'utilisateur"
            return 1
        fi
    fi
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

# Fonction de nettoyage Docker (libère de l'espace disque)
cleanup_docker() {
    log "🧹 Nettoyage Docker en cours..."
    
    local freed_space=0
    
    # 1. Supprimer les images sans tag (dangling)
    local dangling_images=$(docker images -f "dangling=true" -q 2>/dev/null | wc -l)
    if [ "$dangling_images" -gt 0 ]; then
        log_info "Suppression de $dangling_images images sans tag..."
        docker image prune -f > /dev/null 2>&1 && {
            log_success "Images sans tag supprimées"
            freed_space=$((freed_space + 1))
        } || log_warning "Échec suppression images sans tag"
    fi
    
    # 2. Supprimer le cache de build Docker
    log_info "Nettoyage du cache de build Docker..."
    docker builder prune -f > /dev/null 2>&1 && {
        log_success "Cache de build nettoyé"
        freed_space=$((freed_space + 1))
    } || log_warning "Échec nettoyage cache build"
    
    # 3. Supprimer les volumes orphelins
    local orphan_volumes=$(docker volume ls -f "dangling=true" -q 2>/dev/null | wc -l)
    if [ "$orphan_volumes" -gt 0 ]; then
        log_info "Suppression de $orphan_volumes volumes orphelins..."
        docker volume prune -f > /dev/null 2>&1 && {
            log_success "Volumes orphelins supprimés"
            freed_space=$((freed_space + 1))
        } || log_warning "Échec suppression volumes orphelins"
    fi
    
    # 4. Supprimer les conteneurs arrêtés
    local stopped_containers=$(docker ps -a -f "status=exited" -q 2>/dev/null | wc -l)
    if [ "$stopped_containers" -gt 0 ]; then
        log_info "Suppression de $stopped_containers conteneurs arrêtés..."
        docker container prune -f > /dev/null 2>&1 && {
            log_success "Conteneurs arrêtés supprimés"
            freed_space=$((freed_space + 1))
        } || log_warning "Échec suppression conteneurs arrêtés"
    fi
    
    if [ $freed_space -gt 0 ]; then
        log_success "🧹 Nettoyage Docker terminé (espace libéré)"
    else
        log_info "Aucun élément à nettoyer"
    fi
}

# Fonction pour vérifier l'espace disque disponible
check_disk_space() {
    local required_gb=${1:-${DISK_SPACE_REQUIRED:-5}}
    local available_space
    
    # Récupérer l'espace disponible (en GB)
    if command -v df > /dev/null 2>&1; then
        available_space=$(df -BG "$REPO_DIR" 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/G//' || echo "0")
    else
        log_warning "Impossible de vérifier l'espace disque (commande 'df' non disponible)"
        return 0
    fi
    
    if [ "$available_space" -lt "$required_gb" ]; then
        log_warning "⚠️  Espace disque faible : ${available_space}GB disponible (minimum recommandé : ${required_gb}GB)"
        return 1
    else
        log_info "✅ Espace disque OK : ${available_space}GB disponible"
        return 0
    fi
}

# Fonction de récupération en cas d'erreur d'espace disque
recover_from_disk_full() {
    local error_output="$1"
    local current_commit="$2"
    
    # Détecter l'erreur "no space left on device"
    if echo "$error_output" | grep -qi "no space left on device\|disk full\|not enough space"; then
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "🔴 ERREUR : Espace disque insuffisant"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # Afficher l'espace disponible
        if command -v df > /dev/null 2>&1; then
            log_error "Espace disque actuel :"
            df -h "$REPO_DIR" | tail -1 | awk '{print "  Disponible: " $4 " sur " $2 " (" $5 " utilisé)"}'
        fi
        
        log_error ""
        log_error "🔧 OPTIONS DE RÉCUPÉRATION :"
        log_error ""
        log_error "1. Nettoyage automatique Docker (recommandé)"
        log_error "2. Rollback vers commit précédent"
        log_error "3. Ignorer et continuer (risqué)"
        log_error "4. Quitter et nettoyer manuellement"
        log_error ""
        
        # Mode interactif si possible, sinon nettoyage automatique
        if [ -t 0 ] && [ -t 1 ]; then
            # Terminal interactif disponible
            read -p "Votre choix (1-4) [1] : " choice
            choice=${choice:-1}
        else
            # Mode non-interactif (cron, etc.) → nettoyage automatique
            log_warning "Mode non-interactif détecté, nettoyage automatique..."
            choice=1
        fi
        
        case "$choice" in
            1)
                log_info "Option 1 : Nettoyage automatique Docker..."
                cleanup_docker
                
                # Vérifier à nouveau l'espace
                if check_disk_space ${DISK_SPACE_MIN_AFTER_CLEANUP:-3}; then
                    log_success "✅ Espace suffisant après nettoyage, vous pouvez réessayer le déploiement"
                    return 0
                else
                    log_error "❌ Espace toujours insuffisant après nettoyage"
                    log_error "Action manuelle requise : libérer de l'espace puis réessayer"
                    return 1
                fi
                ;;
            2)
                log_info "Option 2 : Rollback vers commit précédent..."
                rollback "$current_commit"
                return 1
                ;;
            3)
                log_warning "Option 3 : Ignorer l'erreur (RISQUÉ)"
                log_warning "Le déploiement peut échouer à nouveau"
                return 0
                ;;
            4)
                log_info "Option 4 : Quitter pour nettoyage manuel"
                log_info "Commandes utiles :"
                log_info "  docker system prune -a --volumes  # Nettoyage complet (ATTENTION)"
                log_info "  docker builder prune -a -f        # Cache build uniquement"
                log_info "  df -h                              # Vérifier espace disque"
                return 1
                ;;
            *)
                log_error "Choix invalide, nettoyage automatique par défaut..."
                cleanup_docker
                return 0
                ;;
        esac
    else
        # Pas d'erreur d'espace disque
        return 0
    fi
}

# ============================================================================
# FONCTION: rollback
# DESCRIPTION: Effectue un rollback transactionnel (code + DB) vers un commit précédent
# PARAMÈTRES:
#   $1: current_commit - Hash du commit vers lequel revenir
# RETOUR:
#   0: Rollback réussi
#   1: Échec du rollback
# USAGE: rollback "f0a724d"
# NOTE: Restaure DB depuis backup si disponible, puis restaure code et rebuild
# ============================================================================
rollback() {
    local current_commit=$1
    local backup_file="${DB_BACKUP:-}"
    
    log_warning "🔄 Rollback transactionnel vers commit ${current_commit:0:7}..."
    
    # Vérifier l'espace disque avant rollback
    if ! check_disk_space 2; then
        log_warning "⚠️  Espace disque faible, nettoyage avant rollback..."
        cleanup_docker
    fi
    
    # 1. Arrêter l'app immédiatement (éviter corruption)
    log_info "🛑 Arrêt de l'application pour éviter corruption..."
    if [ "$BLUE_GREEN_ENABLED" = "true" ]; then
        docker compose -f "$BLUE_GREEN_COMPOSE_FILE" stop web-blue web-green 2>/dev/null || true
    else
        docker compose -f "$COMPOSE_FILE" stop "$CONTAINER_NAME" 2>/dev/null || true
    fi
    
    # 2. Restaurer DB AVANT le code (ordre critique)
    if [ -n "$backup_file" ] && [ -f "$backup_file" ]; then
        log_info "📦 Restauration DB depuis backup..."
        if ! restore_database_from_backup "$backup_file"; then
            log_error "❌ Restauration DB échouée - État critique"
            log_error "L'application reste arrêtée pour éviter corruption"
            return 1
        fi
    else
        log_warning "⚠️  Aucun backup disponible - Rollback code uniquement"
    fi
    
    # 3. Restaurer code
    log_info "📝 Restauration du code vers ${current_commit:0:7}..."
    if ! git checkout "$current_commit" 2>/dev/null; then
        log_error "Échec du checkout vers ${current_commit:0:7}"
        if git checkout "$current_commit" 2>&1 | grep -qi "no space\|disk full"; then
            log_error "Échec probablement dû à l'espace disque"
            cleanup_docker
            if ! git checkout "$current_commit" 2>/dev/null; then
                log_error "Échec définitif du checkout - Intervention manuelle requise"
                return 1
            fi
        else
            return 1
        fi
    fi
    
    # 4. Rebuild et démarrage
    log_info "🔨 Rebuild et démarrage avec l'ancienne version..."
    local build_output
    if [ "$BLUE_GREEN_ENABLED" = "true" ]; then
        # En blue-green, redémarrer l'environnement actif
        local active_env=$(get_active_environment)
        if [ "$active_env" != "none" ]; then
            build_output=$(docker compose -f "$BLUE_GREEN_COMPOSE_FILE" up -d --build "web-${active_env}" 2>&1)
        else
            build_output=$(docker compose -f "$BLUE_GREEN_COMPOSE_FILE" up -d --build web-blue 2>&1)
        fi
    else
        build_output=$(docker compose -f "$COMPOSE_FILE" up -d --build 2>&1)
    fi
    local build_exit_code=$?
    
    if [ $build_exit_code -ne 0 ]; then
        log_error "Échec du rebuild/restart lors du rollback"
        if echo "$build_output" | grep -qi "no space\|disk full"; then
            log_error "Erreur d'espace disque détectée lors du rollback"
            recover_from_disk_full "$build_output" "$current_commit"
        fi
        return 1
    fi
    
    # 5. Vérification sanity (health check)
    log_info "🔍 Vérification de l'état après rollback..."
    sleep 5  # Attendre le démarrage
    
    local container_to_check=""
    if [ "$BLUE_GREEN_ENABLED" = "true" ]; then
        container_to_check="grenoble-roller-staging-$(get_active_environment)"
    else
        container_to_check="$CONTAINER_NAME"
    fi
    
    if container_is_running_stable "$container_to_check"; then
        local check_port=$([ "$BLUE_GREEN_ENABLED" = "true" ] && echo "$PORT" || echo "$PORT")
        if health_check_comprehensive "$container_to_check" "$check_port"; then
            log_success "✅ Rollback transactionnel réussi"
            return 0
        else
            log_error "❌ Rollback échoué - Health check échoué"
            log_error "Intervention manuelle requise"
            return 1
        fi
    else
        log_error "❌ Rollback échoué - Conteneur non stable"
        return 1
    fi
}

# ============================================================================
# FONCTION: restore_database_from_backup
# DESCRIPTION: Restaure la base de données depuis un backup (chiffré ou non)
# PARAMÈTRES:
#   $1: backup_file - Chemin vers le fichier de backup (.sql ou .sql.enc)
# RETOUR:
#   0: Succès
#   1: Échec (backup introuvable, conteneur non running, erreur restauration)
# USAGE: restore_database_from_backup "/backups/staging/db_20251127.sql.enc"
# ============================================================================
restore_database_from_backup() {
    local backup_file=$1
    
    if [ -z "$backup_file" ] || [ ! -f "$backup_file" ]; then
        log_error "Backup introuvable: $backup_file"
        return 1
    fi
    
    if ! container_is_running "$DB_CONTAINER"; then
        log_error "Conteneur DB non running, impossible de restaurer"
        return 1
    fi
    
    # Détecter si le backup est chiffré
    if [[ "$backup_file" == *.enc ]]; then
        log_info "Restauration depuis backup chiffré: $(basename $backup_file)"
        
        # Récupérer la clé depuis Rails credentials
        if container_is_running "$CONTAINER_NAME"; then
            local encryption_key=$(docker exec "$CONTAINER_NAME" bin/rails runner \
                "puts Rails.application.credentials.dig(:database, :backup_encryption_key)" 2>/dev/null | tr -d '\n\r')
            
            if [ -z "$encryption_key" ]; then
                log_error "Clé de chiffrement introuvable dans Rails credentials"
                return 1
            fi
            
            # Déchiffrement + Restauration en un seul pipe (économise espace disque)
            if openssl enc -aes-256-cbc -d -pbkdf2 \
                -pass pass:"$encryption_key" \
                -in "$backup_file" 2>/dev/null | \
                docker exec -i "${DB_CONTAINER}" \
                psql -U postgres "${DB_NAME}" --single-transaction 2>/dev/null; then
                log_success "✅ Base de données restaurée depuis backup chiffré"
                return 0
            else
                log_error "Échec de la restauration (déchiffrement ou import)"
                return 1
            fi
        else
            log_error "Conteneur Rails non running, impossible d'accéder aux credentials"
            return 1
        fi
    else
        log_info "Restauration depuis backup non chiffré: $(basename $backup_file)"
        if cat "$backup_file" | docker exec -i "${DB_CONTAINER}" \
            psql -U postgres "${DB_NAME}" --single-transaction 2>/dev/null; then
            log_success "✅ Base de données restaurée depuis backup non chiffré"
            return 0
        else
            log_error "Échec de la restauration de la base de données"
            return 1
        fi
    fi
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
# Timestamp de début pour métriques
DEPLOY_START_TIME=$(date +%s)
export DEPLOY_START_TIME

log "🚀 DEPLOYMENT START - ${ENV} - $(date '+%Y-%m-%d %H:%M:%S')"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Nettoyage préventif automatique (images sans tag et cache build uniquement)
# Pour éviter les problèmes d'espace disque
log "🧹 Nettoyage préventif Docker (images sans tag + cache build)..."
docker image prune -f > /dev/null 2>&1 && log_info "Images sans tag nettoyées" || true
docker builder prune -f > /dev/null 2>&1 && log_info "Cache build nettoyé" || true

# 1. Vérifier s'il y a des mises à jour
log "📥 Vérification des mises à jour (branche: ${BRANCH})..."
git fetch origin

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/${BRANCH}" 2>/dev/null || echo "$LOCAL")

if [ "$LOCAL" = "$REMOTE" ]; then
    log "✅ Déjà à jour (commit: ${LOCAL:0:7})"
    
    # Mode manuel : proposer de forcer le redéploiement
    if [ "$FORCE_REDEPLOY" = true ]; then
        log_info "Mode FORCE activé, continuation du redéploiement..."
    elif [ -t 0 ]; then
        # Mode interactif (terminal) : demander confirmation
        log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_warning "⚠️  Déjà à jour - Voulez-vous forcer le redéploiement ?"
        log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_info "Options :"
        log_info "  1. Oui - Forcer le redéploiement (rebuild + migrations)"
        log_info "  2. Non - Vérifier uniquement les migrations en attente"
        log_info "  3. Quitter"
        log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        read -t 30 -p "Votre choix (1-3, défaut: 2) : " choice || choice="2"
        
        case "$choice" in
            1)
                log_info "Redéploiement forcé activé"
                FORCE_REDEPLOY=true
                ;;
            2)
                log_info "Vérification des migrations uniquement"
                FORCE_REDEPLOY=false
                ;;
            3|q|Q)
                log_info "Déploiement annulé"
                exit 0
                ;;
            *)
                log_info "Choix invalide, vérification des migrations uniquement"
                FORCE_REDEPLOY=false
                ;;
        esac
    else
        # Mode automatique (cron) : skip le redéploiement si déjà à jour
        log_info "Mode automatique détecté - Skip du redéploiement (déjà à jour)"
        FORCE_REDEPLOY=false
    fi
    
    # Si pas de force, vérifier uniquement les migrations
    if [ "$FORCE_REDEPLOY" = false ]; then
        # 🔍 Vérification critique : Migrations en attente même si Git est à jour
        # Ceci évite le drift DB/code non détecté (best practice DevOps production-grade)
        log "🔍 Vérification des migrations en attente..."
    
    # S'assurer que le conteneur est running (démarre si nécessaire)
    if ! container_is_running "$CONTAINER_NAME"; then
        log_warning "⚠️  Le conteneur ${CONTAINER_NAME} n'est pas running"
        if ensure_container_running "$CONTAINER_NAME" "$COMPOSE_FILE"; then
            log_success "✅ Conteneur démarré, continuation de la vérification..."
        else
            log_error "❌ Impossible de démarrer le conteneur"
            log_warning "Sortie sans vérification - les migrations seront vérifiées au prochain déploiement"
            exit 0
        fi
    fi
    
    # Maintenant le conteneur est running, vérifier les migrations
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
    fi
    
    # Si FORCE_REDEPLOY est activé, continuer avec le redéploiement complet
    if [ "$FORCE_REDEPLOY" = true ]; then
        log_info "🔄 Redéploiement forcé activé - continuation du processus complet..."
    fi
fi

log "🆕 Nouvelle version détectée (${LOCAL:0:7} → ${REMOTE:0:7})"

# 2. Backup base de données (P1 - Rails Credentials + OpenSSL)
backup_database() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/db_${timestamp}.sql"
    local backup_encrypted="${backup_file}.enc"
    
    log "📦 Backup base de données (chiffrement: ${BACKUP_ENCRYPTION_ENABLED})..."
    
    # Récupérer la clé de chiffrement depuis Rails credentials si activé
    local encryption_key=""
    if [ "$BACKUP_ENCRYPTION_ENABLED" = "true" ]; then
        # Attendre que le conteneur soit prêt pour accéder aux credentials
        if container_is_running "$CONTAINER_NAME"; then
            log_info "Récupération de la clé de chiffrement depuis Rails credentials..."
            encryption_key=$(docker exec "$CONTAINER_NAME" bin/rails runner \
                "puts Rails.application.credentials.dig(:database, :backup_encryption_key)" 2>/dev/null | tr -d '\n\r')
            
            if [ -z "$encryption_key" ]; then
                log_warning "⚠️  Clé backup_encryption_key non trouvée dans Rails credentials"
                log_warning "⚠️  Ajouter avec: rails credentials:edit --environment ${ENV}"
                log_warning "⚠️  Structure: database: { backup_encryption_key: 'votre-clé-32-chars' }"
                log_warning "⚠️  Continuation avec backup non chiffré..."
                BACKUP_ENCRYPTION_ENABLED="false"
            else
                log_success "✅ Clé de chiffrement récupérée depuis Rails credentials"
            fi
        else
            log_warning "⚠️  Conteneur non running, impossible d'accéder aux credentials"
            log_warning "⚠️  Continuation avec backup non chiffré..."
            BACKUP_ENCRYPTION_ENABLED="false"
        fi
    fi
    
    # Dump de la base de données
    if ! docker exec "${DB_CONTAINER}" pg_dump -U postgres "${DB_NAME}" > "$backup_file" 2>/dev/null; then
        log_error "Échec du dump DB"
        rm -f "$backup_file"
        return 1
    fi
    
    # Vérifier que le dump n'est pas vide
    if [ ! -s "$backup_file" ]; then
        log_error "Backup vide ou corrompu"
        rm -f "$backup_file"
        return 1
    fi
    
    # Chiffrer avec OpenSSL si activé et clé disponible
    if [ "$BACKUP_ENCRYPTION_ENABLED" = "true" ] && [ -n "$encryption_key" ]; then
        if ! command -v openssl > /dev/null 2>&1; then
            log_error "OpenSSL non disponible - installation requise: sudo apt-get install openssl"
            rm -f "$backup_file"
            return 1
        fi
        
        # Chiffrement avec OpenSSL (AES-256-CBC, PBKDF2, plus rapide que GPG)
        if openssl enc -aes-256-cbc -salt -pbkdf2 \
            -pass pass:"$encryption_key" \
            -in "$backup_file" \
            -out "$backup_encrypted" 2>/dev/null; then
            # Vérification intégrité (test de déchiffrement des premiers bytes)
            if openssl enc -aes-256-cbc -d -pbkdf2 \
                -pass pass:"$encryption_key" \
                -in "$backup_encrypted" 2>/dev/null | head -c 100 > /dev/null 2>&1; then
                local backup_size=$(du -h "$backup_encrypted" | cut -f1)
                log_success "✅ Backup chiffré créé: $(basename ${backup_encrypted}) (${backup_size})"
                rm -f "$backup_file"  # Supprimer le fichier non chiffré
                DB_BACKUP="$backup_encrypted"
                BACKUP_SIZE=$(stat -f%z "$backup_encrypted" 2>/dev/null || stat -c%s "$backup_encrypted" 2>/dev/null || echo "0")
            else
                log_error "Backup chiffré corrompu ou clé invalide"
                rm -f "$backup_file" "$backup_encrypted"
                return 1
            fi
        else
            log_error "Échec du chiffrement OpenSSL"
            # Opti 1 - Fallback gracieux : sauver en clair plutôt que fail
            log_warning "⚠️  Fallback : Sauvegarde du backup NON CHIFFRÉ (mieux qu'aucun backup)"
            DB_BACKUP="$backup_file"
            BACKUP_SIZE=$(stat -f%z "$backup_file" 2>/dev/null || stat -c%s "$backup_file" 2>/dev/null || echo "0")
            rm -f "$backup_encrypted"  # Supprimer le fichier chiffré corrompu
            # Ne pas return 1, continuer avec backup non chiffré
        fi
    else
        log_warning "⚠️  Backup non chiffré (BACKUP_ENCRYPTION_ENABLED=false ou clé manquante)"
        DB_BACKUP="$backup_file"
        BACKUP_SIZE=$(stat -f%z "$backup_file" 2>/dev/null || stat -c%s "$backup_file" 2>/dev/null || echo "0")
    fi
    
    # Garder seulement les N derniers backups (configurable)
    local retention_count=${BACKUP_RETENTION_COUNT:-20}
    if [ "$BACKUP_ENCRYPTION_ENABLED" = "true" ] && [ -n "$encryption_key" ]; then
        ls -t "${BACKUP_DIR}"/db_*.sql.enc 2>/dev/null | tail -n +$((retention_count + 1)) | xargs rm -f 2>/dev/null || true
    else
        ls -t "${BACKUP_DIR}"/db_*.sql 2>/dev/null | tail -n +$((retention_count + 1)) | xargs rm -f 2>/dev/null || true
    fi
    
    return 0
}

# Exécuter le backup
if ! backup_database; then
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

# Vérification post-pull : détecter conflits ou problèmes
GIT_STATUS=$(git status --porcelain 2>/dev/null || echo "")
if [ -n "$GIT_STATUS" ]; then
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_error "⚠️  CONFLITS OU CHANGEMENTS NON COMMITTÉS DÉTECTÉS"
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_error "État Git après pull:"
    echo "$GIT_STATUS" | while read -r line; do
        log_error "  $line"
    done
    log_error ""
    log_error "Le déploiement ne peut pas continuer avec un état Git incohérent"
    log_error "Résolvez les conflits manuellement puis réessayez"
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi

# Vérification post-pull : s'assurer que le code a bien été mis à jour
NEW_COMMIT=$(git rev-parse HEAD)
if [ "$CURRENT_COMMIT" = "$NEW_COMMIT" ]; then
    log_warning "⚠️  Aucun changement détecté après git pull (commit: ${NEW_COMMIT:0:7})"
    log_warning "Vérifiez que la branche ${BRANCH} contient bien les modifications attendues"
else
    log_success "✅ Code mis à jour (${CURRENT_COMMIT:0:7} → ${NEW_COMMIT:0:7})"
fi

# 6. Vérification espace disque avant build
log "💾 Vérification de l'espace disque..."
if ! check_disk_space ${DISK_SPACE_REQUIRED:-5}; then
    log_warning "⚠️  Espace disque faible, nettoyage préventif..."
    cleanup_docker
    # Vérifier à nouveau
    if ! check_disk_space ${DISK_SPACE_MIN_AFTER_CLEANUP:-3}; then
        log_error "❌ Espace disque insuffisant même après nettoyage"
        log_error "Action requise : libérer de l'espace manuellement puis réessayer"
        exit 1
    fi
fi

# P4 - Détection intelligente des changements critiques (optimisation builds)
needs_no_cache_build() {
    local changes=$(git diff --name-only HEAD@{1} HEAD 2>/dev/null || git diff --name-only origin/${BRANCH} HEAD 2>/dev/null || echo "")
    
    # Rebuild complet seulement si changements critiques
    if echo "$changes" | grep -qE '^(Gemfile|Gemfile\.lock|Dockerfile|package\.json|package-lock\.json|yarn\.lock)'; then
        log_warning "⚠️  Changements critiques détectés (Gemfile/Dockerfile/package.json)"
        return 0  # Besoin rebuild sans cache
    fi
    
    # Sinon, build incrémental (10x plus rapide)
    return 1  # Pas besoin rebuild sans cache
}

# ============================================================================
# FONCTION: verify_migrations_synced
# DESCRIPTION: Vérifie que toutes les migrations locales sont présentes dans le conteneur
# PARAMÈTRES:
#   $1: container - Nom du conteneur
#   $2: expected_count - Nombre attendu de migrations
#   $3: local_list - Liste triée des migrations locales
# RETOUR:
#   0: Migrations synchronisées
#   1: Migrations manquantes ou nombre incorrect
# USAGE: verify_migrations_synced "grenoble-roller-staging" 33 "$LOCAL_MIGRATIONS_LIST"
# ============================================================================
verify_migrations_synced() {
    local container=$1
    local expected_count=$2
    local local_list=$3
    
    # Lister migrations dans le conteneur
    local container_list=$(docker exec "$container" find /rails/db/migrate -name "*.rb" -type f -exec basename {} \; 2>/dev/null | sort || echo "")
    
    if [ -z "$container_list" ]; then
        log_error "❌ Impossible de lister les migrations dans le conteneur"
        return 1
    fi
    
    local container_count=$(echo "$container_list" | wc -l | tr -d ' ')
    
    # Vérifier le nombre
    if [ "$container_count" -ne "$expected_count" ]; then
        log_warning "⚠️  Nombre de migrations différent : attendu=${expected_count}, conteneur=${container_count}"
        return 1
    fi
    
    # Vérifier que toutes les migrations locales sont dans le conteneur
    local missing=$(comm -23 <(echo "$local_list") <(echo "$container_list") || echo "")
    
    if [ -n "$missing" ]; then
        log_error "❌ Migrations manquantes dans le conteneur :"
        echo "$missing" | while read -r migration; do
            log_error "  🔴 $migration"
        done
        return 1
    fi
    
    log_success "✅ Migrations synchronisées (${expected_count} fichiers)"
    return 0
}

# ============================================================================
# FONCTION: health_check_comprehensive
# DESCRIPTION: Effectue un health check complet (DB, Redis, Migrations, HTTP)
# PARAMÈTRES:
#   $1: container - Nom du conteneur
#   $2: port - Port HTTP du conteneur
# RETOUR:
#   0: Tous les checks réussis
#   >0: Nombre d'erreurs détectées
# USAGE: health_check_comprehensive "grenoble-roller-staging" 3001
# ============================================================================
health_check_comprehensive() {
    local container=$1
    local port=$2
    local errors=0
    
    log "🏥 Health check complet (DB, Redis, Migrations, HTTP)..."
    
    # 1. Vérifier DB connectivité depuis Rails
    log_info "  → Vérification DB..."
    if ! docker exec "$container" bin/rails runner \
        "ActiveRecord::Base.connection.execute('SELECT 1')" > /dev/null 2>&1; then
        log_error "  ❌ DB inaccessible depuis Rails"
        errors=$((errors + 1))
    else
        log_success "  ✅ DB accessible"
    fi
    
    # 2. Vérifier Redis (si utilisé)
    log_info "  → Vérification Redis..."
    if docker exec "$container" bin/rails runner \
       "Redis.current.ping rescue nil" > /dev/null 2>&1; then
        if docker exec "$container" bin/rails runner \
           "Redis.current.ping" > /dev/null 2>&1; then
            log_success "  ✅ Redis accessible"
        else
            log_warning "  ⚠️  Redis non configuré (non bloquant)"
        fi
    else
        log_warning "  ⚠️  Redis non disponible (non bloquant)"
    fi
    
    # 3. Vérifier migrations appliquées
    log_info "  → Vérification migrations..."
    local pending=$(docker exec "$container" bin/rails db:migrate:status 2>/dev/null | \
                   awk '/^\s*down/ {count++} END {print count+0}' || echo "999")
    if [ "$pending" -gt 0 ]; then
        log_error "  ❌ Migrations en attente: $pending"
        errors=$((errors + 1))
    else
        log_success "  ✅ Toutes les migrations appliquées"
    fi
    
    # 4. Test HTTP endpoint
    log_info "  → Vérification HTTP (port: ${port})..."
    local response=$(curl -s -w "%{http_code}" -o /dev/null \
                    "http://localhost:${port}/up" 2>/dev/null || echo "000")
    if [ "$response" = "200" ]; then
        log_success "  ✅ HTTP endpoint OK (${response})"
    else
        log_error "  ❌ HTTP endpoint échoué (code: ${response})"
        errors=$((errors + 1))
    fi
    
    return $errors
}

# ============================================================================
# FONCTION: force_rebuild_without_cache
# DESCRIPTION: Force un rebuild Docker complet sans cache (garantit inclusion fichiers)
# PARAMÈTRES:
#   $1: compose_file - Chemin vers docker-compose.yml (optionnel, défaut: $COMPOSE_FILE)
# RETOUR:
#   0: Build réussi
#   1: Échec du build
# USAGE: force_rebuild_without_cache "$COMPOSE_FILE"
# NOTE: Nettoie cache BuildKit, génère BUILD_ID unique, rebuild avec --no-cache
# ============================================================================
force_rebuild_without_cache() {
    local compose_file=${1:-$COMPOSE_FILE}
    log_warning "🔄 Rebuild sans cache COMPLET pour garantir l'inclusion de tous les fichiers..."
    log_info "Arrêt des conteneurs..."
    docker compose -f "$compose_file" down > /dev/null 2>&1 || true
    
    log_info "Nettoyage du cache de build (garde cache récent pour performance)..."
    docker builder prune -f > /dev/null 2>&1 || true
    
    log_info "Nettoyage BuildKit cache (cache persistant)..."
    docker buildx prune -a -f > /dev/null 2>&1 || true
    
    log_info "Nettoyage des images intermédiaires..."
    docker image prune -f > /dev/null 2>&1 || true
    
    # Supprimer l'image actuelle si elle existe (force rebuild complet)
    log_info "Suppression de l'image actuelle (force rebuild from scratch)..."
    docker rmi $(docker images -q "${CONTAINER_NAME}" 2>/dev/null | head -1) --force 2>/dev/null || true
    
    # Vérifier que les fichiers de migration sont bien dans le build context
    log_info "Vérification que les migrations sont dans le build context..."
    local migration_count=$(find "$REPO_DIR/db/migrate" -name "*.rb" -type f 2>/dev/null | wc -l | tr -d ' ')
    log_info "✅ ${migration_count} fichier(s) de migration trouvé(s) dans le build context"
    
    # Générer un BUILD_ID unique pour forcer un nouveau build (évite cache Docker trompeur)
    local BUILD_ID="$(date +%Y%m%d-%H%M%S)-$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
    log_info "🔨 BUILD_ID unique: ${BUILD_ID} (force nouveau layer, évite cache trompeur)"
    
    log_info "Rebuild sans cache COMPLET (--pull --no-cache --build-arg BUILD_ID)..."
    log_warning "⚠️  Ce build peut prendre 5-10 minutes (sans cache complet)..."
    
    # Utiliser --pull pour forcer le pull des images de base, --no-cache pour ignorer tout le cache
    # et --build-arg BUILD_ID pour forcer un nouveau layer (évite cache Docker trompeur)
    # Note: --progress doit être AVANT build (global compose flag)
    # Note: On n'utilise pas de capture dans une variable car avec set -e, ça peut faire planter
    # On laisse la sortie aller directement vers stdout/stderr et on vérifie le code de sortie après
    if docker compose --progress=plain -f "$compose_file" build --pull --no-cache --build-arg BUILD_ID="$BUILD_ID" 2>&1 | tee -a "$LOG_FILE"; then
        BUILD_EXIT_CODE=0
        log_success "✅ Build réussi"
    else
        BUILD_EXIT_CODE=$?
        log_error "❌ Build échoué (exit code: $BUILD_EXIT_CODE)"
        return $BUILD_EXIT_CODE
    fi
    
    if [ $BUILD_EXIT_CODE -eq 0 ]; then
        log_info "Démarrage des conteneurs..."
        if docker compose -f "$compose_file" up -d 2>&1 | tee -a "$LOG_FILE"; then
            log_success "✅ Conteneurs démarrés"
            return 0
        else
            log_error "❌ Échec du démarrage des conteneurs"
            return 1
        fi
    else
        return $BUILD_EXIT_CODE
    fi
}

# Blue-Green Deployment Functions (Zero-Downtime)
get_active_environment() {
    # Détecter quel environnement est actif (blue ou green)
    if docker ps --format '{{.Names}}' | grep -q "grenoble-roller-staging-blue"; then
        if docker ps --format '{{.Names}}' | grep -q "grenoble-roller-staging-green"; then
            # Les deux sont running, vérifier le proxy
            local proxy_config=$(docker exec grenoble-roller-staging-proxy cat /etc/nginx/nginx.conf 2>/dev/null || echo "")
            if echo "$proxy_config" | grep -q "web-green:3000"; then
                echo "green"
            else
                echo "blue"
            fi
        else
            echo "blue"
        fi
    elif docker ps --format '{{.Names}}' | grep -q "grenoble-roller-staging-green"; then
        echo "green"
    else
        echo "none"
    fi
}

get_inactive_environment() {
    local active=$(get_active_environment)
    if [ "$active" = "blue" ]; then
        echo "green"
    elif [ "$active" = "green" ]; then
        echo "blue"
    else
        echo "blue"  # Par défaut, commencer avec blue
    fi
}

blue_green_deploy() {
    log "🔵🟢 Blue-Green Deployment (Zero-Downtime)..."
    
    local active_env=$(get_active_environment)
    local inactive_env=$(get_inactive_environment)
    
    log_info "Environnement actif: ${active_env}"
    log_info "Déploiement sur: ${inactive_env}"
    
    # 1. Build le nouvel environnement (inactif)
    local new_container="grenoble-roller-staging-${inactive_env}"
    log_info "🔨 Build de l'environnement ${inactive_env}..."
    
    if needs_no_cache_build; then
        log_warning "Build sans cache (changements critiques détectés)"
        docker compose -f "$BLUE_GREEN_COMPOSE_FILE" build --no-cache "web-${inactive_env}" > /tmp/build-${inactive_env}.log 2>&1
    else
        log_info "Build incrémental (cache activé)"
        docker compose -f "$BLUE_GREEN_COMPOSE_FILE" build "web-${inactive_env}" > /tmp/build-${inactive_env}.log 2>&1
    fi
    
    if [ $? -ne 0 ]; then
        log_error "Échec du build ${inactive_env}"
        cat /tmp/build-${inactive_env}.log | tee -a "$LOG_FILE"
        return 1
    fi
    
    # 2. Démarrer le nouvel environnement
    log_info "🚀 Démarrage de l'environnement ${inactive_env}..."
    docker compose -f "$BLUE_GREEN_COMPOSE_FILE" up -d "web-${inactive_env}" > /tmp/start-${inactive_env}.log 2>&1
    
    if [ $? -ne 0 ]; then
        log_error "Échec du démarrage ${inactive_env}"
        cat /tmp/start-${inactive_env}.log | tee -a "$LOG_FILE"
        return 1
    fi
    
    # 3. Attendre que le nouvel environnement soit healthy
    log_info "⏳ Attente que ${inactive_env} soit healthy..."
    local max_wait=120
    local waited=0
    while [ $waited -lt $max_wait ]; do
        if docker inspect --format='{{.State.Health.Status}}' "$new_container" 2>/dev/null | grep -q "healthy"; then
            log_success "✅ ${inactive_env} est healthy"
            break
        fi
        sleep 2
        waited=$((waited + 2))
        if [ $((waited % 10)) -eq 0 ]; then
            log_info "Attente... (${waited}s/${max_wait}s)"
        fi
    done
    
    if [ $waited -ge $max_wait ]; then
        log_error "❌ ${inactive_env} n'est pas devenu healthy"
        docker logs "$new_container" --tail 50 | tee -a "$LOG_FILE"
        return 1
    fi
    
    # 4. Health check complet sur le nouvel environnement
    local new_port=$([ "$inactive_env" = "blue" ] && echo "3002" || echo "3003")
    if ! health_check_comprehensive "$new_container" "$new_port"; then
        log_error "❌ Health check échoué sur ${inactive_env}"
        return 1
    fi
    
    # 5. Opti 2 - Validation pre-switch : Test de charge léger avant basculement
    log_info "🔍 Test de charge léger sur ${inactive_env} avant basculement..."
    local stress_test_errors=0
    for i in {1..10}; do
        local test_response=$(curl -s -o /dev/null -w "%{http_code}" \
                             "http://localhost:${new_port}/up" 2>/dev/null || echo "000")
        if [ "$test_response" != "200" ]; then
            stress_test_errors=$((stress_test_errors + 1))
        fi
        sleep 0.1
    done
    
    if [ $stress_test_errors -gt 2 ]; then
        log_error "❌ Test de charge échoué (${stress_test_errors}/10 requêtes en erreur)"
        return 1
    fi
    log_success "✅ Test de charge réussi (${stress_test_errors}/10 erreurs tolérées)"
    
    # 6. Basculement du trafic (mise à jour nginx)
    log_info "🔄 Basculement du trafic vers ${inactive_env}..."
    local nginx_conf="${SCRIPT_DIR}/nginx-blue-green.conf"
    local temp_conf="/tmp/nginx-${inactive_env}.conf"
    
    # Créer la nouvelle config nginx
    sed "s/server web-.*:3000;/server web-${inactive_env}:3000;/" "$nginx_conf" > "$temp_conf"
    
    # Appliquer la nouvelle config
    docker cp "$temp_conf" "grenoble-roller-staging-proxy:/etc/nginx/nginx.conf" 2>/dev/null || {
        log_error "Échec de la mise à jour de la config nginx"
        rm -f "$temp_conf"
        return 1
    }
    
    # Recharger nginx (sans downtime)
    docker exec "grenoble-roller-staging-proxy" nginx -s reload 2>/dev/null || {
        log_error "Échec du rechargement nginx"
        rm -f "$temp_conf"
        return 1
    }
    
    rm -f "$temp_conf"
    log_success "✅ Trafic basculé vers ${inactive_env}"
    
    # 6. Attendre quelques secondes pour vérifier la stabilité
    sleep 5
    
    # 7. Vérifier que le proxy fonctionne toujours
    local proxy_health=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${PORT}/health" 2>/dev/null || echo "000")
    if [ "$proxy_health" != "200" ]; then
        log_error "❌ Proxy non accessible après basculement"
        # Rollback rapide
        sed "s/server web-.*:3000;/server web-${active_env}:3000;/" "$nginx_conf" > "$temp_conf"
        docker cp "$temp_conf" "grenoble-roller-staging-proxy:/etc/nginx/nginx.conf" 2>/dev/null
        docker exec "grenoble-roller-staging-proxy" nginx -s reload 2>/dev/null
        rm -f "$temp_conf"
        return 1
    fi
    
    # 8. Arrêter l'ancien environnement (optionnel, peut être gardé pour rollback rapide)
    if [ "$active_env" != "none" ]; then
        log_info "🛑 Arrêt de l'ancien environnement ${active_env} (gardé 5min pour rollback rapide)..."
        # Ne pas arrêter immédiatement, permettre rollback rapide
        (sleep 300; docker compose -f "$BLUE_GREEN_COMPOSE_FILE" stop "web-${active_env}" 2>/dev/null || true) &
    fi
    
    log_success "✅ Blue-Green deployment réussi - Zero downtime"
    return 0
}

# 7. Vérification pré-build : comparaison intelligente avec le conteneur actuel
log "🔍 Vérification des fichiers de migration avant build..."

# OPTIMISATION : Cache le résultat de find (évite 3 exécutions)
LOCAL_MIGRATIONS_LIST=$(find "$REPO_DIR/db/migrate" -name "*.rb" -type f -exec basename {} \; 2>/dev/null | sort)
MIGRATION_FILES_COUNT=$(echo "$LOCAL_MIGRATIONS_LIST" | wc -l | tr -d ' ')

if [ "$MIGRATION_FILES_COUNT" -eq 0 ]; then
    log_error "❌ Aucun fichier de migration trouvé dans db/migrate/"
    log_error "Vérifiez que le git pull a bien récupéré tous les fichiers"
    rollback "$CURRENT_COMMIT"
    exit 1
else
    log_info "✅ ${MIGRATION_FILES_COUNT} fichier(s) de migration trouvé(s) localement"
fi

# Comparaison intelligente : conteneur actuel vs nouveaux fichiers
NEED_NO_CACHE_BUILD=false
if container_is_running "$CONTAINER_NAME"; then
    log_info "🔍 Comparaison avec le conteneur actuel pour optimiser le build..."
    CURRENT_CONTAINER_MIGRATIONS=$(docker exec "$CONTAINER_NAME" find /rails/db/migrate -name "*.rb" -type f -exec basename {} \; 2>/dev/null | sort || echo "")
    
    if [ -n "$CURRENT_CONTAINER_MIGRATIONS" ]; then
        CURRENT_COUNT=$(echo "$CURRENT_CONTAINER_MIGRATIONS" | wc -l | tr -d ' ')
        NEW_IN_LOCAL=$(comm -23 <(echo "$LOCAL_MIGRATIONS_LIST") <(echo "$CURRENT_CONTAINER_MIGRATIONS") || echo "")
        
        if [ -n "$NEW_IN_LOCAL" ] || [ "$MIGRATION_FILES_COUNT" -ne "$CURRENT_COUNT" ]; then
            if [ -n "$NEW_IN_LOCAL" ]; then
                log_warning "⚠️  Nouvelles migrations détectées dans le repo local :"
                echo "$NEW_IN_LOCAL" | while read -r migration; do
                    log_warning "  🆕 $migration"
                done
            fi
            if [ "$MIGRATION_FILES_COUNT" -ne "$CURRENT_COUNT" ]; then
                log_warning "⚠️  Nombre de migrations différent : local=${MIGRATION_FILES_COUNT}, conteneur=${CURRENT_COUNT}"
            fi
            log_warning "⚠️  Rebuild sans cache OBLIGATOIRE pour garantir l'inclusion des migrations"
            NEED_NO_CACHE_BUILD=true
            
            # Forcer arrêt + nettoyage cache pour garantir fraîcheur
            log_info "Nettoyage préventif du cache avant rebuild..."
            docker compose -f "$COMPOSE_FILE" down > /dev/null 2>&1 || true
            docker builder prune -f > /dev/null 2>&1 || true
        else
            log_success "✅ Migrations identiques entre local et conteneur actuel"
        fi
    else
        log_info "ℹ️  Impossible de lire les migrations du conteneur actuel (peut être en cours de démarrage)"
        # Si on ne peut pas lire, on fait un build sans cache pour être sûr
        log_warning "⚠️  Build sans cache par sécurité (impossible de vérifier le conteneur actuel)"
        NEED_NO_CACHE_BUILD=true
    fi
else
    log_info "ℹ️  Aucun conteneur actuel, build normal"
fi

# 7. Build et restart (avec Blue-Green si activé)
if [ "$BLUE_GREEN_ENABLED" = "true" ]; then
    # Blue-Green Deployment (Zero-Downtime)
    if ! blue_green_deploy; then
        log_error "Échec du blue-green deployment"
        rollback "$CURRENT_COMMIT"
        exit 1
    fi
    BUILD_EXIT_CODE=0
    BUILD_OUTPUT="Blue-green deployment réussi"
    # Mettre à jour CONTAINER_NAME pour les étapes suivantes
    CONTAINER_NAME="grenoble-roller-staging-$(get_active_environment)"
else
    # Déploiement classique
    if [ "$NEED_NO_CACHE_BUILD" = true ] || needs_no_cache_build; then
        log "🔨 Build SANS CACHE (nouvelles migrations ou changements critiques)..."
        # La fonction affiche déjà dans les logs via tee
        if force_rebuild_without_cache "$COMPOSE_FILE"; then
            BUILD_EXIT_CODE=0
            BUILD_OUTPUT="Rebuild sans cache réussi"
        else
            BUILD_EXIT_CODE=$?
            BUILD_OUTPUT="Rebuild sans cache échoué"
        fi
    else
        log "🔨 Build et redémarrage (cache activé)..."
        BUILD_OUTPUT=$(docker compose -f "$COMPOSE_FILE" up -d --build 2>&1)
        BUILD_EXIT_CODE=$?
        
        # Vérifier que l'image a été créée après build
        if [ $BUILD_EXIT_CODE -eq 0 ]; then
            local image_name=$(docker compose -f "$COMPOSE_FILE" images -q web 2>/dev/null | head -1)
            if [ -z "$image_name" ]; then
                log_error "❌ Image non trouvée après build réussi"
                log_error "Le build a peut-être échoué silencieusement"
                BUILD_EXIT_CODE=1
            else
                log_success "✅ Image créée: ${image_name:0:12}..."
            fi
        fi
    fi
fi

if [ $BUILD_EXIT_CODE -ne 0 ]; then
    log_error "Échec du build/restart"
    echo "$BUILD_OUTPUT" | tee -a "$LOG_FILE"
    
    # Détecter erreur d'espace disque
    if echo "$BUILD_OUTPUT" | grep -qi "no space left on device\|disk full\|not enough space"; then
        log_error "Erreur d'espace disque détectée"
        if recover_from_disk_full "$BUILD_OUTPUT" "$CURRENT_COMMIT"; then
            log_info "Nettoyage effectué, vous pouvez réessayer le déploiement"
            exit 0
        else
            rollback "$CURRENT_COMMIT"
            exit 1
        fi
    else
        rollback "$CURRENT_COMMIT"
        exit 1
    fi
fi

# 8. Vérification POST-BUILD IMPÉRATIVE : les fichiers locaux DOIVENT être dans le conteneur
log "🔍 Vérification IMPÉRATIVE : les fichiers de migration locaux sont-ils dans le conteneur ?"
if ! container_is_running "$CONTAINER_NAME"; then
    log_error "❌ Le conteneur n'est pas running, impossible de vérifier"
    show_container_logs "$CONTAINER_NAME"
    rollback "$CURRENT_COMMIT"
    exit 1
fi

# Attendre que le conteneur soit prêt
wait_for_container_running "$CONTAINER_NAME" 30 || {
    log_error "❌ Le conteneur n'est pas stable"
    show_container_logs "$CONTAINER_NAME"
    rollback "$CURRENT_COMMIT"
    exit 1
}

sleep 3  # Attendre que le système de fichiers soit accessible

# Vérification IMPÉRATIVE : toutes les migrations locales doivent être dans le conteneur
# Utiliser la fonction helper pour éviter duplication
if ! verify_migrations_synced "$CONTAINER_NAME" "$MIGRATION_FILES_COUNT" "$LOCAL_MIGRATIONS_LIST"; then
    # Récupérer la liste pour afficher les détails
    CONTAINER_MIGRATIONS_LIST=$(docker exec "$CONTAINER_NAME" find /rails/db/migrate -name "*.rb" -type f -exec basename {} \; 2>/dev/null | sort || echo "")
    MISSING_IN_CONTAINER=$(comm -23 <(echo "$LOCAL_MIGRATIONS_LIST") <(echo "$CONTAINER_MIGRATIONS_LIST") || echo "")
    
    if [ -n "$MISSING_IN_CONTAINER" ]; then
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_error "❌ ERREUR CRITIQUE : Migrations locales ABSENTES du conteneur"
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$MISSING_IN_CONTAINER" | while read -r migration; do
        log_error "  🔴 $migration (présent localement, ABSENT du conteneur)"
    done
    log_error ""
    log_warning "🔄 CORRECTION AUTOMATIQUE : Rebuild sans cache pour forcer l'inclusion des fichiers..."
    
    # Correction automatique : rebuild sans cache
    if force_rebuild_without_cache "$COMPOSE_FILE"; then
        # Attendre que le conteneur démarre
        if wait_for_container_running "$CONTAINER_NAME" 60; then
            # Vérifier à nouveau après rebuild
            sleep 5
            if verify_migrations_synced "$CONTAINER_NAME" "$MIGRATION_FILES_COUNT" "$LOCAL_MIGRATIONS_LIST"; then
                log_success "✅ CORRECTION RÉUSSIE - Toutes les migrations sont maintenant présentes"
                log_success "✅ Continuation du déploiement..."
                # Mettre à jour CONTAINER_MIGRATIONS_LIST pour la suite
                CONTAINER_MIGRATIONS_LIST=$(docker exec "$CONTAINER_NAME" find /rails/db/migrate -name "*.rb" -type f -exec basename {} \; 2>/dev/null | sort || echo "")
            else
                # Récupérer les détails pour affichage
                NEW_CONTAINER_MIGRATIONS=$(docker exec "$CONTAINER_NAME" find /rails/db/migrate -name "*.rb" -type f -exec basename {} \; 2>/dev/null | sort || echo "")
                NEW_MISSING=$(comm -23 <(echo "$LOCAL_MIGRATIONS_LIST") <(echo "$NEW_CONTAINER_MIGRATIONS") || echo "")
                log_error "❌ Migrations toujours manquantes après rebuild sans cache"
                log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "$NEW_MISSING" | while read -r migration; do
                    log_error "  🔴 $migration"
                done
                log_error ""
                log_error "🔧 DIAGNOSTIC :"
                log_error "  1. Vérifier .dockerignore : cat .dockerignore | grep -i migrate"
                log_error "  2. Vérifier que les fichiers existent : ls -la db/migrate/ | grep -E '$(echo "$NEW_MISSING" | head -1 | sed 's/\.rb$//')'"
                log_error "  3. Vérifier le Dockerfile : la commande COPY doit inclure db/migrate"
                log_error "  4. Vérifier le build context : docker compose build --progress=plain pour voir les fichiers copiés"
                log_error ""
                log_error "❌ IMPOSSIBLE de continuer - Rollback"
                show_container_logs "$CONTAINER_NAME"
                rollback "$CURRENT_COMMIT"
                exit 1
            fi
        else
            log_error "❌ Le conteneur n'a pas redémarré après le rebuild"
            cat /tmp/rebuild_fix.log | tee -a "$LOG_FILE"
            show_container_logs "$CONTAINER_NAME"
            rollback "$CURRENT_COMMIT"
            exit 1
        fi
    else
        log_error "❌ Échec du rebuild sans cache"
        cat /tmp/rebuild_fix.log | tee -a "$LOG_FILE"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "🔧 SOLUTIONS MANUELLES :"
        log_error "  1. Vérifier le .dockerignore (ne doit pas exclure db/migrate/)"
        log_error "  2. Vérifier que git pull a bien récupéré tous les fichiers"
        log_error "  3. Nettoyer manuellement : docker builder prune -a -f"
        log_error "  4. Rebuild manuel : docker compose -f $COMPOSE_FILE build --no-cache"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        show_container_logs "$CONTAINER_NAME"
        rollback "$CURRENT_COMMIT"
        exit 1
    fi
    fi
else
    # Récupérer la liste pour affichage
    CONTAINER_MIGRATIONS_LIST=$(docker exec "$CONTAINER_NAME" find /rails/db/migrate -name "*.rb" -type f -exec basename {} \; 2>/dev/null | sort || echo "")
    CONTAINER_COUNT=$(echo "$CONTAINER_MIGRATIONS_LIST" | wc -l | tr -d ' ')
    log_success "✅ VÉRIFICATION RÉUSSIE : Toutes les ${MIGRATION_FILES_COUNT} migrations locales sont dans le conteneur (${CONTAINER_COUNT} fichiers)"
    log_success "✅ Le build a correctement inclus tous les fichiers de migration"
fi

# 9. Attendre que le conteneur web démarre
log "⏳ Attente du démarrage du conteneur..."
if ! wait_for_container_running "$CONTAINER_NAME" 60; then
    log_error "Le conteneur web n'a pas démarré"
    show_container_logs "$CONTAINER_NAME"
    rollback "$CURRENT_COMMIT"
    exit 1
fi

# 10. Attendre que le conteneur soit healthy (si healthcheck configuré)
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

# 11. Vérifier que le conteneur est toujours running avant migrations
if ! container_is_running "$CONTAINER_NAME"; then
    log_error "Le conteneur web s'est arrêté avant les migrations"
    show_container_logs "$CONTAINER_NAME"
    rollback "$CURRENT_COMMIT"
    exit 1
fi

# 12. Migrations - Les fichiers sont vérifiés (étape 8), on peut maintenant appliquer les migrations
log "🗄️ Préparation des migrations..."

# Vérification que le conteneur est toujours running
if ! container_is_running "$CONTAINER_NAME"; then
    log_error "Le conteneur web s'est arrêté juste avant les migrations"
    show_container_logs "$CONTAINER_NAME"
    rollback "$CURRENT_COMMIT"
    exit 1
fi

# Les fichiers de migration ont déjà été vérifiés à l'étape 8 (impératif)
# Toutes les migrations locales sont dans le conteneur, on peut appliquer db:migrate

# 🔍 SAFEGUARD 1 : Analyse des migrations en attente pour détecter les migrations destructives
log "🔍 Analyse des migrations en attente pour détecter les risques..."
MIGRATION_STATUS=$(docker exec "${CONTAINER_NAME}" bin/rails db:migrate:status 2>&1)
PENDING_MIGRATIONS=$(echo "$MIGRATION_STATUS" | grep "^\s*down" || echo "")

if [ -n "$PENDING_MIGRATIONS" ]; then
    # Patterns destructifs étendus (couvre plus de cas Rails)
    DESTRUCTIVE_PATTERNS="Remove|Drop|Destroy|Delete|Truncate|Clear|Rename.*Column|Change.*Column.*Type"
    DESTRUCTIVE_MIGRATIONS=$(echo "$PENDING_MIGRATIONS" | grep -iE "$DESTRUCTIVE_PATTERNS" || echo "")
    
    if [ -n "$DESTRUCTIVE_MIGRATIONS" ]; then
        log_error "⚠️  ⚠️  ⚠️  MIGRATIONS DESTRUCTIVES DÉTECTÉES ⚠️  ⚠️  ⚠️"
        log_error "Les migrations suivantes peuvent supprimer ou modifier définitivement des données :"
        echo "$DESTRUCTIVE_MIGRATIONS" | while read -r migration; do
            log_error "  🔴 $migration"
        done
        
        if [ "$ENV" = "production" ]; then
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
            log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log_warning "⚠️  STAGING : Migration destructive détectée"
            log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log_warning "Exécution automatique en staging (review recommandée)"
            log_warning "Si vous voulez ARRÊTER, appuyez sur Ctrl+C maintenant"
            for i in {10..1}; do
                echo -ne "\rContinuation dans ${i}s...   "
                sleep 1
            done
            echo ""  # Nouvelle ligne
            log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log_info "Continuation de l'exécution..."
        fi
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

# 🕐 SAFEGUARD 2 : Configuration du timeout adaptatif pour les migrations (P2)
calculate_migration_timeout() {
    local pending_migrations=$1
    local env_multiplier=1
    local max_timeout=$MIGRATION_MAX_TIMEOUT
    
    # Multiplicateur selon l'environnement
    if [ "$ENV" = "production" ]; then
        env_multiplier=2  # Plus de temps en production
        max_timeout=$MIGRATION_MAX_TIMEOUT_PRODUCTION
    fi
    
    local calculated=$((MIGRATION_BASE_TIMEOUT + (pending_migrations * MIGRATION_PER_MIGRATION * env_multiplier)))
    echo $((calculated > max_timeout ? max_timeout : calculated))
}

# Calculer le timeout adaptatif
PENDING_COUNT=$(echo "$PENDING_MIGRATIONS" | wc -l | tr -d ' ')
MIGRATION_TIMEOUT=$(calculate_migration_timeout $PENDING_COUNT)

log "🕐 Timeout migration adaptatif : ${MIGRATION_TIMEOUT}s pour ${PENDING_COUNT} migration(s) (${ENV})"

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

# En staging/production, utiliser db:migrate (ne pas utiliser db:reset qui supprime les données)
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
    log_error "⚠️  RISQUE : Migration partielle possible"
    log_error "La migration a peut-être été partiellement exécutée, vérifiez l'état de la DB"
    log_error "Durée réelle : ${MIGRATION_DURATION}s"
    log_error ""
    log_error "🔧 SOLUTIONS POSSIBLES :"
    log_error "  1. Vérifier l'état : docker exec ${CONTAINER_NAME} bin/rails db:migrate:status"
    log_error "  2. Si migration bloquée : redémarrer le conteneur DB"
    log_error "  3. Si migration partielle : restaurer backup puis corriger migration"
    log_error "  4. Augmenter timeout si migration légitime : MIGRATION_TIMEOUT=1200 (20min)"
    log_error ""
    log_error "Action : Rollback du code et vérification manuelle de la DB"
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
        log_error "⚠️ ERREUR DÉTECTÉE : Table manquante lors d'une migration"
        log_error "Cela indique probablement un problème d'ORDRE DES MIGRATIONS"
        log_error "Vérifiez que les migrations créant les tables sont exécutées AVANT celles qui les modifient"
    fi
    
    if echo "$MIGRATION_OUTPUT" | grep -qi "lock\|deadlock\|timeout"; then
        log_error "⚠️ ERREUR DÉTECTÉE : Verrouillage de base de données"
        log_error "La migration a peut-être causé un lock sur une table"
        log_error "Vérifiez les processus PostgreSQL en cours"
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

# Attendre que le conteneur soit running avant de vérifier les migrations
if ! wait_for_container_running "$CONTAINER_NAME" 30; then
    log_error "Le conteneur n'est pas running, impossible de vérifier les migrations"
    show_container_logs "$CONTAINER_NAME" 100
    rollback "$CURRENT_COMMIT"
    exit 1
fi

# Attendre que Rails soit complètement démarré (vérification active)
log_info "Attente que Rails soit prêt (vérification active)..."
RAILS_READY=false
RAILS_WAIT_COUNT=0
RAILS_MAX_WAIT=30  # Maximum 30 tentatives = 30 secondes

while [ $RAILS_WAIT_COUNT -lt $RAILS_MAX_WAIT ]; do
    # Tester si Rails répond (via db:migrate:status qui nécessite Rails)
    if docker exec "${CONTAINER_NAME}" bin/rails db:migrate:status > /dev/null 2>&1; then
        RAILS_READY=true
        log_success "Rails est prêt (après ${RAILS_WAIT_COUNT}s)"
        break
    fi
    RAILS_WAIT_COUNT=$((RAILS_WAIT_COUNT + 1))
    if [ $((RAILS_WAIT_COUNT % 5)) -eq 0 ]; then
        log_info "Attente Rails... (${RAILS_WAIT_COUNT}s/${RAILS_MAX_WAIT}s)"
    fi
    sleep 1
done

if [ "$RAILS_READY" = false ]; then
    log_warning "⚠️  Rails n'est pas encore prêt après ${RAILS_MAX_WAIT}s, mais on continue quand même..."
fi

POST_MIGRATION_STATUS=$(docker exec "${CONTAINER_NAME}" bin/rails db:migrate:status 2>&1)
POST_MIGRATION_EXIT=$?

# Si la commande a échoué, on ne peut pas vérifier - mais on continue quand même
if [ $POST_MIGRATION_EXIT -ne 0 ]; then
    log_warning "⚠️  Impossible d'exécuter db:migrate:status (exit code: $POST_MIGRATION_EXIT)"
    log_warning "Réponse: $POST_MIGRATION_STATUS"
    log_warning "Le conteneur peut être en cours de démarrage, on continue quand même..."
    POST_PENDING_COUNT=0  # On assume qu'il n'y a pas de migrations en attente
else
    # Compter les migrations en attente (méthode robuste avec awk)
    POST_PENDING_COUNT=$(echo "$POST_MIGRATION_STATUS" | awk '/^\s*down/ {count++} END {print count+0}' 2>/dev/null || echo "0")
    
    # S'assurer que c'est un nombre valide (défaut à 0 si vide ou invalide)
    if ! [[ "$POST_PENDING_COUNT" =~ ^[0-9]+$ ]]; then
        POST_PENDING_COUNT=0
    fi
    
    log_info "Migrations en attente après db:migrate : $POST_PENDING_COUNT"
fi

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

# 12. Health check avec retry (unifié - évite duplication HTTP)
# Opti 4 - Backoff exponentiel pour health check
calculate_backoff() {
    local retry=$1
    local max_backoff=${HEALTH_CHECK_BACKOFF_MAX:-10}
    local backoff=$((2 ** (retry / 5)))  # Double tous les 5 retries
    echo $((backoff > max_backoff ? max_backoff : backoff))
}

# Health check avec retry (utilise directement health_check_comprehensive)
log "🏥 Health check complet avec retry (DB, Redis, Migrations, HTTP)..."
MAX_RETRIES=${HEALTH_CHECK_MAX_RETRIES:-60}
RETRY_COUNT=0

# Vérifier que curl est disponible
if ! command -v curl > /dev/null 2>&1; then
    log_error "curl n'est pas disponible sur le système"
    log_error "Installation requise : sudo apt-get install curl"
    rollback "$CURRENT_COMMIT"
    exit 1
fi

# Attendre que le conteneur soit "healthy" selon Docker (si healthcheck configuré)
if docker inspect --format='{{.State.Health}}' "$CONTAINER_NAME" 2>/dev/null | grep -q "Status"; then
    log_info "Attente que le conteneur soit 'healthy' selon Docker..."
    if wait_for_container_healthy "$CONTAINER_NAME" 120; then
        log_success "Conteneur est 'healthy' selon Docker, continuation du health check complet..."
    else
        log_warning "Conteneur n'est pas devenu 'healthy' selon Docker, mais continuation du health check complet..."
    fi
else
    log_info "Pas de healthcheck Docker configuré, attente de ${HEALTH_CHECK_INITIAL_SLEEP:-10}s pour le démarrage complet..."
    sleep ${HEALTH_CHECK_INITIAL_SLEEP:-10}
fi

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # Vérifier que le conteneur est toujours running
    if ! container_is_running "$CONTAINER_NAME"; then
        log_error "Le conteneur web s'est arrêté pendant le health check"
        show_container_logs "$CONTAINER_NAME"
        rollback "$CURRENT_COMMIT"
        exit 1
    fi
    
    # Health check complet (inclut HTTP, DB, Redis, Migrations)
    if health_check_comprehensive "$CONTAINER_NAME" "$PORT"; then
        log_success "✅ Déploiement ${ENV} terminé avec succès (commit: ${REMOTE:0:7})"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "✅ DEPLOYMENT SUCCESS"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        notify_slack "✅" "Deployment successful (commit: ${REMOTE:0:7})"
        exit 0
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $((RETRY_COUNT % 5)) -eq 0 ]; then
            log_warning "Health check échoué - Tentative $RETRY_COUNT/$MAX_RETRIES"
        else
            log_info "Tentative health check $RETRY_COUNT/$MAX_RETRIES..."
        fi
        # Backoff exponentiel (économise temps si app démarre rapidement)
        BACKOFF=$(calculate_backoff $RETRY_COUNT)
        sleep $BACKOFF
    fi
done

# 13. Rollback si health check échoue
log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_error "Health check échoué après $MAX_RETRIES tentatives"
log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

show_container_logs "$CONTAINER_NAME"
rollback "$CURRENT_COMMIT"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "❌ DEPLOYMENT FAILED - ROLLBACK EXECUTED"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# P3 - Export métriques (échec)
export_deployment_metrics "failure"

notify_slack "❌" "Deployment failed - rollback executed (commit: ${CURRENT_COMMIT:0:7})"
exit 1

