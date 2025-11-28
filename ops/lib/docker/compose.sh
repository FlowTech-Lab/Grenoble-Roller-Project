#!/bin/bash
###############################################################################
# Module: docker/compose.sh
# Description: Wrappers pour docker compose
# Dependencies: core/logging.sh
# Author: FlowTech Lab
# Version: 1.0.0
###############################################################################

# Force un rebuild sans cache complet
force_rebuild_without_cache() {
    local compose_file=$1
    local container_name=${2:-}
    local repo_dir=${REPO_DIR:-.}
    
    log_warning "🔄 Rebuild sans cache COMPLET pour garantir l'inclusion de tous les fichiers..."
    
    # Vérification critique : s'assurer qu'on est sur la bonne branche avant build
    local current_branch=$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    local current_commit=$(git -C "$repo_dir" rev-parse --short HEAD 2>/dev/null || echo "unknown")
    
    if [ -n "${BRANCH:-}" ] && [ "$current_branch" != "$BRANCH" ]; then
        log_error "❌ ERREUR CRITIQUE : Branche incorrecte avant rebuild"
        log_error "Branche actuelle: ${current_branch}, attendue: ${BRANCH}"
        log_error "Le build utiliserait le code de la mauvaise branche !"
        return 1
    fi
    
    log_info "✅ Branche vérifiée : ${current_branch} (commit: ${current_commit})"
    log_info "Arrêt des conteneurs..."
    docker compose -f "$compose_file" down > /dev/null 2>&1 || true
    
    # Nettoyage CRITIQUE : Supprimer les migrations et schémas du volume
    # Le volume ne doit contenir QUE les fichiers SQLite de Solid Queue/Cache/Cable
    # Les migrations et schémas doivent venir de l'image, pas du volume
    log_info "🧹 Nettoyage du volume /rails/db (suppression migrations/schémas qui écrase l'image)..."
    local volume_name=$(docker compose -f "$compose_file" config --volumes 2>/dev/null | grep -E "staging.*data|prod.*data" | head -1 || echo "")
    if [ -n "$volume_name" ]; then
        # Supprimer migrations, schémas, seeds du volume (ils doivent venir de l'image)
        docker run --rm -v "${volume_name}:/data" alpine sh -c "
            if [ -d /data/migrate ]; then
                rm -rf /data/migrate
                echo '  ✅ Dossier migrate supprimé du volume'
            fi
            if [ -f /data/schema.rb ]; then
                rm -f /data/schema.rb
                echo '  ✅ schema.rb supprimé du volume'
            fi
            if [ -f /data/seeds.rb ]; then
                rm -f /data/seeds.rb
                echo '  ✅ seeds.rb supprimé du volume'
            fi
            # Garder les schémas Solid Queue/Cache/Cable mais les supprimer aussi (ils doivent venir de l'image)
            rm -f /data/*_schema.rb 2>/dev/null && echo '  ✅ Schémas Solid Queue/Cache/Cable supprimés du volume'
            echo '  ℹ️  Fichiers SQLite conservés (s\'ils existent)'
        " 2>/dev/null || log_warning "⚠️  Impossible de nettoyer le volume (peut-être inexistant)"
    else
        log_warning "⚠️  Volume non détecté, nettoyage ignoré"
    fi
    
    log_info "Nettoyage du cache de build (garde cache récent pour performance)..."
    docker builder prune -f > /dev/null 2>&1 || true
    
    log_info "Nettoyage BuildKit cache (cache persistant)..."
    docker buildx prune -a -f > /dev/null 2>&1 || true
    
    log_info "Nettoyage AGRESSIF des images (supprime TOUTES les images non utilisées, y compris intermédiaires)..."
    # Supprimer toutes les images non utilisées (pas seulement dangling)
    # Ceci inclut les images intermédiaires du multi-stage build qui peuvent contenir d'anciennes migrations
    docker image prune -a -f > /dev/null 2>&1 || true
    
    # Supprimer l'image actuelle si elle existe (force rebuild complet)
    if [ -n "$container_name" ]; then
        log_info "Suppression de l'image actuelle (force rebuild from scratch)..."
        docker rmi $(docker images -q "$container_name" 2>/dev/null | head -1) --force 2>/dev/null || true
    fi
    
    # Supprimer aussi les images intermédiaires du multi-stage build (base, build stages)
    log_info "Suppression des images intermédiaires du multi-stage build..."
    docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | grep -E "staging-web|ruby.*slim" | awk '{print $2}' | xargs -r docker rmi --force 2>/dev/null || true
    
    # Vérifier que les fichiers de migration sont bien dans le build context
    log_info "Vérification que les migrations sont dans le build context..."
    local migration_count=$(find "$repo_dir/db/migrate" -name "*.rb" -type f 2>/dev/null | wc -l | tr -d ' ')
    log_info "✅ ${migration_count} fichier(s) de migration trouvé(s) dans le build context"
    
    # Générer un BUILD_ID unique pour forcer un nouveau build
    local BUILD_ID="$(date +%Y%m%d-%H%M%S)-$(git -C "$repo_dir" rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
    log_info "🔨 BUILD_ID unique: ${BUILD_ID} (force nouveau layer, évite cache trompeur)"
    
    log_info "Rebuild sans cache COMPLET (--pull --no-cache --build-arg BUILD_ID)..."
    log_warning "⚠️  Ce build peut prendre 5-10 minutes (sans cache complet)..."
    
    # Build avec --no-cache
    if docker compose --progress=plain -f "$compose_file" build --pull --no-cache --build-arg BUILD_ID="$BUILD_ID" 2>&1 | tee -a "${LOG_FILE:-/dev/stdout}"; then
        BUILD_EXIT_CODE=0
        log_success "✅ Build réussi"
    else
        BUILD_EXIT_CODE=$?
        log_error "❌ Build échoué (exit code: $BUILD_EXIT_CODE)"
        return $BUILD_EXIT_CODE
    fi
    
    if [ $BUILD_EXIT_CODE -eq 0 ]; then
        log_info "Démarrage de tous les services (web, db, minio, etc.)..."
        # Démarrer tous les services pour s'assurer que les nouveaux services ajoutés au docker-compose.yml sont créés
        if docker compose -f "$compose_file" up -d 2>&1 | tee -a "${LOG_FILE:-/dev/stdout}"; then
            log_success "✅ Tous les services démarrés avec succès"
            return 0
        else
            log_error "❌ Échec du démarrage des services"
            return 1
        fi
    else
        return $BUILD_EXIT_CODE
    fi
}

# Build normal avec cache
docker_compose_build() {
    local compose_file=$1
    
    log "🔨 Build et redémarrage (cache activé)..."
    
    # Vérification : s'assurer qu'on est sur la bonne branche avant build
    local repo_dir=${REPO_DIR:-.}
    local build_branch=$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [ -n "${BRANCH:-}" ] && [ "$build_branch" != "$BRANCH" ]; then
        log_error "❌ ERREUR : Branche incorrecte avant build (${build_branch} au lieu de ${BRANCH})"
        log_error "Le build utiliserait le code de la mauvaise branche !"
        return 1
    fi
    
    local build_output=$(docker compose -f "$compose_file" up -d --build 2>&1)
    local build_exit_code=$?
    
    # Vérifier que l'image a été créée après build
    if [ $build_exit_code -eq 0 ]; then
        local image_name=$(docker compose -f "$compose_file" images -q web 2>/dev/null | head -1)
        if [ -z "$image_name" ]; then
            log_error "❌ Image non trouvée après build réussi"
            log_error "Le build a peut-être échoué silencieusement"
            return 1
        else
            log_success "✅ Image créée: ${image_name:0:12}..."
        fi
    fi
    
    echo "$build_output" | tee -a "${LOG_FILE:-/dev/stdout}"
    return $build_exit_code
}

