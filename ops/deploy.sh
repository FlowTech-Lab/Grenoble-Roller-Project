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
# Utiliser $0 pour obtenir le chemin du symlink (si présent), sinon BASH_SOURCE[0]
# Cela permet de détecter l'environnement même si le script est un symlink
SCRIPT_PATH="${0:-${BASH_SOURCE[0]}}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# Détecter l'environnement depuis le chemin du script (symlink ou réel)
if [[ "$SCRIPT_DIR" == *"/staging"* ]] || [[ "$0" == *"/staging"* ]]; then
    ENV="staging"
elif [[ "$SCRIPT_DIR" == *"/production"* ]] || [[ "$0" == *"/production"* ]]; then
    ENV="production"
else
    echo "❌ Erreur: Environnement non détecté (staging/production)"
    echo "   Le script doit être dans ops/staging/ ou ops/production/"
    exit 1
fi

# REPO_DIR doit pointer vers la racine du repo
# Si le script est dans ops/staging/ ou ops/production/, remonter de 2 niveaux
# Si le script est directement dans ops/, remonter d'1 niveau
if [[ "$SCRIPT_DIR" == *"/staging"* ]] || [[ "$SCRIPT_DIR" == *"/production"* ]]; then
    REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
else
    REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
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
source "${LIB_DIR}/deployment/cron.sh"
source "${LIB_DIR}/deployment/maintenance.sh"

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
export FORCE_REDEPLOY  # Exporter pour les modules (migrations.sh)

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
    
    # Arrêter les conteneurs orphelins qui pourraient bloquer les ports
    # Ces conteneurs sont des restes d'une ancienne configuration (Nginx/Certbot)
    # et ne sont plus dans le docker-compose.yml actuel qui utilise Caddy
    log_info "Détection et arrêt des conteneurs orphelins (ancienne config Nginx/Certbot)..."
    
    local orphan_found=false
    
    # Vérifier et arrêter les anciens conteneurs Nginx/Certbot s'ils existent encore (migration)
    # Ces conteneurs ne sont plus dans le docker-compose.yml actuel (migration Nginx → Caddy)
    # Note: Le conteneur Caddy actuel (grenoble-roller-caddy-production) ne doit PAS être arrêté
    for old_container in "grenoble-roller-nginx-production" "grenoble-roller-certbot-production"; do
        if $DOCKER_CMD ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${old_container}$"; then
            log_warning "⚠️  Ancien conteneur détecté (migration Nginx → Caddy) : $old_container"
            log_info "   Arrêt et suppression de $old_container..."
            $DOCKER_CMD stop "$old_container" 2>/dev/null || true
            $DOCKER_CMD rm "$old_container" 2>/dev/null || true
            orphan_found=true
        fi
    done
    
    if [ "$orphan_found" = "false" ]; then
        log_info "✅ Aucun conteneur orphelin détecté (ancienne config propre)"
    fi
    
    $DOCKER_CMD image prune -f > /dev/null 2>&1 && log_info "Images sans tag nettoyées" || true
    $DOCKER_CMD builder prune -f > /dev/null 2>&1 && log_info "Cache build nettoyé" || true
    
    # Activer le mode maintenance AVANT le build (évite downtime)
    if container_is_running "$CONTAINER_NAME"; then
        log "🔒 Activation du mode maintenance (évite downtime)..."
        enable_maintenance_mode "$CONTAINER_NAME" || log_warning "⚠️  Impossible d'activer le mode maintenance, continuation..."
    fi
    
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
    
    # Vérification post-pull (exclure les fichiers de logs qui sont ignorés par Git)
    GIT_STATUS=$(git status --porcelain 2>/dev/null | grep -vE "(logs/|ops/logs/)" || echo "")
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
    
    # 6. Décision intelligente : Rebuild ou restart ?
    # ⚠️  Détection robuste pour éviter rebuild inutile
    log "🔍 Analyse : Rebuild nécessaire ou restart suffisant ?"
    
    if needs_rebuild "$CONTAINER_NAME"; then
        log_warning "⚠️  Rebuild nécessaire détecté"
        log_warning "   Raisons possibles :"
        log_warning "   - Changements dans Gemfile, Dockerfile, database.yml"
        log_warning "   - Nouvelles migrations"
        log_warning "   - Image ancienne (>24h)"
        log_warning "   - Conteneur n'existe pas"
        
        # Rebuild directement sans confirmation (confirmation demandée seulement en cas de rollback)
        log "🔨 Build SANS CACHE..."
        log_warning "⚠️  Rebuild complet sans cache (peut prendre 5-10 minutes)"
        if ! force_rebuild_without_cache "$COMPOSE_FILE" "$CONTAINER_NAME"; then
            log_error "Échec du build - Rollback"
            rollback "$CURRENT_COMMIT"
            exit 1
        fi
    else
        log_success "✅ Pas besoin de rebuild (restart interne ou pas de changements critiques)"
        log_info "   Redémarrage du conteneur existant..."
        
        # Redémarrer le conteneur sans rebuild
        if container_exists "$CONTAINER_NAME"; then
            if container_is_running "$CONTAINER_NAME"; then
                log_info "Conteneur déjà running, restart pour appliquer les changements..."
            fi
            
            $DOCKER_CMD compose -f "$COMPOSE_FILE" restart web 2>&1 || {
                log_error "Échec du redémarrage"
                rollback "$CURRENT_COMMIT"
                exit 1
            }
            
            # Attendre que le conteneur démarre
            if ! wait_for_container_running "$CONTAINER_NAME" 120; then
                log_error "❌ Le conteneur n'a pas redémarré"
                log_warning "   Tentative de rebuild complet..."
                if ! force_rebuild_without_cache "$COMPOSE_FILE" "$CONTAINER_NAME"; then
                    log_error "Échec du build - Rollback"
                    rollback "$CURRENT_COMMIT"
                    exit 1
                fi
            else
                log_success "✅ Conteneur redémarré avec succès"
            fi
        else
            log_warning "⚠️  Conteneur n'existe pas, rebuild obligatoire..."
            if ! force_rebuild_without_cache "$COMPOSE_FILE" "$CONTAINER_NAME"; then
                log_error "Échec du build - Rollback"
                rollback "$CURRENT_COMMIT"
                exit 1
            fi
        fi
    fi
    
    # 7. Vérification POST-BUILD : migrations dans le conteneur
    # ⚠️  IMPORTANT : Le conteneur peut s'arrêter si Solid Queue ne peut pas démarrer
    #    (tables SQLite n'existent pas encore). On vérifie d'abord l'image, puis le conteneur.
    log "🔍 Vérification IMPÉRATIVE : les fichiers de migration locaux sont-ils dans le conteneur ?"
    
    # Essayer de vérifier même si le conteneur n'est pas running (utilise l'image)
    if ! verify_migrations_synced "$CONTAINER_NAME" "$MIGRATION_FILES_COUNT" "$LOCAL_MIGRATIONS_LIST"; then
        log_warning "⚠️  Vérification échouée, attente que le conteneur démarre..."
        
        # Attendre que le conteneur démarre (peut prendre du temps si Solid Queue bloque)
        if ! wait_for_container_running "$CONTAINER_NAME" 120; then
            log_error "❌ Le conteneur n'est pas stable après 120s"
            log_error "   Cause probable : Solid Queue ne peut pas démarrer (tables SQLite manquantes)"
            log_warning "   ⚠️  Relance de 'docker compose up -d' pour être sûr..."
            
            # Relancer un compose up pour être sûr
            if $DOCKER_CMD compose -f "$COMPOSE_FILE" up -d 2>&1 | tee -a "${LOG_FILE:-/dev/stdout}"; then
                log_info "✅ Services redémarrés, nouvelle attente..."
                sleep 5
                
                # Réessayer d'attendre que le conteneur démarre
                if ! wait_for_container_running "$CONTAINER_NAME" 120; then
                    log_error "❌ Le conteneur n'est toujours pas stable après relance"
                    log_error "   Solution : Les migrations SQLite seront appliquées après le démarrage"
                    log_warning "   Continuation du déploiement (migrations SQLite seront appliquées ensuite)..."
                else
                    log_success "✅ Conteneur stable après relance"
                fi
            else
                log_error "❌ Échec du redémarrage des services"
                log_error "   Solution : Les migrations SQLite seront appliquées après le démarrage"
                log_warning "   Continuation du déploiement (migrations SQLite seront appliquées ensuite)..."
            fi
        else
            # Réessayer la vérification maintenant que le conteneur est running
            sleep 3
            if ! verify_migrations_synced "$CONTAINER_NAME" "$MIGRATION_FILES_COUNT" "$LOCAL_MIGRATIONS_LIST"; then
                log_error "❌ ERREUR CRITIQUE : Migrations locales ABSENTES du conteneur"
                log_error "Rollback en cours..."
                rollback "$CURRENT_COMMIT"
                exit 1
            fi
        fi
    fi
    
    # 8. Attendre que le conteneur soit healthy
    # ⚠️  IMPORTANT : Le conteneur peut s'arrêter si Solid Queue ne peut pas démarrer
    #    (tables SQLite manquantes). Le docker-entrypoint gère maintenant cela automatiquement.
    #    Si le conteneur s'arrête, on détecte si c'est un restart interne ou un vrai problème.
    if $DOCKER_CMD inspect --format='{{.State.Health}}' "$CONTAINER_NAME" 2>/dev/null | grep -q "Status"; then
        if ! wait_for_container_healthy "$CONTAINER_NAME" ${CONTAINER_HEALTHY_WAIT:-120}; then
            log_warning "⚠️  Le conteneur n'est pas devenu healthy dans les temps"
            log_warning "   Vérification si le conteneur est running..."
            
            if ! container_is_running "$CONTAINER_NAME"; then
                # Détecter si c'est un restart interne récent
                if detect_internal_restart "$CONTAINER_NAME" 300; then
                    log_info "ℹ️  Restart interne détecté (conteneur arrêté récemment)"
                    log_info "   Redémarrage automatique du conteneur..."
                    $DOCKER_CMD compose -f "$COMPOSE_FILE" restart web 2>&1 || true
                    sleep 5
                    
                    # Réessayer d'attendre que le conteneur soit healthy
                    if ! wait_for_container_healthy "$CONTAINER_NAME" 60; then
                        log_warning "⚠️  Le conteneur n'est toujours pas healthy après restart"
                        log_warning "   ⚠️  Relance de 'docker compose up -d' pour être sûr..."
                        
                        # Relancer un compose up pour être sûr
                        if $DOCKER_CMD compose -f "$COMPOSE_FILE" up -d 2>&1 | tee -a "${LOG_FILE:-/dev/stdout}"; then
                            log_info "✅ Services redémarrés, nouvelle attente..."
                            sleep 5
                            
                            # Réessayer d'attendre que le conteneur soit healthy
                            if ! wait_for_container_healthy "$CONTAINER_NAME" 60; then
                                log_error "❌ Le conteneur n'est toujours pas healthy après relance"
                                log_error "   Vérification des logs..."
                                $DOCKER_CMD logs --tail 50 "$CONTAINER_NAME" 2>&1 | grep -i -E "error|solid.*queue|sqlite|migration" || true
                                rollback "$CURRENT_COMMIT"
                                exit 1
                            else
                                log_success "✅ Conteneur healthy après relance"
                            fi
                        else
                            log_error "❌ Échec du redémarrage des services"
                            log_error "   Vérification des logs..."
                            $DOCKER_CMD logs --tail 50 "$CONTAINER_NAME" 2>&1 | grep -i -E "error|solid.*queue|sqlite|migration" || true
                            rollback "$CURRENT_COMMIT"
                            exit 1
                        fi
                    fi
                else
                    log_error "❌ Le conteneur s'est arrêté (pas un restart interne récent)"
                    log_error "   Cause probable : Solid Queue ne peut pas démarrer (tables SQLite manquantes)"
                    log_error "   Vérification des logs..."
                    $DOCKER_CMD logs --tail 50 "$CONTAINER_NAME" 2>&1 | grep -i -E "error|solid.*queue|sqlite|migration" || true
                    log_warning "   Les migrations SQLite seront appliquées dans la prochaine étape..."
                    log_warning "   ⚠️  Relance de 'docker compose up -d' pour être sûr..."
                    
                    # Relancer un compose up pour être sûr
                    if $DOCKER_CMD compose -f "$COMPOSE_FILE" up -d 2>&1 | tee -a "${LOG_FILE:-/dev/stdout}"; then
                        log_info "✅ Services redémarrés, nouvelle attente..."
                        sleep 5
                        
                        # Réessayer d'attendre que le conteneur soit healthy
                        if ! wait_for_container_healthy "$CONTAINER_NAME" 60; then
                            log_error "❌ Le conteneur n'est toujours pas healthy après relance"
                            rollback "$CURRENT_COMMIT"
                            exit 1
                        else
                            log_success "✅ Conteneur healthy après relance"
                        fi
                    else
                        log_error "❌ Échec du redémarrage des services"
                        rollback "$CURRENT_COMMIT"
                        exit 1
                    fi
                fi
            else
                log_error "Le conteneur web n'est pas devenu healthy (mais est running)"
                rollback "$CURRENT_COMMIT"
                exit 1
            fi
        fi
    else
        log_info "Pas de healthcheck configuré, attente supplémentaire..."
        sleep 10
        
        # Vérifier que le conteneur est toujours running
        if ! container_is_running "$CONTAINER_NAME"; then
            # Détecter si c'est un restart interne
            if detect_internal_restart "$CONTAINER_NAME" 300; then
                log_info "ℹ️  Restart interne détecté, redémarrage automatique..."
                $DOCKER_CMD compose -f "$COMPOSE_FILE" restart web 2>&1 || true
                sleep 10
            else
                log_warning "⚠️  Le conteneur s'est arrêté après démarrage"
                log_warning "   Cause probable : Solid Queue ne peut pas démarrer (tables SQLite manquantes)"
                log_warning "   ⚠️  Relance de 'docker compose up -d' pour être sûr..."
                
                # Relancer un compose up pour être sûr
                if $DOCKER_CMD compose -f "$COMPOSE_FILE" up -d 2>&1 | tee -a "${LOG_FILE:-/dev/stdout}"; then
                    log_info "✅ Services redémarrés, nouvelle attente..."
                    sleep 10
                else
                    log_error "❌ Échec du redémarrage des services"
                    log_warning "   Continuation du déploiement (migrations SQLite seront appliquées)..."
                fi
            fi
        fi
    fi
    
    # 9. Analyser et appliquer les migrations
    if ! analyze_destructive_migrations "$CONTAINER_NAME"; then
        log_error "Migrations destructives détectées - Rollback"
        rollback "$CURRENT_COMMIT"
        exit 1
    fi
    
    # 9. Analyser et appliquer les migrations
    # ⚠️  IMPORTANT : Vérifier que le conteneur est running avant d'essayer les migrations
    #    Si le conteneur n'est pas running, détecter si c'est un restart interne
    if ! container_is_running "$CONTAINER_NAME"; then
        # Détecter si c'est un restart interne récent
        if detect_internal_restart "$CONTAINER_NAME" 300; then
            log_info "ℹ️  Restart interne détecté, redémarrage automatique..."
            $DOCKER_CMD compose -f "$COMPOSE_FILE" restart web 2>&1 || true
            
            # Attendre que le conteneur redémarre
            if ! wait_for_container_running "$CONTAINER_NAME" 60; then
                log_warning "⚠️  Le conteneur n'a pas redémarré avec restart"
                log_warning "   ⚠️  Relance de 'docker compose up -d' pour être sûr..."
                
                # Relancer un compose up pour être sûr
                if $DOCKER_CMD compose -f "$COMPOSE_FILE" up -d 2>&1 | tee -a "${LOG_FILE:-/dev/stdout}"; then
                    log_info "✅ Services redémarrés, nouvelle attente..."
                    sleep 5
                    
                    # Réessayer d'attendre que le conteneur redémarre
                    if ! wait_for_container_running "$CONTAINER_NAME" 60; then
                        log_error "❌ Le conteneur n'a toujours pas redémarré après relance"
                        log_error "   Vérification des logs..."
                        $DOCKER_CMD logs --tail 50 "$CONTAINER_NAME" 2>&1 | tail -20 || true
                        rollback "$CURRENT_COMMIT"
                        exit 1
                    else
                        log_success "✅ Conteneur running après relance"
                    fi
                else
                    log_error "❌ Échec du redémarrage des services"
                    log_error "   Vérification des logs..."
                    $DOCKER_CMD logs --tail 50 "$CONTAINER_NAME" 2>&1 | tail -20 || true
                    rollback "$CURRENT_COMMIT"
                    exit 1
                fi
            fi
            sleep 5
        else
            log_error "❌ Le conteneur n'est pas running, impossible d'appliquer les migrations"
            log_warning "   ⚠️  Tentative de relance de 'docker compose up -d' pour être sûr..."
            
            # Relancer un compose up pour être sûr
            if $DOCKER_CMD compose -f "$COMPOSE_FILE" up -d 2>&1 | tee -a "${LOG_FILE:-/dev/stdout}"; then
                log_info "✅ Services redémarrés, nouvelle attente..."
                sleep 5
                
                # Réessayer de vérifier que le conteneur est running
                if ! container_is_running "$CONTAINER_NAME"; then
                    log_error "❌ Le conteneur n'est toujours pas running après relance"
                    log_error "   Vérification des logs..."
                    $DOCKER_CMD logs --tail 50 "$CONTAINER_NAME" 2>&1 | tail -20 || true
                    log_error "   Rollback en cours..."
                    rollback "$CURRENT_COMMIT"
                    exit 1
                else
                    log_success "✅ Conteneur running après relance"
                fi
            else
                log_error "❌ Échec du redémarrage des services"
                log_error "   Vérification des logs..."
                $DOCKER_CMD logs --tail 50 "$CONTAINER_NAME" 2>&1 | tail -20 || true
                log_error "   Rollback en cours..."
                rollback "$CURRENT_COMMIT"
                exit 1
            fi
        fi
    fi
    
    if ! analyze_destructive_migrations "$CONTAINER_NAME"; then
        log_error "Migrations destructives détectées - Rollback"
        rollback "$CURRENT_COMMIT"
        exit 1
    fi
    
    # Calculer timeout adaptatif
    MIGRATION_STATUS=$($DOCKER_CMD exec "$CONTAINER_NAME" bin/rails db:migrate:status 2>&1)
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
    
    # ⚠️  IMPORTANT : Vérifier que le conteneur est toujours running après les migrations
    #    (Solid Queue peut avoir crashé si les tables SQLite n'existent pas)
    #    Détecter si c'est un restart interne ou un vrai problème
    if ! container_is_running "$CONTAINER_NAME"; then
        # Détecter si c'est un restart interne récent
        if detect_internal_restart "$CONTAINER_NAME" 300; then
            log_info "ℹ️  Restart interne détecté après migrations, redémarrage automatique..."
            $DOCKER_CMD compose -f "$COMPOSE_FILE" restart web 2>&1 || true
        else
            log_warning "⚠️  Le conteneur s'est arrêté après les migrations"
            log_warning "   Cause probable : Solid Queue ne peut pas démarrer (tables SQLite manquantes)"
            log_warning "   ⚠️  Relance de 'docker compose up -d' pour être sûr..."
            
            # Relancer un compose up pour être sûr
            if $DOCKER_CMD compose -f "$COMPOSE_FILE" up -d 2>&1 | tee -a "${LOG_FILE:-/dev/stdout}"; then
                log_info "✅ Services redémarrés, nouvelle attente..."
            else
                log_warning "⚠️  Échec du redémarrage, continuation..."
            fi
        fi
        
        # Attendre que le conteneur redémarre
        if ! wait_for_container_running "$CONTAINER_NAME" 60; then
            log_warning "⚠️  Le conteneur n'a pas redémarré avec restart/up"
            log_warning "   ⚠️  Dernière tentative avec 'docker compose up -d'..."
            
            # Dernière tentative avec compose up
            if $DOCKER_CMD compose -f "$COMPOSE_FILE" up -d 2>&1 | tee -a "${LOG_FILE:-/dev/stdout}"; then
                sleep 5
                if ! wait_for_container_running "$CONTAINER_NAME" 60; then
                    log_error "❌ Le conteneur n'a toujours pas redémarré après toutes les tentatives"
                    rollback "$CURRENT_COMMIT"
                    exit 1
                else
                    log_success "✅ Conteneur running après dernière tentative"
                fi
            else
                log_error "❌ Échec définitif du redémarrage"
                rollback "$CURRENT_COMMIT"
                exit 1
            fi
        fi
        
        sleep 5
    fi
    
    # 10. Installation/mise à jour du crontab
    log "⏰ Installation/mise à jour du crontab..."
    if ! install_crontab; then
        log_warning "⚠️  Échec de l'installation du crontab - Continuation du déploiement"
        log_info "   Le crontab peut être installé manuellement avec: bundle exec whenever --update-crontab"
    fi
    
    # 11. Désactiver le mode maintenance AVANT le health check
    log "🔓 Désactivation du mode maintenance..."
    disable_maintenance_mode "$CONTAINER_NAME" || log_warning "⚠️  Impossible de désactiver le mode maintenance, continuation..."
    
    # 12. Health check final avec retry
    log "🏥 Health check complet avec retry..."
    MAX_RETRIES=${HEALTH_CHECK_MAX_RETRIES:-60}
    RETRY_COUNT=0
    
    # Note: curl n'est pas nécessaire sur l'hôte car le health check teste depuis le conteneur
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
    
    # 13. Rollback si health check échoue
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

