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
# Utilise whenever pour générer et installer le crontab
install_crontab() {
    local repo_dir=${REPO_DIR:-.}
    local env=${ENV:-production}
    
    log "🔄 Installation/mise à jour du crontab pour ${env}..."
    
    # Vérifier que whenever est disponible
    if ! command -v bundle > /dev/null 2>&1; then
        log_error "bundle n'est pas disponible - impossible d'installer le cron"
        return 1
    fi
    
    # Aller dans le répertoire du projet
    cd "$repo_dir" || {
        log_error "Impossible d'accéder au répertoire: $repo_dir"
        return 1
    }
    
    # Vérifier que schedule.rb existe
    if [ ! -f "config/schedule.rb" ]; then
        log_error "config/schedule.rb introuvable"
        return 1
    fi
    
    # Générer et installer le crontab
    if bundle exec whenever --update-crontab; then
        log_success "✅ Crontab installé/mis à jour avec succès"
        
        # Afficher les entrées installées (pour vérification)
        log_info "📋 Entrées cron installées:"
        bundle exec whenever | while IFS= read -r line; do
            log_info "   $line"
        done
        
        return 0
    else
        log_error "❌ Échec de l'installation du crontab"
        return 1
    fi
}

# Vérifie si le crontab est déjà installé
# Retourne 0 si installé, 1 sinon
is_crontab_installed() {
    local repo_dir=${REPO_DIR:-.}
    
    cd "$repo_dir" || return 1
    
    # Vérifier si whenever peut détecter des entrées existantes
    if bundle exec whenever 2>/dev/null | grep -q "EventReminderJob\|helloasso\|memberships"; then
        return 0
    else
        return 1
    fi
}

# Affiche le crontab actuel (généré par whenever)
show_crontab() {
    local repo_dir=${REPO_DIR:-.}
    
    cd "$repo_dir" || return 1
    
    log "📋 Crontab actuel (généré depuis config/schedule.rb):"
    bundle exec whenever | while IFS= read -r line; do
        echo "   $line"
    done
}

# Supprime toutes les entrées cron générées par whenever
clear_crontab() {
    local repo_dir=${REPO_DIR:-.}
    
    log_warning "🗑️  Suppression du crontab..."
    
    cd "$repo_dir" || return 1
    
    if bundle exec whenever --clear-crontab; then
        log_success "✅ Crontab supprimé"
        return 0
    else
        log_error "❌ Échec de la suppression du crontab"
        return 1
    fi
}

