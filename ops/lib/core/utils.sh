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

