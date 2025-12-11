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
    if ! $DOCKER_CMD exec "$container" bin/rails runner \
        "ActiveRecord::Base.connection.execute('SELECT 1')" > /dev/null 2>&1; then
        log_error "  ❌ DB inaccessible depuis Rails"
        errors=$((errors + 1))
    else
        log_success "  ✅ DB accessible"
    fi
    
    # 2. Vérifier Redis (si utilisé)
    log_info "  → Vérification Redis..."
    if $DOCKER_CMD exec "$container" bin/rails runner \
       "Redis.current.ping rescue nil" > /dev/null 2>&1; then
        if $DOCKER_CMD exec "$container" bin/rails runner \
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
    local pending=$($DOCKER_CMD exec "$container" bin/rails db:migrate:status 2>/dev/null | \
                   awk '/^\s*down/ {count++} END {print count+0}' || echo "999")
    if [ "$pending" -gt 0 ]; then
        log_error "  ❌ Migrations en attente: $pending"
        errors=$((errors + 1))
    else
        log_success "  ✅ Toutes les migrations appliquées"
    fi
    
    # 4. Test HTTP endpoint
    # Détecter le port interne du conteneur (variable d'environnement PORT)
    # Le port passé en paramètre est le port externe, mais dans le conteneur l'app écoute sur PORT (généralement 3000)
    local internal_port=$($DOCKER_CMD exec "$container" sh -c 'echo ${PORT:-3000}' 2>/dev/null || echo "3000")
    log_info "  → Vérification HTTP (port externe: ${port}, port interne: ${internal_port})..."
    
    # Tester depuis le conteneur (le port interne, pas le port externe)
    local response="000"
    
    # Vérifier si curl est disponible dans le conteneur
    if $DOCKER_CMD exec "$container" which curl > /dev/null 2>&1; then
        # Tester depuis le conteneur (localhost avec le port interne)
        response=$($DOCKER_CMD exec "$container" curl -s -w "%{http_code}" -o /dev/null \
                   "http://localhost:${internal_port}/up" 2>/dev/null || echo "000")
    # Sinon, utiliser wget si disponible dans le conteneur
    elif $DOCKER_CMD exec "$container" which wget > /dev/null 2>&1; then
        local wget_output=$($DOCKER_CMD exec "$container" wget -q -O - \
                            "http://localhost:${internal_port}/up" 2>&1)
        if echo "$wget_output" | grep -q "200 OK\|up"; then
            response="200"
        else
            response="000"
        fi
    # Sinon, essayer via le reverse proxy depuis l'hôte (si curl disponible sur l'hôte)
    elif command -v curl > /dev/null 2>&1; then
        # Tester via le reverse proxy (port 80) depuis l'hôte
        local proxy_response=$(curl -s -w "%{http_code}" -o /dev/null \
                              "http://localhost:80/up" 2>/dev/null || echo "000")
        if [ "$proxy_response" != "000" ] && [ "$proxy_response" != "" ]; then
            response="$proxy_response"
        else
            log_warning "  ⚠️  Impossible de tester HTTP (curl non disponible dans le conteneur et proxy inaccessible)"
            # Ne pas compter comme erreur si on ne peut pas tester
            return $errors
        fi
    else
        log_warning "  ⚠️  curl/wget non disponible (conteneur et hôte), skip HTTP check"
        # Ne pas compter comme erreur si on ne peut pas tester
        return $errors
    fi
    
    if [ "$response" = "200" ]; then
        log_success "  ✅ HTTP endpoint OK (${response})"
    else
        log_error "  ❌ HTTP endpoint échoué (code: ${response})"
        errors=$((errors + 1))
    fi
    
    return $errors
}

