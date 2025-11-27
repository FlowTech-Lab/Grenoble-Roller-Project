#!/bin/bash
# Configuration centralisée pour le script de déploiement
# Source: ops/staging/config.sh

# Migration timeouts
readonly MIGRATION_BASE_TIMEOUT=60
readonly MIGRATION_PER_MIGRATION=30
readonly MIGRATION_MAX_TIMEOUT=900
readonly MIGRATION_MAX_TIMEOUT_PRODUCTION=1800

# Health check retries
readonly HEALTH_CHECK_MAX_RETRIES=60
readonly HEALTH_CHECK_BACKOFF_MAX=10
readonly HEALTH_CHECK_INITIAL_SLEEP=10

# Container wait timeouts
readonly CONTAINER_RUNNING_WAIT=60
readonly CONTAINER_HEALTHY_WAIT=120
readonly CONTAINER_NEW_WAIT=120

# Disk space requirements (GB)
readonly DISK_SPACE_REQUIRED=5
readonly DISK_SPACE_MIN_AFTER_CLEANUP=3

# Backup retention
readonly BACKUP_RETENTION_COUNT=20

# Build optimization
readonly BUILD_CACHE_KEEP_RECENT=true  # Garde cache récent pour performance

