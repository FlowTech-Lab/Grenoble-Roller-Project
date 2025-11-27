#!/bin/bash
###############################################################################
# Script de déploiement automatique STAGING/PRODUCTION
# Usage: ./ops/staging/deploy.sh [--force] ou ./ops/production/deploy.sh [--force]
# Auto-détecte l'environnement depuis le chemin du script
###############################################################################

set -euo pipefail  # Mode strict : erreur, variable non définie, pipefail

# ============================================================================
# DÉTECTION AUTOMATIQUE DE L'ENVIRONNEMENT
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Détecter l'environnement depuis le chemin du script
if [[ "$SCRIPT_DIR" == *"/staging"* ]]; then
    ENV="staging"
elif [[ "$SCRIPT_DIR" == *"/production"* ]]; then
    ENV="production"
else
    echo "❌ Erreur: Environnement non détecté (staging/production)"
    echo "   Le script doit être dans ops/staging/ ou ops/production/"
    exit 1
fi

# ============================================================================
# CHARGEMENT DE LA CONFIGURATION
# ============================================================================
CONFIG_FILE="${SCRIPT_DIR}/../config/${ENV}.env"
if [ -f "$CONFIG_FILE" ]; then
    set -a  # Auto-export des variables
    source "$CONFIG_FILE"
    set +a
else
    echo "❌ Erreur: Fichier de configuration introuvable: ${CONFIG_FILE}"
    exit 1
fi

# Résoudre les chemins absolus
REPO_DIR="$(cd "${REPO_DIR}" && pwd)"
COMPOSE_FILE="${REPO_DIR}/${COMPOSE_FILE}"
BACKUP_DIR="${REPO_DIR}/${BACKUP_DIR}"
LOG_FILE="${REPO_DIR}/${LOG_FILE}"
LOG_JSON_FILE="${REPO_DIR}/${LOG_JSON_FILE}"

# Créer les répertoires nécessaires
mkdir -p "$BACKUP_DIR" "$(dirname "$LOG_FILE")" "$(dirname "$LOG_JSON_FILE")"

# ============================================================================
# CHARGEMENT DES MODULES (ordre important)
# ============================================================================
LIB_DIR="${SCRIPT_DIR}/../lib"

# Core (pas de dépendances)
source "${LIB_DIR}/core/colors.sh"
source "${LIB_DIR}/core/logging.sh"
source "${LIB_DIR}/core/utils.sh"

# Security
source "${LIB_DIR}/security/credentials.sh"

# Docker
source "${LIB_DIR}/docker/containers.sh"
source "${LIB_DIR}/docker/images.sh"
source "${LIB_DIR}/docker/compose.sh"

# Database
source "${LIB_DIR}/database/backup.sh"
source "${LIB_DIR}/database/restore.sh"
source "${LIB_DIR}/database/migrations.sh"

# Health
source "${LIB_DIR}/health/waiters.sh"
source "${LIB_DIR}/health/checks.sh"

# Deployment
source "${LIB_DIR}/deployment/rollback.sh"
source "${LIB_DIR}/deployment/metrics.sh"

# Blue-green (lazy loading)
if [ "${BLUE_GREEN_ENABLED:-false}" = "true" ]; then
    if [ -f "${LIB_DIR}/deployment/blue_green.sh" ]; then
        source "${LIB_DIR}/deployment/blue_green.sh"
    else
        log_warning "⚠️  Blue-green activé mais module non trouvé"
    fi
fi

# ============================================================================
# INITIALISATION
# ============================================================================
DEPLOYMENT_ID=$(generate_deployment_id)
export DEPLOYMENT_ID

# Charger les Rails credentials
if ! load_rails_credentials "$ENV"; then
    if [ "$ENV" = "staging" ]; then
        log_warning "Continuation sans chiffrement (staging)"
        BACKUP_ENCRYPTION_ENABLED="false"
    else
        log_error "Master key requise en production"
        exit 1
    fi
