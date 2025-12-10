#!/bin/bash
###############################################################################
# Module: docker/containers.sh
# Description: Gestion des conteneurs Docker
# Dependencies: 
#   - core/logging.sh
#   - health/waiters.sh (wait_for_container_running)
# Author: FlowTech Lab
# Version: 1.0.0
###############################################################################

# Détecter automatiquement si sudo est nécessaire pour docker
_detect_docker_cmd() {
    # Si DOCKER_CMD est déjà défini, l'utiliser
    if [ -n "${DOCKER_CMD:-}" ]; then
        echo "$DOCKER_CMD"
        return
    fi
    
    # Si on est root (via sudo), docker devrait fonctionner directement
    if [ "$(id -u)" -eq 0 ]; then
        if docker ps >/dev/null 2>&1; then
            echo "docker"
            return
        fi
    fi
    
    # Tester si docker fonctionne sans sudo
    if docker ps >/dev/null 2>&1; then
        echo "docker"
    # Sinon, tester avec sudo (si disponible)
    elif command -v sudo >/dev/null 2>&1 && sudo docker ps >/dev/null 2>&1; then
        echo "sudo docker"
    else
        # Fallback : docker (échouera avec un message d'erreur clair)
        echo "docker"
    fi
}

# Initialiser DOCKER_CMD une seule fois (export pour que les autres modules l'utilisent)
if [ -z "${DOCKER_CMD_INITIALIZED:-}" ]; then
    export DOCKER_CMD=$(_detect_docker_cmd)
    export DOCKER_CMD_INITIALIZED=1
fi

# Vérifier si un conteneur est running
container_is_running() {
    local container_name=$1
    # Capturer les erreurs pour debug si nécessaire
    local output
    output=$($DOCKER_CMD ps --format '{{.Names}}' 2>&1)
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        # Si erreur de permission, essayer avec sudo explicitement
        if echo "$output" | grep -q "permission denied\|Cannot connect to the Docker daemon"; then
            if command -v sudo >/dev/null 2>&1; then
                output=$(sudo docker ps --format '{{.Names}}' 2>&1)
                exit_code=$?
                if [ $exit_code -eq 0 ]; then
                    export DOCKER_CMD="sudo docker"
                fi
            fi
        fi
    fi
    
    if [ $exit_code -eq 0 ]; then
        echo "$output" | grep -q "^${container_name}$" || return 1
    else
        return 1
    fi
}

# Vérification stable (anti-race condition)
container_is_running_stable() {
    local container_name=$1
    local checks=3
    local interval=1
    
    for i in $(seq 1 $checks); do
        if ! $DOCKER_CMD inspect --format='{{.State.Running}}' "$container_name" 2>/dev/null | grep -q "true"; then
            return 1
        fi
        [ $i -lt $checks ] && sleep $interval
    done
    return 0
}

# Vérifier si un conteneur existe (running ou stopped)
container_exists() {
    local container_name=$1
    $DOCKER_CMD ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${container_name}$" || return 1
}

# Vérifier si un conteneur est healthy
container_is_healthy() {
    local container_name=$1
    local health_status=$($DOCKER_CMD inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "none")
    [ "$health_status" = "healthy" ]
}

# Démarrer un conteneur existant
start_existing_container() {
    local container_name=$1
    local compose_file=$2
    
    log_info "Démarrage du conteneur ${container_name}..."
    $DOCKER_CMD start "$container_name" 2>/dev/null || {
        log_info "Tentative avec docker compose..."
        $DOCKER_CMD compose -f "$compose_file" up -d "$container_name" 2>/dev/null || {
            log_error "Échec du démarrage du conteneur"
            return 1
        }
    }
    
    # Charger wait_for_container_running si disponible
    if command -v wait_for_container_running > /dev/null 2>&1; then
        if wait_for_container_running "$container_name" 60; then
            log_success "✅ Conteneur ${container_name} démarré avec succès"
            return 0
        else
            log_error "❌ Le conteneur n'a pas démarré dans les temps"
            return 1
        fi
    else
        # Fallback : attendre 5 secondes
        sleep 5
        if container_is_running "$container_name"; then
            log_success "✅ Conteneur ${container_name} démarré"
            return 0
        else
            log_error "❌ Le conteneur n'a pas démarré"
            return 1
        fi
    fi
}

# Créer et démarrer un nouveau conteneur
create_new_container() {
    local container_name=$1
    local compose_file=$2
    
    log_info "Création et démarrage du conteneur ${container_name}..."
    if $DOCKER_CMD compose -f "$compose_file" up -d --build; then
        # Charger wait_for_container_running si disponible
        if command -v wait_for_container_running > /dev/null 2>&1; then
            if wait_for_container_running "$container_name" 120; then
                log_success "✅ Conteneur ${container_name} créé et démarré avec succès"
                return 0
            else
                log_error "❌ Le conteneur n'a pas démarré dans les temps"
                return 1
            fi
        else
            sleep 10
            if container_is_running "$container_name"; then
                log_success "✅ Conteneur ${container_name} créé"
                return 0
            else
                log_error "❌ Le conteneur n'a pas démarré"
                return 1
            fi
        fi
    else
        log_error "Échec de la création du conteneur"
        return 1
    fi
}

# Prompt utilisateur pour action
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

# S'assure qu'un conteneur est running (démarre ou crée si nécessaire)
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
            start_existing_container "$container_name" "$compose_file"
        else
            log_info "Démarrage annulé par l'utilisateur"
            return 1
        fi
    else
        # Le conteneur n'existe pas du tout
        log_warning "⚠️  Le conteneur ${container_name} n'existe pas"
        
        if prompt_user_action "Voulez-vous créer et démarrer le conteneur ?"; then
            create_new_container "$container_name" "$compose_file"
        else
            log_info "Création annulée par l'utilisateur"
            return 1
        fi
    fi
}

