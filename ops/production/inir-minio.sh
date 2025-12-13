#!/bin/bash
###############################################################################
# Script d'initialisation MinIO pour PRODUCTION
# Usage: ./ops/production/init-minio.sh
# Effectue: Création du bucket grenoble-roller-production si nécessaire
# ⚠️  ATTENTION: Ce script est pour PRODUCTION - utilisez avec précaution
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Charger les modules nécessaires
LIB_DIR="${SCRIPT_DIR}/../lib"
if [ -f "${LIB_DIR}/core/colors.sh" ]; then
    source "${LIB_DIR}/core/colors.sh"
    source "${LIB_DIR}/core/logging.sh"
    source "${LIB_DIR}/docker/containers.sh"
else
    # Fallback simple si les libs ne sont pas disponibles
    log() { echo "[INFO] $*"; }
    log_success() { echo "[OK] $*"; }
    log_error() { echo "[ERROR] $*"; }
    log_warning() { echo "[WARN] $*"; }
    log_info() { echo "[INFO] $*"; }
    container_is_running() { docker ps --format '{{.Names}}' | grep -q "^$1$"; }
fi

COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
MINIO_CONTAINER="grenoble-roller-minio-production"
BUCKET_NAME="grenoble-roller-production"

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🪣 INITIALISATION MINIO - PRODUCTION"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Vérifier que le conteneur MinIO est running
if ! container_is_running "$MINIO_CONTAINER"; then
    log_error "❌ Le conteneur ${MINIO_CONTAINER} n'est pas en cours d'exécution"
    log_error "Démarrez-le avec: docker compose -f ${COMPOSE_FILE} up -d minio"
    exit 1
fi

log_success "✅ Conteneur ${MINIO_CONTAINER} est running"

# Attendre que MinIO soit prêt
log "⏳ Attente que MinIO soit prêt..."
for i in {1..30}; do
    if docker exec "$MINIO_CONTAINER" curl -sf http://localhost:9000/minio/health/live > /dev/null 2>&1; then
        log_success "✅ MinIO est prêt"
        break
    fi
    if [ $i -eq 30 ]; then
        log_error "❌ Timeout : MinIO n'est pas prêt après 30 tentatives"
        exit 1
    fi
    sleep 1
done

# Configurer l'alias MinIO client
log "🔧 Configuration du client MinIO..."
if docker exec "$MINIO_CONTAINER" mc alias set local http://localhost:9000 minioadmin minioadmin > /dev/null 2>&1; then
    log_success "✅ Alias configuré"
else
    log_warning "⚠️  Alias déjà configuré ou erreur (continuez...)"
fi

# Vérifier si le bucket existe
log "🔍 Vérification du bucket ${BUCKET_NAME}..."
if docker exec "$MINIO_CONTAINER" mc ls local/ 2>/dev/null | grep -q "$BUCKET_NAME"; then
    log_success "✅ Bucket ${BUCKET_NAME} existe déjà"
else
    log_info "📦 Création du bucket ${BUCKET_NAME}..."
    if docker exec "$MINIO_CONTAINER" mc mb local/"$BUCKET_NAME" 2>&1; then
        log_success "✅ Bucket ${BUCKET_NAME} créé avec succès"
    else
        log_error "❌ Échec de la création du bucket"
        exit 1
    fi
fi

# Configurer les permissions du bucket (download pour les fichiers publics)
log "🔐 Configuration des permissions du bucket..."
if docker exec "$MINIO_CONTAINER" mc anonymous set download local/"$BUCKET_NAME" 2>&1; then
    log_success "✅ Permissions configurées (download)"
else
    log_warning "⚠️  Erreur lors de la configuration des permissions (peut déjà être configuré)"
fi

# Vérifier l'accès depuis Rails
log "🧪 Test de connexion depuis Rails..."
if docker compose -f "$COMPOSE_FILE" exec -T web bin/rails runner "
  require 'aws-sdk-s3'
  begin
    s3 = Aws::S3::Client.new(
      endpoint: Rails.application.credentials.dig(:minio, :endpoint),
      access_key_id: Rails.application.credentials.dig(:minio, :access_key_id),
      secret_access_key: Rails.application.credentials.dig(:minio, :secret_access_key),
      region: 'us-east-1',
      force_path_style: true
    )
    s3.head_bucket(bucket: '${BUCKET_NAME}')
    puts 'OK'
  rescue => e
    puts \"ERROR: #{e.message}\"
    exit 1
  end
" 2>&1 | grep -q "OK"; then
    log_success "✅ Rails peut accéder au bucket"
else
    log_error "❌ Rails ne peut pas accéder au bucket"
    log_error "Vérifiez les credentials Rails avec: docker compose -f ${COMPOSE_FILE} exec web bin/rails credentials:show"
    exit 1
fi

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "✅ INITIALISATION MINIO TERMINÉE"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

