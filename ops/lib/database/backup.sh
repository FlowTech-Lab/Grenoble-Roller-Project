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
    
    # Récupérer la clé de chiffrement depuis Rails credentials si activé
    local encryption_key=""
    if [ "$backup_encryption_enabled" = "true" ]; then
        # Attendre que le conteneur soit prêt pour accéder aux credentials
        if container_is_running "${CONTAINER_NAME:-}"; then
            log_info "Récupération de la clé de chiffrement depuis Rails credentials..."
            encryption_key=$(docker exec "${CONTAINER_NAME}" bin/rails runner \
                "puts Rails.application.credentials.dig(:database, :backup_encryption_key)" 2>/dev/null | tr -d '\n\r')
            
            if [ -z "$encryption_key" ]; then
                log_warning "⚠️  Clé backup_encryption_key non trouvée dans Rails credentials"
                log_warning "⚠️  Ajouter avec: rails credentials:edit --environment ${ENV}"
                log_warning "⚠️  Structure: database: { backup_encryption_key: 'votre-clé-32-chars' }"
                log_warning "⚠️  Continuation avec backup non chiffré..."
                backup_encryption_enabled="false"
            else
                log_success "✅ Clé de chiffrement récupérée depuis Rails credentials"
            fi
        else
            log_warning "⚠️  Conteneur non running, impossible d'accéder aux credentials"
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
        if openssl enc -aes-256-cbc -salt -pbkdf2 \
            -pass pass:"$encryption_key" \
            -in "$backup_file" \
            -out "$backup_encrypted" 2>/dev/null; then
            # Vérification intégrité
            if openssl enc -aes-256-cbc -d -pbkdf2 \
                -pass pass:"$encryption_key" \
                -in "$backup_encrypted" 2>/dev/null | head -c 100 > /dev/null 2>&1; then
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

