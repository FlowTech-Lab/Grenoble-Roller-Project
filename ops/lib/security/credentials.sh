#!/bin/bash
###############################################################################
# Module: security/credentials.sh
# Description: Gestion des Rails credentials (master keys)
# Dependencies: 
#   - core/logging.sh (log_error, log_warning, log_success)
#   - Variable: REPO_DIR
# Author: FlowTech Lab
# Version: 1.0.0
###############################################################################

# ============================================================================
# FONCTION: load_rails_credentials
# DESCRIPTION: Charge la master key Rails pour un environnement donné
# PARAMÈTRES:
#   $1: env - Environnement (staging/production)
# RETOUR:
#   0: Succès
#   1: Échec (master key introuvable)
# USAGE: load_rails_credentials "staging"
# ============================================================================
load_rails_credentials() {
    local env=$1
    local repo_dir=${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}
    local key_file="${repo_dir}/config/credentials/${env}.key"
    
    # 1. Chercher la master key par environnement (staging.key, production.key)
    if [ -f "$key_file" ]; then
        export RAILS_MASTER_KEY=$(cat "$key_file" | tr -d '\n\r')
        log_info "🔐 Master key chargée depuis ${key_file}"
        return 0
    fi
    
    # 2. Fallback : master.key global (development)
    if [ -f "${repo_dir}/config/master.key" ]; then
        export RAILS_MASTER_KEY=$(cat "${repo_dir}/config/master.key" | tr -d '\n\r')
        log_info "🔐 Master key chargée depuis config/master.key (dev)"
        return 0
    fi
    
    # 3. Fallback : variable d'environnement RAILS_MASTER_KEY
    if [ -n "${RAILS_MASTER_KEY:-}" ]; then
        log_info "🔐 Master key chargée depuis RAILS_MASTER_KEY (env var)"
        return 0
    fi
    
    # 4. Échec : master key introuvable
    log_error "Master key Rails introuvable pour ${env}"
    log_warning "Créer avec: rails credentials:edit --environment ${env}"
    log_warning "Ou définir RAILS_MASTER_KEY comme variable d'environnement"
    return 1
}

