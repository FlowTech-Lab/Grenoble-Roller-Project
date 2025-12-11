#!/bin/bash
###############################################################################
# Module: docker/images.sh
# Description: Gestion des images Docker et cache
# Dependencies: core/logging.sh
# Author: FlowTech Lab
# Version: 1.0.0
###############################################################################

# Nettoyage Docker (libère de l'espace disque)
cleanup_docker() {
    log "🧹 Nettoyage Docker en cours..."
    
    local freed_space=0
    
    # 1. Supprimer les images sans tag (dangling)
    local dangling_images=$($DOCKER_CMD images -f "dangling=true" -q 2>/dev/null | wc -l)
    if [ "$dangling_images" -gt 0 ]; then
        log_info "Suppression de $dangling_images images sans tag..."
        $DOCKER_CMD image prune -f > /dev/null 2>&1 && {
            log_success "Images sans tag supprimées"
            freed_space=$((freed_space + 1))
        } || log_warning "Échec suppression images sans tag"
    fi
    
    # 2. Supprimer le cache de build Docker
    log_info "Nettoyage du cache de build Docker..."
    $DOCKER_CMD builder prune -f > /dev/null 2>&1 && {
        log_success "Cache de build nettoyé"
        freed_space=$((freed_space + 1))
    } || log_warning "Échec nettoyage cache build"
    
    # 3. Supprimer les volumes orphelins
    local orphan_volumes=$($DOCKER_CMD volume ls -f "dangling=true" -q 2>/dev/null | wc -l)
    if [ "$orphan_volumes" -gt 0 ]; then
        log_info "Suppression de $orphan_volumes volumes orphelins..."
        $DOCKER_CMD volume prune -f > /dev/null 2>&1 && {
            log_success "Volumes orphelins supprimés"
            freed_space=$((freed_space + 1))
        } || log_warning "Échec suppression volumes orphelins"
    fi
    
    # 4. Supprimer les conteneurs arrêtés
    local stopped_containers=$($DOCKER_CMD ps -a -f "status=exited" -q 2>/dev/null | wc -l)
    if [ "$stopped_containers" -gt 0 ]; then
        log_info "Suppression de $stopped_containers conteneurs arrêtés..."
        $DOCKER_CMD container prune -f > /dev/null 2>&1 && {
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

# Détecter si un rebuild sans cache est nécessaire
needs_no_cache_build() {
    local repo_dir=${REPO_DIR:-.}
    local branch=${BRANCH:-main}
    local changes=$(git -C "$repo_dir" diff --name-only HEAD@{1} HEAD 2>/dev/null || git -C "$repo_dir" diff --name-only origin/${branch} HEAD 2>/dev/null || echo "")
    
    # Rebuild complet seulement si changements critiques
    if echo "$changes" | grep -qE '^(Gemfile|Gemfile\.lock|Dockerfile|package\.json|package-lock\.json|yarn\.lock)'; then
        log_warning "⚠️  Changements critiques détectés (Gemfile/Dockerfile/package.json)"
        return 0  # Besoin rebuild sans cache
    fi
    
    # Sinon, build incrémental (10x plus rapide)
    return 1  # Pas besoin rebuild sans cache
}

