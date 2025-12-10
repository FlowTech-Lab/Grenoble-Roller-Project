#!/bin/bash
###############################################################################
# Module: health/checks.sh
# Description: Health checks complets (DB, Redis, Migrations, HTTP)
# Dependencies: 
#   - core/logging.sh
#   - docker/containers.sh (container_is_running)
# Author: FlowTech Lab
# Version: 1.0.0
###############################################################################

# Health check complet (DB, Redis, Migrations, HTTP)
health_check_comprehensive() {
    local container=$1
    local port=$2
    local errors=0
    
    log "🏥 Health check complet (DB, Redis, Migrations, HTTP)..."
    
    # 1. Vérifier DB connectivité depuis Rails
    log_info "  → Vérification DB..."
    if ! docker exec "$container" bin/rails runner \
        "ActiveRecord::Base.connection.execute('SELECT 1')" > /dev/null 2>&1; then
        log_error "  ❌ DB inaccessible depuis Rails"
        errors=$((errors + 1))
    else
        log_success "  ✅ DB accessible"
    fi
    
    # 2. Vérifier Redis (si utilisé)
    log_info "  → Vérification Redis..."
    if docker exec "$container" bin/rails runner \
       "Redis.current.ping rescue nil" > /dev/null 2>&1; then
        if docker exec "$container" bin/rails runner \
           "Redis.current.ping" > /dev/null 2>&1; then
            log_success "  ✅ Redis accessible"
        else
            log_warning "  ⚠️  Redis non configuré (non bloquant)"
        fi
    else
        log_warning "  ⚠️  Redis non disponible (non bloquant)"
    fi
    
    # 3. Vérifier migrations appliquées
    log_info "  → Vérification migrations..."
    local pending=$(docker exec "$container" bin/rails db:migrate:status 2>/dev/null | \
                   awk '/^\s*down/ {count++} END {print count+0}' || echo "999")
    if [ "$pending" -gt 0 ]; then
        log_error "  ❌ Migrations en attente: $pending"
        errors=$((errors + 1))
    else
        log_success "  ✅ Toutes les migrations appliquées"
    fi
    
    # 4. Test HTTP endpoint
    log_info "  → Vérification HTTP (port: ${port})..."
    if ! command -v curl > /dev/null 2>&1; then
        log_warning "  ⚠️  curl non disponible, skip HTTP check"
    else
        local response=$(curl -s -w "%{http_code}" -o /dev/null \
                        "http://localhost:${port}/up" 2>/dev/null || echo "000")
        if [ "$response" = "200" ]; then
            log_success "  ✅ HTTP endpoint OK (${response})"
        else
            log_error "  ❌ HTTP endpoint échoué (code: ${response})"
            errors=$((errors + 1))
        fi
    fi
    
    return $errors
}

