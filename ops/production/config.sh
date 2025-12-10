#!/bin/bash
# Configuration centralisée pour le script de déploiement PRODUCTION
# Source: ops/production/config.sh
# ⚠️  Timeouts plus longs en production pour plus de stabilité

# Migration timeouts (plus longs en production)
readonly MIGRATION_BASE_TIMEOUT=120
readonly MIGRATION_PER_MIGRATION=60
readonly MIGRATION_MAX_TIMEOUT=1800
readonly MIGRATION_MAX_TIMEOUT_PRODUCTION=3600

# Health check retries (plus de tentatives en production)
readonly HEALTH_CHECK_MAX_RETRIES=120
readonly HEALTH_CHECK_BACKOFF_MAX=15
readonly HEALTH_CHECK_INITIAL_SLEEP=15

# Container wait timeouts (plus longs en production)
readonly CONTAINER_RUNNING_WAIT=120
readonly CONTAINER_HEALTHY_WAIT=180
readonly CONTAINER_NEW_WAIT=180

# Disk space requirements (GB) - Plus d'espace requis en production
readonly DISK_SPACE_REQUIRED=10
readonly DISK_SPACE_MIN_AFTER_CLEANUP=5

# Backup retention (plus de rétention en production)
readonly BACKUP_RETENTION_COUNT=50

# Build optimization
readonly BUILD_CACHE_KEEP_RECENT=true  # Garde cache récent pour performance