fi

# Détection du mode d'exécution (manuel vs automatique/cron)
FORCE_REDEPLOY=false
if [ -t 0 ] && [ "$#" -gt 0 ] && [ "$1" = "--force" ]; then
    FORCE_REDEPLOY=true
fi

# Initialiser variables pour métriques
REMOTE=""
MIGRATION_DURATION=0
export MIGRATION_DURATION

# ============================================================================
# WORKFLOW PRINCIPAL
# ============================================================================
main() {
    # Aller dans le répertoire du projet
    cd "$REPO_DIR" || exit 1
    
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
        exit 1
    fi
    
    # Timestamp de début
    DEPLOY_START_TIME=$(date +%s)
    export DEPLOY_START_TIME
    
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "🚀 DEPLOYMENT START - ${ENV} - $(date '+%Y-%m-%d %H:%M:%S')"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Nettoyage préventif
    log "🧹 Nettoyage préventif Docker..."
    docker image prune -f > /dev/null 2>&1 && log_info "Images sans tag nettoyées" || true
    docker builder prune -f > /dev/null 2>&1 && log_info "Cache build nettoyé" || true
    
    # 1. Vérifier les mises à jour Git
    log "📥 Vérification des mises à jour (branche: ${BRANCH})..."
    git fetch origin
    
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse "origin/${BRANCH}" 2>/dev/null || echo "$LOCAL")
    
    if [ "$LOCAL" = "$REMOTE" ]; then
        log "✅ Déjà à jour (commit: ${LOCAL:0:7})"
        
        if [ "$FORCE_REDEPLOY" = true ]; then
            log_info "Mode FORCE activé, continuation du redéploiement..."
        elif [ -t 0 ]; then
            log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log_warning "⚠️  Déjà à jour - Voulez-vous forcer le redéploiement ?"
            log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            read -t 30 -p "Votre choix (o/N, défaut: N) : " choice || choice="N"
            if [[ "$choice" =~ ^[OoYy]$ ]]; then
                FORCE_REDEPLOY=true
            else
                log_info "Déploiement annulé"
                exit 0
            fi
        else
            log_info "Mode automatique détecté - Skip du redéploiement (déjà à jour)"
            exit 0
        fi
    else
        log "🆕 Nouvelle version détectée (${LOCAL:0:7} → ${REMOTE:0:7})"
    fi
    
    # Sauvegarder le commit actuel (pour rollback)
    CURRENT_COMMIT=$(git rev-parse HEAD)
    log "💾 Commit actuel sauvegardé: ${CURRENT_COMMIT:0:7}"
    
    # 2. Backup base de données
    if ! backup_database; then
        log_error "Échec du backup - Rollback"
        rollback "$CURRENT_COMMIT"
        exit 1
    fi
    
    # 3. Git pull
    log "📥 Mise à jour du code..."
    if ! git pull origin "$BRANCH"; then
        log_error "Échec du git pull - Rollback"
        rollback "$CURRENT_COMMIT"
        exit 1
    fi
    
    # Vérification post-pull
    GIT_STATUS=$(git status --porcelain 2>/dev/null || echo "")
    if [ -n "$GIT_STATUS" ]; then
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "⚠️  CONFLITS OU CHANGEMENTS NON COMMITTÉS DÉTECTÉS"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        rollback "$CURRENT_COMMIT"
        exit 1
    fi
    
    # 4. Vérification espace disque
    log "💾 Vérification de l'espace disque..."
    if ! check_disk_space ${DISK_SPACE_REQUIRED:-5} "$REPO_DIR"; then
        log_warning "⚠️  Espace disque faible, nettoyage préventif..."
        cleanup_docker
        if ! check_disk_space ${DISK_SPACE_MIN_AFTER_CLEANUP:-3} "$REPO_DIR"; then
            log_error "❌ Espace disque insuffisant même après nettoyage"
            rollback "$CURRENT_COMMIT"
            exit 1
        fi
    fi
    
    # 5. Vérification migrations avant build
    log "🔍 Vérification des fichiers de migration avant build..."
    LOCAL_MIGRATIONS_LIST=$(find "$REPO_DIR/db/migrate" -name "*.rb" -type f -exec basename {} \; 2>/dev/null | sort)
    MIGRATION_FILES_COUNT=$(echo "$LOCAL_MIGRATIONS_LIST" | wc -l | tr -d ' ')
    
    if [ "$MIGRATION_FILES_COUNT" -eq 0 ]; then
        log_error "❌ Aucun fichier de migration trouvé dans db/migrate/"
        rollback "$CURRENT_COMMIT"
        exit 1
    fi
    
    log_info "✅ ${MIGRATION_FILES_COUNT} fichier(s) de migration trouvé(s) localement"
    
    # 6. Build
    log "🔍 Vérification finale de la branche Git avant build..."
    CURRENT_BRANCH_FINAL=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [ "$CURRENT_BRANCH_FINAL" != "$BRANCH" ]; then
        log_error "❌ ERREUR : Branche incorrecte avant build"
        log_error "Branche actuelle: ${CURRENT_BRANCH_FINAL}, attendue: ${BRANCH}"
        if ! git checkout "$BRANCH" 2>/dev/null; then
            rollback "$CURRENT_COMMIT"
            exit 1
        fi
    fi
    
    # Décider du type de build
    NEED_NO_CACHE_BUILD=false
    if container_is_running "$CONTAINER_NAME"; then
        CURRENT_CONTAINER_MIGRATIONS=$(docker exec "$CONTAINER_NAME" find /rails/db/migrate -name "*.rb" -type f -exec basename {} \; 2>/dev/null | sort || echo "")
        if [ -n "$CURRENT_CONTAINER_MIGRATIONS" ]; then
            CURRENT_COUNT=$(echo "$CURRENT_CONTAINER_MIGRATIONS" | wc -l | tr -d ' ')
            NEW_IN_LOCAL=$(comm -23 <(echo "$LOCAL_MIGRATIONS_LIST") <(echo "$CURRENT_CONTAINER_MIGRATIONS") || echo "")
            
            if [ -n "$NEW_IN_LOCAL" ] || [ "$MIGRATION_FILES_COUNT" -ne "$CURRENT_COUNT" ]; then
                log_warning "⚠️  Nouvelles migrations détectées - Rebuild sans cache OBLIGATOIRE"
                NEED_NO_CACHE_BUILD=true
            fi
        fi
    fi
    
    if [ "$NEED_NO_CACHE_BUILD" = true ] || needs_no_cache_build; then
        log "🔨 Build SANS CACHE (nouvelles migrations ou changements critiques)..."
        if ! force_rebuild_without_cache "$COMPOSE_FILE" "$CONTAINER_NAME"; then
            log_error "Échec du build - Rollback"
            rollback "$CURRENT_COMMIT"
            exit 1
        fi
    else
        log "🔨 Build et redémarrage (cache activé)..."
        if ! docker_compose_build "$COMPOSE_FILE"; then
            log_error "Échec du build - Rollback"
            rollback "$CURRENT_COMMIT"
            exit 1
        fi
    fi
    
    # 7. Vérification POST-BUILD : migrations dans le conteneur
    log "🔍 Vérification IMPÉRATIVE : les fichiers de migration locaux sont-ils dans le conteneur ?"
    if ! wait_for_container_running "$CONTAINER_NAME" 60; then
        log_error "❌ Le conteneur n'est pas stable"
        rollback "$CURRENT_COMMIT"
        exit 1
    fi
    
    sleep 3
    
    if ! verify_migrations_synced "$CONTAINER_NAME" "$MIGRATION_FILES_COUNT" "$LOCAL_MIGRATIONS_LIST"; then
        log_error "❌ ERREUR CRITIQUE : Migrations locales ABSENTES du conteneur"
        log_error "Rollback en cours..."
        rollback "$CURRENT_COMMIT"
        exit 1
    fi
    
    # 8. Attendre que le conteneur soit healthy
    if docker inspect --format='{{.State.Health}}' "$CONTAINER_NAME" 2>/dev/null | grep -q "Status"; then
        if ! wait_for_container_healthy "$CONTAINER_NAME" ${CONTAINER_HEALTHY_WAIT:-120}; then
            log_error "Le conteneur web n'est pas devenu healthy"
            rollback "$CURRENT_COMMIT"
            exit 1
        fi
    else
        log_info "Pas de healthcheck configuré, attente supplémentaire..."
        sleep 10
    fi
    
    # 9. Analyser et appliquer les migrations
    if ! analyze_destructive_migrations "$CONTAINER_NAME"; then
        log_error "Migrations destructives détectées - Rollback"
        rollback "$CURRENT_COMMIT"
        exit 1
    fi
    
    # Calculer timeout adaptatif
    MIGRATION_STATUS=$(docker exec "$CONTAINER_NAME" bin/rails db:migrate:status 2>&1)
    PENDING_MIGRATIONS=$(echo "$MIGRATION_STATUS" | grep "^\s*down" || echo "")
    PENDING_COUNT=$(echo "$PENDING_MIGRATIONS" | wc -l | tr -d ' ')
    MIGRATION_TIMEOUT=$(calculate_migration_timeout $PENDING_COUNT)
    
    if [ "$PENDING_COUNT" -gt 0 ]; then
        log "🕐 Timeout migration adaptatif : ${MIGRATION_TIMEOUT}s pour ${PENDING_COUNT} migration(s)"
        if ! apply_migrations "$CONTAINER_NAME" "$MIGRATION_TIMEOUT"; then
            log_error "Échec des migrations - Rollback"
            rollback "$CURRENT_COMMIT"
            exit 1
        fi
    else
        log_success "✅ Aucune migration en attente"
    fi
    
    # 10. Health check final avec retry
    log "🏥 Health check complet avec retry..."
    MAX_RETRIES=${HEALTH_CHECK_MAX_RETRIES:-60}
    RETRY_COUNT=0
    
    if ! command -v curl > /dev/null 2>&1; then
        log_error "curl n'est pas disponible sur le système"
        rollback "$CURRENT_COMMIT"
        exit 1
    fi
    
    sleep ${HEALTH_CHECK_INITIAL_SLEEP:-10}
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if ! container_is_running "$CONTAINER_NAME"; then
            log_error "Le conteneur web s'est arrêté pendant le health check"
            rollback "$CURRENT_COMMIT"
            exit 1
        fi
        
        if health_check_comprehensive "$CONTAINER_NAME" "$PORT"; then
            log_success "✅ Déploiement ${ENV} terminé avec succès (commit: ${REMOTE:0:7})"
            log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            log "✅ DEPLOYMENT SUCCESS"
            log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            export_deployment_metrics "success"
            exit 0
        else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [ $((RETRY_COUNT % 5)) -eq 0 ]; then
                log_warning "Health check échoué - Tentative $RETRY_COUNT/$MAX_RETRIES"
            fi
            # Backoff exponentiel
            local backoff=$((2 ** (RETRY_COUNT / 5)))
            backoff=$((backoff > ${HEALTH_CHECK_BACKOFF_MAX:-10} ? ${HEALTH_CHECK_BACKOFF_MAX:-10} : backoff))
            sleep $backoff
        fi
    done
    
    # 11. Rollback si health check échoue
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_error "Health check échoué après $MAX_RETRIES tentatives"
    log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    export_deployment_metrics "failure"
    rollback "$CURRENT_COMMIT"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "❌ DEPLOYMENT FAILED - ROLLBACK EXECUTED"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
}

# Gestion erreurs globale
trap 'export_deployment_metrics "failure"; exit 1' ERR

# Exécution
main "$@"

