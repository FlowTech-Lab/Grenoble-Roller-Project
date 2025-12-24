#!/bin/bash
###############################################################################
# Module: deployment/rollback.sh
# Description: Rollback transactionnel (code + DB) vers un commit précédent
# Dependencies: 
#   - core/logging.sh
#   - core/utils.sh (check_disk_space, prompt_with_timeout)
#   - docker/containers.sh (container_is_running_stable)
#   - docker/images.sh (cleanup_docker)
#   - database/restore.sh (restore_database_from_backup)
#   - health/checks.sh (health_check_comprehensive)
#   - Variables: DB_BACKUP, BLUE_GREEN_ENABLED, COMPOSE_FILE, BLUE_GREEN_COMPOSE_FILE, CONTAINER_NAME, PORT, REPO_DIR, ENV
# Author: FlowTech Lab
# Version: 1.0.0
###############################################################################

rollback() {
    local current_commit=$1
    local backup_file="${DB_BACKUP:-}"
    local repo_dir=${REPO_DIR:-.}
    
    log_warning "🔄 Rollback transactionnel vers commit ${current_commit:0:7}..."
    
    # Vérifier l'espace disque avant rollback
    if ! check_disk_space 2 "$repo_dir"; then
        log_warning "⚠️  Espace disque faible, nettoyage avant rollback..."
        cleanup_docker
    fi
    
    # 1. Activer le mode maintenance AVANT d'arrêter (évite downtime si possible)
    log_info "🔒 Activation du mode maintenance avant rollback..."
    if container_is_running "${CONTAINER_NAME:-}"; then
        if command -v enable_maintenance_mode > /dev/null 2>&1; then
            enable_maintenance_mode "${CONTAINER_NAME}" || log_warning "⚠️  Impossible d'activer le mode maintenance"
        fi
    fi
    
    # 2. Arrêter l'app immédiatement (éviter corruption)
    log_info "🛑 Arrêt de l'application pour éviter corruption..."
    if [ "${BLUE_GREEN_ENABLED:-false}" = "true" ]; then
        $DOCKER_CMD compose -f "${BLUE_GREEN_COMPOSE_FILE}" stop web-blue web-green 2>/dev/null || true
    else
        $DOCKER_CMD compose -f "${COMPOSE_FILE}" stop "${CONTAINER_NAME}" 2>/dev/null || true
    fi
    
    # 3. Restaurer DB AVANT le code (ordre critique)
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
    
    # 4. Restaurer code
    log_info "📝 Restauration du code vers ${current_commit:0:7}..."
    if ! git -C "$repo_dir" checkout "$current_commit" 2>/dev/null; then
        log_error "Échec du checkout vers ${current_commit:0:7}"
        if git -C "$repo_dir" checkout "$current_commit" 2>&1 | grep -qi "no space\|disk full"; then
            log_error "Échec probablement dû à l'espace disque"
            cleanup_docker
            if ! git -C "$repo_dir" checkout "$current_commit" 2>/dev/null; then
                log_error "Échec définitif du checkout - Intervention manuelle requise"
                return 1
            fi
        else
            return 1
        fi
    fi
    
    # 5. Demander confirmation avant de relancer l'ancien conteneur
    # ⚠️  IMPORTANT : Confirmation demandée ici, pas au début du déploiement
    #    - Staging : défaut NON, timeout 120s
    #    - Production : défaut OUI, timeout 120s
    log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_warning "🔄 Le déploiement a échoué, rollback vers l'ancienne version"
    log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local default_answer="yes"
    if [ "${ENV:-}" = "staging" ]; then
        default_answer="no"
    fi
    
    if ! prompt_with_timeout "Voulez-vous relancer l'ancien conteneur (rollback) ?" 120 "$default_answer"; then
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_error "❌ Rollback annulé par l'opérateur"
        log_error "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_warning "💡 L'application reste arrêtée"
        log_warning "   Intervention manuelle requise"
        return 1
    fi
    
    # 6. Rebuild et démarrage avec l'ancienne version
    log_info "🔨 Rebuild et démarrage avec l'ancienne version..."
    local build_output
    local build_exit_code
    
    if [ "${BLUE_GREEN_ENABLED:-false}" = "true" ]; then
        # En blue-green, redémarrer l'environnement actif
        if command -v get_active_environment > /dev/null 2>&1; then
            local active_env=$(get_active_environment)
            if [ "$active_env" != "none" ]; then
                build_output=$($DOCKER_CMD compose -f "${BLUE_GREEN_COMPOSE_FILE}" up -d --build "web-${active_env}" 2>&1)
            else
                build_output=$($DOCKER_CMD compose -f "${BLUE_GREEN_COMPOSE_FILE}" up -d --build web-blue 2>&1)
            fi
        else
            build_output=$($DOCKER_CMD compose -f "${BLUE_GREEN_COMPOSE_FILE}" up -d --build web-blue 2>&1)
        fi
    else
        build_output=$($DOCKER_CMD compose -f "${COMPOSE_FILE}" up -d --build 2>&1)
    fi
    build_exit_code=$?
    
    if [ $build_exit_code -ne 0 ]; then
        log_error "Échec du rebuild/restart lors du rollback"
        return 1
    fi
    
    # 7. Désactiver le mode maintenance après rollback réussi
    log_info "🔓 Désactivation du mode maintenance..."
    if container_is_running_stable "$container_to_check"; then
        if command -v disable_maintenance_mode > /dev/null 2>&1; then
            disable_maintenance_mode "$container_to_check" || log_warning "⚠️  Impossible de désactiver le mode maintenance"
        fi
    fi
    
    # 8. Vérification sanity (health check)
    log_info "🔍 Vérification de l'état après rollback..."
    sleep 5  # Attendre le démarrage
    
    local container_to_check=""
    if [ "${BLUE_GREEN_ENABLED:-false}" = "true" ]; then
        if command -v get_active_environment > /dev/null 2>&1; then
            container_to_check="grenoble-roller-${ENV:-staging}-$(get_active_environment)"
        else
            container_to_check="${CONTAINER_NAME}"
        fi
    else
        container_to_check="${CONTAINER_NAME}"
    fi
    
    if container_is_running_stable "$container_to_check"; then
        local check_port=${PORT:-3000}
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

