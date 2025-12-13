#!/bin/bash
###############################################################################
# Module: deployment/cron.sh
# Description: Gestion automatique du crontab via whenever
# Dependencies: 
#   - core/logging.sh
#   - core/utils.sh
#   - Variables: REPO_DIR, ENV
# Author: FlowTech Lab
# Version: 1.0.0
###############################################################################

# Installe ou met à jour le crontab depuis schedule.rb
# Utilise whenever pour générer le crontab et l'écrit dans /rails/config/crontab
# Supercronic lit directement ce fichier (pas besoin de la commande crontab)
# IMPORTANT : S'exécute depuis le conteneur (bundle/whenever disponibles uniquement dans le conteneur)
install_crontab() {
    local container=${CONTAINER_NAME:-}
    local env=${ENV:-production}
    
    if [ -z "$container" ]; then
        log_warning "⚠️  Nom du conteneur non spécifié, impossible d'installer le crontab"
        return 1
    fi
    
    log "🔄 Installation/mise à jour du crontab pour ${env}..."
    
    # Vérifier que le conteneur est running
    if ! container_is_running "$container"; then
        log_warning "⚠️  Conteneur ${container} non running, impossible d'installer le crontab"
        return 1
    fi
    
    # Vérifier que schedule.rb existe dans le conteneur
    if ! $DOCKER_CMD exec "$container" test -f /rails/config/schedule.rb 2>/dev/null; then
        log_error "config/schedule.rb introuvable dans le conteneur"
        return 1
    fi
    
    # Générer le contenu du crontab avec whenever (sans utiliser --update-crontab qui nécessite crontab)
    log_info "   Génération du crontab depuis config/schedule.rb..."
    local crontab_content
    crontab_content=$($DOCKER_CMD exec "$container" bundle exec whenever --set "environment=${env}" 2>&1)
    local whenever_exit_code=$?
    
    if [ $whenever_exit_code -ne 0 ] || [ -z "$crontab_content" ]; then
        log_error "❌ Échec de la génération du crontab (exit code: $whenever_exit_code)"
        echo "$crontab_content" | while IFS= read -r line; do
            log_error "   $line"
        done
        return 1
    fi
    
    # Écrire le crontab dans /rails/config/crontab (Supercronic lit ce fichier)
    log_info "   Écriture du crontab dans /rails/config/crontab..."
    
    # S'assurer que le répertoire config existe
    $DOCKER_CMD exec "$container" mkdir -p /rails/config 2>/dev/null || true
    
    # Essayer plusieurs méthodes pour écrire le fichier
    local write_error=""
    local write_success=false
    
    # Méthode 1 : Utiliser base64 pour encoder le contenu (évite les problèmes d'échappement)
    # Vérifier d'abord si base64 est disponible dans le conteneur
    if $DOCKER_CMD exec "$container" which base64 >/dev/null 2>&1; then
        local crontab_encoded
        # base64 -w 0 (GNU) ou base64 sans -w (BSD/macOS), on supprime les retours à la ligne manuellement
        crontab_encoded=$(echo "$crontab_content" | base64 2>/dev/null | tr -d '\n' || echo "$crontab_content" | base64 -w 0 2>/dev/null || echo "")
        
        if [ -n "$crontab_encoded" ]; then
            # Décoder et écrire dans le conteneur
            if $DOCKER_CMD exec "$container" sh -c "echo '$crontab_encoded' | base64 -d > /rails/config/crontab" 2>&1; then
                write_success=true
            else
                write_error=$($DOCKER_CMD exec "$container" sh -c "echo '$crontab_encoded' | base64 -d > /rails/config/crontab" 2>&1 || true)
            fi
        fi
    fi
    
    # Méthode 2 : Si base64 a échoué, utiliser tee comme fallback
    if [ "$write_success" != true ]; then
        log_info "   Tentative avec méthode alternative (tee)..."
        if echo "$crontab_content" | $DOCKER_CMD exec -i "$container" tee /rails/config/crontab >/dev/null 2>&1; then
            write_success=true
        else
            write_error=$(echo "$crontab_content" | $DOCKER_CMD exec -i "$container" tee /rails/config/crontab 2>&1 || true)
        fi
    fi
    
    if [ "$write_success" = true ]; then
        log_success "✅ Crontab généré et écrit dans /rails/config/crontab"
        
        # Vérifier que le fichier existe et contient des entrées
        local installed_count
        installed_count=$($DOCKER_CMD exec "$container" grep -c "rails runner" /rails/config/crontab 2>/dev/null || echo "0")
        
        if [ "$installed_count" -gt 0 ]; then
            log_success "✅ Vérification : $installed_count entrée(s) cron dans le fichier"
            
            # Afficher les entrées installées (pour vérification)
            log_info "📋 Entrées cron générées:"
            echo "$crontab_content" | while IFS= read -r line; do
                # Ignorer les lignes vides et les commentaires
                if [ -n "$line" ] && ! echo "$line" | grep -q "^#"; then
                    log_info "   $line"
                fi
            done
            
            return 0
        else
            log_warning "⚠️  Le fichier crontab existe mais aucune entrée trouvée"
            return 1
        fi
    else
        log_error "❌ Échec de l'écriture du crontab dans /rails/config/crontab"
        if [ -n "$write_error" ]; then
            echo "$write_error" | while IFS= read -r line; do
                log_error "   $line"
            done
        fi
        log_info "   Vérification des permissions sur /rails/config..."
        $DOCKER_CMD exec "$container" ls -la /rails/config 2>&1 | while IFS= read -r line; do
            log_info "   $line"
        done || true
        return 1
    fi
}

