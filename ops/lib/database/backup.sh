#!/bin/bash
###############################################################################
# Module: database/backup.sh
# Description: Backup PostgreSQL avec chiffrement OpenSSL
# Dependencies: 
#   - core/logging.sh
#   - docker/containers.sh (container_is_running)
#   - Variables: DB_CONTAINER, DB_NAME, BACKUP_DIR, CONTAINER_NAME, ENV
# Author: FlowTech Lab
# Version: 1.0.0
###############################################################################

backup_database() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/db_${timestamp}.sql"
    local backup_encrypted="${backup_file}.enc"
    local backup_encryption_enabled=${BACKUP_ENCRYPTION_ENABLED:-true}
    
    log "📦 Backup base de données (chiffrement: ${backup_encryption_enabled})..."
    
    # Récupérer la clé de chiffrement depuis master.key (plus simple et cohérent avec Rails)
    local encryption_key=""
    if [ "$backup_encryption_enabled" = "true" ]; then
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
                log_warning "⚠️  master.key non trouvée dans le conteneur"
                log_warning "⚠️  Vérifier que config/master.key existe"
                log_warning "⚠️  Continuation avec backup non chiffré..."
                backup_encryption_enabled="false"
            else
                log_success "✅ Clé de chiffrement récupérée depuis master.key (conteneur)"
            fi
        else
            log_warning "⚠️  Conteneur non running et master.key introuvable sur le host"
            log_warning "⚠️  Continuation avec backup non chiffré..."
            backup_encryption_enabled="false"
        fi
    fi
    
    # Dump de la base de données
    if ! docker exec "${DB_CONTAINER}" pg_dump -U postgres "${DB_NAME}" > "$backup_file" 2>/dev/null; then
        log_error "Échec du dump DB"
        rm -f "$backup_file"
        return 1
    fi
    
    # Vérifier que le dump n'est pas vide
    if [ ! -s "$backup_file" ]; then
        log_error "Backup vide ou corrompu"
        rm -f "$backup_file"
        return 1
    fi
    
    # Chiffrer avec OpenSSL si activé et clé disponible
    if [ "$backup_encryption_enabled" = "true" ] && [ -n "$encryption_key" ]; then
        if ! command -v openssl > /dev/null 2>&1; then
            log_error "OpenSSL non disponible - installation requise: sudo apt-get install openssl"
            rm -f "$backup_file"
            return 1
        fi
        
        # Chiffrement avec OpenSSL (AES-256-CBC, PBKDF2)
        # Utiliser echo -n pour éviter les problèmes de retours à la ligne dans la clé
        if echo -n "$encryption_key" | openssl enc -aes-256-cbc -salt -pbkdf2 \
            -pass stdin \
            -in "$backup_file" \
            -out "$backup_encrypted" 2>/dev/null; then
            # Vérification intégrité : tester le déchiffrement sur un petit échantillon
            local test_decrypt=$(echo -n "$encryption_key" | openssl enc -aes-256-cbc -d -pbkdf2 \
                -pass stdin \
                -in "$backup_encrypted" 2>/dev/null | head -c 100 2>/dev/null | wc -c)
            
            if [ "$test_decrypt" -gt 0 ]; then
                local backup_size=$(du -h "$backup_encrypted" | cut -f1)
                log_success "✅ Backup chiffré créé: $(basename ${backup_encrypted}) (${backup_size})"
                rm -f "$backup_file"
                DB_BACKUP="$backup_encrypted"
                BACKUP_SIZE=$(stat -f%z "$backup_encrypted" 2>/dev/null || stat -c%s "$backup_encrypted" 2>/dev/null || echo "0")
            else
                log_error "Backup chiffré corrompu ou clé invalide"
                rm -f "$backup_file" "$backup_encrypted"
                return 1
            fi
        else
            log_error "Échec du chiffrement OpenSSL"
            log_warning "⚠️  Fallback : Sauvegarde du backup NON CHIFFRÉ (mieux qu'aucun backup)"
            DB_BACKUP="$backup_file"
            BACKUP_SIZE=$(stat -f%z "$backup_file" 2>/dev/null || stat -c%s "$backup_file" 2>/dev/null || echo "0")
            rm -f "$backup_encrypted"
        fi
    else
        log_warning "⚠️  Backup non chiffré (BACKUP_ENCRYPTION_ENABLED=false ou clé manquante)"
        DB_BACKUP="$backup_file"
        BACKUP_SIZE=$(stat -f%z "$backup_file" 2>/dev/null || stat -c%s "$backup_file" 2>/dev/null || echo "0")
    fi
    
    # Garder seulement les N derniers backups
    local retention_count=${BACKUP_RETENTION_COUNT:-20}
    if [ "$backup_encryption_enabled" = "true" ] && [ -n "$encryption_key" ]; then
        ls -t "${BACKUP_DIR}"/db_*.sql.enc 2>/dev/null | tail -n +$((retention_count + 1)) | xargs rm -f 2>/dev/null || true
    else
        ls -t "${BACKUP_DIR}"/db_*.sql 2>/dev/null | tail -n +$((retention_count + 1)) | xargs rm -f 2>/dev/null || true
    fi
    
    return 0
}

