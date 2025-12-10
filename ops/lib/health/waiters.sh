#!/bin/bash
###############################################################################
# Module: health/waiters.sh
# Description: Fonctions d'attente pour conteneurs (running, healthy)
# Dependencies: 
#   - core/logging.sh
#   - docker/containers.sh (container_is_running, container_is_healthy)
# Author: FlowTech Lab
# Version: 1.0.0
###############################################################################

# Attendre qu'un conteneur soit running
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
                if command -v show_container_logs > /dev/null 2>&1; then
                    show_container_logs "$container_name" 30
                fi
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
        if command -v show_container_logs > /dev/null 2>&1; then
            show_container_logs "$container_name" 50
        fi
    fi
    return 1
}

# Attendre qu'un conteneur soit healthy
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

