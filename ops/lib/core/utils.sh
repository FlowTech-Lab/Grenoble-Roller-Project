#!/bin/bash
###############################################################################
# Module: core/utils.sh
# Description: Fonctions utilitaires génériques
# Dependencies: core/logging.sh
# Author: FlowTech Lab
# Version: 1.0.0
###############################################################################

# Fonction pour afficher les logs d'un conteneur en cas d'erreur
show_container_logs() {
    local container_name=$1
    local lines=${2:-50}
    
    log_error "=== Dernières ${lines} lignes des logs de ${container_name} ==="
    $DOCKER_CMD logs --tail "$lines" "$container_name" 2>&1 | tee -a "${LOG_FILE:-/dev/stdout}" || true
    log_error "=== Fin des logs ==="
}

# Fonction pour vérifier l'espace disque disponible
check_disk_space() {
    local required_gb=${1:-5}
    local repo_dir=${2:-${REPO_DIR:-.}}
    local available_space
    
    # Récupérer l'espace disponible (en GB)
    if command -v df > /dev/null 2>&1; then
        available_space=$(df -BG "$repo_dir" 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/G//' || echo "0")
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

# Fonction pour générer un ID de déploiement unique
generate_deployment_id() {
    echo "deploy-$(date +%Y%m%d-%H%M%S)-${RANDOM}"
}

# Fonction pour demander confirmation avec timeout
# Usage: prompt_with_timeout "message" timeout_seconds default_answer
# default_answer: "yes" ou "no"
# Retourne: 0 si oui, 1 si non
prompt_with_timeout() {
    local message=$1
    local timeout_seconds=${2:-120}
    local default_answer=${3:-no}
    local default_upper=$(echo "$default_answer" | tr '[:lower:]' '[:upper:]')
    
    # Si on n'est pas en mode interactif, utiliser la valeur par défaut
    if [ ! -t 0 ] || [ ! -t 1 ]; then
        log_info "Mode non-interactif détecté, utilisation de la valeur par défaut: ${default_answer}"
        if [ "$default_answer" = "yes" ]; then
            return 0
        else
            return 1
        fi
    fi
    
    # Afficher le message avec la valeur par défaut
    if [ "$default_answer" = "yes" ]; then
        local prompt_text="${message} (O/n, timeout: ${timeout_seconds}s, défaut: OUI) : "
    else
        local prompt_text="${message} (o/N, timeout: ${timeout_seconds}s, défaut: NON) : "
    fi
    
    log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_warning "$message"
    log_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_warning "Timeout: ${timeout_seconds} secondes (défaut: ${default_upper})"
    
    # Utiliser read avec timeout
    local answer=""
    if read -t "$timeout_seconds" -p "$prompt_text" answer; then
        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]' | xargs)
    else
        # Timeout atteint
        log_warning "⏱️  Timeout atteint (${timeout_seconds}s), utilisation de la valeur par défaut: ${default_upper}"
        answer="$default_answer"
    fi
    
    # Si réponse vide, utiliser la valeur par défaut
    if [ -z "$answer" ]; then
        answer="$default_answer"
    fi
    
    # Vérifier la réponse
    case "$answer" in
        o|oui|y|yes|oui)
            log_info "✅ Confirmation: OUI"
            return 0
            ;;
        n|non|no|non)
            log_info "❌ Confirmation: NON"
            return 1
            ;;
        *)
            # Réponse invalide, utiliser la valeur par défaut
            log_warning "⚠️  Réponse invalide '${answer}', utilisation de la valeur par défaut: ${default_upper}"
            if [ "$default_answer" = "yes" ]; then
                return 0
            else
                return 1
            fi
            ;;
    esac
}

