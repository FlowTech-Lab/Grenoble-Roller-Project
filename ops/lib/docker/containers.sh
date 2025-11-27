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

# Vérifier si un conteneur est running
container_is_running() {
    local container_name=$1
    docker ps --format '{{.Names}}' | grep -q "^${container_name}$" 2>/dev/null || return 1
}

# Vérification stable (anti-race condition)
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

# Vérifier si un conteneur existe (running ou stopped)
container_exists() {
    local container_name=$1
    docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$" 2>/dev/null || return 1
}

# Vérifier si un conteneur est healthy
container_is_healthy() {
    local container_name=$1
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "none")
    [ "$health_status" = "healthy" ]
}

# Démarrer un conteneur existant
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
    if docker compose -f "$compose_file" up -d --build; then
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

