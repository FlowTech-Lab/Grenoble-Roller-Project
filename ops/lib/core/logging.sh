#!/bin/bash
###############################################################################
# Module: core/logging.sh
# Description: Fonctions de logging structuré (texte + JSON)
# Dependencies: 
#   - core/colors.sh (RED, GREEN, YELLOW, NC)
#   - Variables: LOG_FILE, LOG_JSON_FILE, ENV, DEPLOYMENT_ID, DEPLOY_START_TIME
# Author: FlowTech Lab
# Version: 1.0.0
###############################################################################

# Charger les couleurs si pas déjà chargées
if [ -z "${RED:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/colors.sh" 2>/dev/null || true
fi

# Logging structuré JSON
log_json() {
    local level=$1
    shift
    local message="$@"
    
    # Calculer durée si DEPLOY_START_TIME existe
    local deploy_duration_seconds=""
    if [ -n "${DEPLOY_START_TIME:-}" ]; then
        local current_time=$(date +%s)
        deploy_duration_seconds=$((current_time - DEPLOY_START_TIME))
    fi
    
    if command -v jq > /dev/null 2>&1 && [ -n "${LOG_JSON_FILE:-}" ]; then
        jq -n \
            --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
            --arg lvl "$level" \
            --arg msg "$message" \
            --arg env "${ENV:-unknown}" \
            --arg commit "${REMOTE:-${LOCAL:-unknown}:0:7}" \
            --arg deploy_id "${DEPLOYMENT_ID:-unknown}" \
            --arg duration "$deploy_duration_seconds" \
            '{
                timestamp: $ts,
                level: $lvl,
                message: $msg,
                environment: $env,
                commit: $commit,
                deployment_id: $deploy_id,
                deploy_duration_seconds: ($duration | if . == "" then null else tonumber end)
            }' >> "${LOG_JSON_FILE}" 2>/dev/null || true
    fi
}

log() {
    local message="$@"
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${message}" | tee -a "${LOG_FILE:-/dev/stdout}"
    log_json "INFO" "${message}"
}

log_error() {
    local message="$@"
    echo -e "${RED:-}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: ${message}${NC:-}" | tee -a "${LOG_FILE:-/dev/stderr}"
    log_json "ERROR" "${message}"
}

log_success() {
    local message="$@"
    echo -e "${GREEN:-}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: ${message}${NC:-}" | tee -a "${LOG_FILE:-/dev/stdout}"
    log_json "SUCCESS" "${message}"
}

log_warning() {
    local message="$@"
    echo -e "${YELLOW:-}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: ${message}${NC:-}" | tee -a "${LOG_FILE:-/dev/stdout}"
    log_json "WARNING" "${message}"
}

log_info() {
    local message="$@"
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: ${message}" | tee -a "${LOG_FILE:-/dev/stdout}"
    log_json "INFO" "${message}"
}