# Détecter si un conteneur s'est arrêté récemment (restart interne)
# Retourne: 0 si restart interne détecté, 1 sinon
detect_internal_restart() {
    local container_name=$1
    local max_restart_age=${2:-300}  # 5 minutes par défaut
    
    # Vérifier si le conteneur existe
    if ! container_exists "$container_name"; then
        return 1  # Pas de restart interne si le conteneur n'existe pas
    fi
    
    # Vérifier l'état du conteneur
    local container_status=$($DOCKER_CMD inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null || echo "unknown")
    
    if [ "$container_status" = "running" ]; then
        # Conteneur running, vérifier s'il a redémarré récemment
        local started_at=$($DOCKER_CMD inspect --format='{{.State.StartedAt}}' "$container_name" 2>/dev/null || echo "")
        if [ -n "$started_at" ]; then
            # Convertir en timestamp Unix (nécessite date -d ou équivalent)
            local started_timestamp=$(date -d "$started_at" +%s 2>/dev/null || echo "0")
            local current_timestamp=$(date +%s)
            local age=$((current_timestamp - started_timestamp))
            
            if [ "$age" -lt "$max_restart_age" ]; then
                log_info "ℹ️  Conteneur redémarré récemment (il y a ${age}s)"
                return 0  # Restart interne détecté
            fi
        fi
        return 1  # Pas de restart récent
    elif [ "$container_status" = "exited" ]; then
        # Conteneur arrêté, vérifier depuis quand
        local finished_at=$($DOCKER_CMD inspect --format='{{.State.FinishedAt}}' "$container_name" 2>/dev/null || echo "")
        if [ -n "$finished_at" ]; then
            local finished_timestamp=$(date -d "$finished_at" +%s 2>/dev/null || echo "0")
            local current_timestamp=$(date +%s)
            local age=$((current_timestamp - finished_timestamp))
            
            if [ "$age" -lt "$max_restart_age" ]; then
                log_info "ℹ️  Conteneur arrêté récemment (il y a ${age}s)"
                return 0  # Restart interne détecté
            fi
        fi
        return 1  # Arrêt ancien, pas un restart interne
    fi
    
    return 1  # État inconnu, pas un restart interne
}

# Détecter si un rebuild est vraiment nécessaire
# Vérifie les changements dans Gemfile, database.yml, Dockerfile, etc.
needs_rebuild() {
    local repo_dir=${REPO_DIR:-.}
    local container_name=$1
    
    # 1. Vérifier si le conteneur n'existe pas → rebuild nécessaire
    if ! container_exists "$container_name"; then
        log_info "ℹ️  Conteneur n'existe pas → rebuild nécessaire"
        return 0
    fi
    
    # 2. Vérifier si c'est un restart interne récent → pas besoin de rebuild
    if detect_internal_restart "$container_name" 300; then
        log_info "ℹ️  Restart interne détecté → pas besoin de rebuild"
        return 1
    fi
    
    # 3. Vérifier les changements critiques dans le code
    local changes=$(git -C "$repo_dir" diff --name-only HEAD@{1} HEAD 2>/dev/null || \
                   git -C "$repo_dir" diff --name-only origin/${BRANCH:-main} HEAD 2>/dev/null || \
                   echo "")
    
    # Fichiers critiques qui nécessitent un rebuild
    if echo "$changes" | grep -qE '^(Gemfile|Gemfile\.lock|Dockerfile|Dockerfile\.dev|package\.json|package-lock\.json|yarn\.lock|config/database\.yml|config/solid_queue\.yml|bin/docker-entrypoint)'; then
        log_warning "⚠️  Changements critiques détectés nécessitant un rebuild"
        return 0
    fi
    
    # 4. Vérifier si l'image est ancienne (plus de 24h)
    local image_id=$($DOCKER_CMD inspect --format='{{.Image}}' "$container_name" 2>/dev/null || echo "")
    if [ -n "$image_id" ]; then
        local image_created=$($DOCKER_CMD inspect --format='{{.Created}}' "$image_id" 2>/dev/null || echo "")
        if [ -n "$image_created" ]; then
            local image_timestamp=$(date -d "$image_created" +%s 2>/dev/null || echo "0")
            local current_timestamp=$(date +%s)
            local image_age=$((current_timestamp - image_timestamp))
            local max_age=$((24 * 3600))  # 24 heures
            
            if [ "$image_age" -gt "$max_age" ]; then
                log_info "ℹ️  Image ancienne (${image_age}s) → rebuild recommandé"
                return 0
            fi
        fi
    fi
    
    # 5. Vérifier les migrations (si nouvelles migrations, rebuild nécessaire)
    if container_is_running "$container_name"; then
        local container_migrations=$($DOCKER_CMD exec "$container_name" find /rails/db/migrate -name "*.rb" -type f 2>/dev/null | wc -l | tr -d ' ')
        local local_migrations=$(find "$repo_dir/db/migrate" -name "*.rb" -type f 2>/dev/null | wc -l | tr -d ' ')
        
        if [ "$local_migrations" -gt "$container_migrations" ]; then
            log_warning "⚠️  Nouvelles migrations détectées (local: ${local_migrations}, conteneur: ${container_migrations})"
            return 0
        fi
    fi
    
    # Pas besoin de rebuild
    return 1
}

