#!/bin/bash
###############################################################################
# Module: deployment/metrics.sh
# Description: Export métriques Prometheus pour déploiements
# Dependencies: 
#   - core/logging.sh
#   - Variables: REPO_DIR, ENV, DEPLOY_START_TIME, MIGRATION_DURATION, DB_BACKUP
# Author: FlowTech Lab
# Version: 1.0.0
###############################################################################

export_deployment_metrics() {
    local status=$1  # "success" ou "failure"
    local deploy_end_time=$(date +%s)
    local deploy_duration=$((deploy_end_time - DEPLOY_START_TIME))
    local repo_dir=${REPO_DIR:-.}
    local env=${ENV:-unknown}
    
    local metrics_file="${repo_dir}/metrics/deploy-${env}.prom"
    mkdir -p "$(dirname "$metrics_file")"
    
    # Calculer la taille du backup si disponible
    local backup_size=0
    if [ -n "${DB_BACKUP:-}" ] && [ -f "$DB_BACKUP" ]; then
        if command -v stat > /dev/null 2>&1; then
            backup_size=$(stat -f%z "$DB_BACKUP" 2>/dev/null || stat -c%s "$DB_BACKUP" 2>/dev/null || echo "0")
        fi
    fi
    
    cat > "$metrics_file" <<EOF
# HELP deployment_duration_seconds Durée totale du déploiement
deployment_duration_seconds{env="${env}",status="${status}"} ${deploy_duration}

# HELP migration_duration_seconds Durée des migrations DB
migration_duration_seconds{env="${env}"} ${MIGRATION_DURATION:-0}

# HELP deployment_timestamp_seconds Timestamp du déploiement
deployment_timestamp_seconds{env="${env}"} ${deploy_end_time}

# HELP backup_size_bytes Taille du backup DB
backup_size_bytes{env="${env}"} ${backup_size}

# HELP deployment_status Statut du déploiement (1=success, 0=failure)
deployment_status{env="${env}"} $([ "$status" = "success" ] && echo "1" || echo "0")
EOF
    
    log_info "📊 Métriques exportées: ${metrics_file}"
    
    # Push vers Prometheus Pushgateway (si configuré)
    if [ -n "${PROMETHEUS_PUSHGATEWAY:-}" ]; then
        if command -v curl > /dev/null 2>&1; then
            curl -X POST --data-binary @"$metrics_file" \
                 "${PROMETHEUS_PUSHGATEWAY}/metrics/job/deployment/instance/${env}" \
                 --silent --show-error > /dev/null 2>&1 && \
            log_success "✅ Métriques poussées vers Prometheus Pushgateway" || \
            log_warning "⚠️  Échec push métriques vers Prometheus"
        fi
    fi
}

