#!/bin/bash
###############################################################################
# Module: database/restore.sh
# Description: Restauration PostgreSQL depuis backup (chiffré ou non)
# Dependencies: 
#   - core/logging.sh
#   - docker/containers.sh (container_is_running)
#   - Variables: DB_CONTAINER, DB_NAME, CONTAINER_NAME
# Author: FlowTech Lab
# Version: 1.0.0
###############################################################################

restore_database_from_backup() {
    local backup_file=$1
    
    if [ -z "$backup_file" ] || [ ! -f "$backup_file" ]; then
        log_error "Backup introuvable: $backup_file"
        return 1
    fi
    
    if ! container_is_running "${DB_CONTAINER}"; then
        log_error "Conteneur DB non running, impossible de restaurer"
        return 1
    fi
    
    # Détecter si le backup est chiffré
    if [[ "$backup_file" == *.enc ]]; then
        log_info "Restauration depuis backup chiffré: $(basename $backup_file)"
        
        # Récupérer la clé depuis master.key (plus simple et cohérent avec Rails)
        local encryption_key=""
        # Essayer d'abord depuis le host (si disponible)
        local master_key_path="${REPO_DIR:-.}/config/master.key"
        if [ -f "$master_key_path" ]; then
            encryption_key=$(cat "$master_key_path" | tr -d '\n\r')
            log_success "✅ Clé de chiffrement récupérée depuis master.key (host)"
        # Sinon, depuis le conteneur
        elif container_is_running "${CONTAINER_NAME:-}"; then
            log_info "Récupération de la clé de chiffrement depuis master.key (conteneur)..."
            encryption_key=$(docker exec "${CONTAINER_NAME}" cat /rails/config/master.key 2>/dev/null | tr -d '\n\r')
            
            if [ -z "$encryption_key" ]; then
                log_error "master.key introuvable dans le conteneur"
                return 1
            else
                log_success "✅ Clé de chiffrement récupérée depuis master.key (conteneur)"
            fi
        else
            log_error "Conteneur Rails non running et master.key introuvable sur le host"
            return 1
        fi
        
        # Déchiffrement + Restauration en un seul pipe
        if echo -n "$encryption_key" | openssl enc -aes-256-cbc -d -pbkdf2 \
            -pass stdin \
            -in "$backup_file" 2>/dev/null | \
            docker exec -i "${DB_CONTAINER}" \
            psql -U postgres "${DB_NAME}" --single-transaction 2>/dev/null; then
            log_success "✅ Base de données restaurée depuis backup chiffré"
            return 0
        else
            log_error "Échec de la restauration (déchiffrement ou import)"
            return 1
        fi
    else
        log_info "Restauration depuis backup non chiffré: $(basename $backup_file)"
        if cat "$backup_file" | docker exec -i "${DB_CONTAINER}" \
            psql -U postgres "${DB_NAME}" --single-transaction 2>/dev/null; then
            log_success "✅ Base de données restaurée depuis backup non chiffré"
            return 0
        else
            log_error "Échec de la restauration de la base de données"
            return 1
        fi
    fi
}