# Vérifie si le crontab est déjà installé
# Retourne 0 si installé, 1 sinon
is_crontab_installed() {
    local container=${CONTAINER_NAME:-}
    
    if [ -z "$container" ] || ! container_is_running "$container"; then
        return 1
    fi
    
    # Vérifier si le fichier /rails/config/crontab existe et contient des entrées
    if $DOCKER_CMD exec "$container" test -f /rails/config/crontab 2>/dev/null && \
       $DOCKER_CMD exec "$container" grep -q "rails runner" /rails/config/crontab 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Affiche le crontab actuel (depuis le fichier ou généré par whenever)
show_crontab() {
    local container=${CONTAINER_NAME:-}
    local env=${ENV:-production}
    
    if [ -z "$container" ] || ! container_is_running "$container"; then
        log_error "Conteneur non disponible"
        return 1
    fi
    
    # Afficher le contenu du fichier crontab s'il existe
    if $DOCKER_CMD exec "$container" test -f /rails/config/crontab 2>/dev/null; then
        log "📋 Crontab actuel (depuis /rails/config/crontab):"
        $DOCKER_CMD exec "$container" cat /rails/config/crontab 2>/dev/null | while IFS= read -r line; do
            echo "   $line"
        done
    else
        log "📋 Crontab actuel (généré depuis config/schedule.rb):"
        $DOCKER_CMD exec "$container" bundle exec whenever --set "environment=${env}" 2>/dev/null | while IFS= read -r line; do
            echo "   $line"
        done
    fi
}

# Supprime le fichier crontab utilisé par Supercronic
clear_crontab() {
    local container=${CONTAINER_NAME:-}
    
    log_warning "🗑️  Suppression du crontab..."
    
    if [ -z "$container" ] || ! container_is_running "$container"; then
        log_error "Conteneur non disponible"
        return 1
    fi
    
    # Supprimer ou vider le fichier /rails/config/crontab
    if $DOCKER_CMD exec "$container" rm -f /rails/config/crontab 2>/dev/null || \
       $DOCKER_CMD exec "$container" sh -c 'echo "" > /rails/config/crontab' 2>/dev/null; then
        log_success "✅ Crontab supprimé"
        return 0
    else
        log_error "❌ Échec de la suppression du crontab"
        return 1
    fi
}

