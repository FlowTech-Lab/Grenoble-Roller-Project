#!/bin/bash
# Script watchdog STAGING - Vérifie les mises à jour et déclenche le déploiement
# Usage: À exécuter via cron toutes les 5 minutes
# Usage: ./ops/staging/watchdog.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DEPLOY_SCRIPT="${SCRIPT_DIR}/deploy.sh"
ENV="staging"

cd "$REPO_DIR" || exit 1

# Vérifier si un déploiement est déjà en cours
LOCK_FILE="/tmp/grenoble-roller-deploy-${ENV}.lock"
if [ -f "$LOCK_FILE" ]; then
    # Vérifier l'âge du lock file (timeout 30 minutes)
    if command -v stat > /dev/null 2>&1; then
        # Linux
        LOCK_AGE=$(($(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0)))
    else
        # macOS
        LOCK_AGE=$(($(date +%s) - $(stat -f %m "$LOCK_FILE" 2>/dev/null || echo 0)))
    fi
    
    if [ $LOCK_AGE -gt 1800 ]; then  # 30 minutes
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Lock file stale (>30min), suppression..."
        rm -f "$LOCK_FILE"
    else
        PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [ -n "$PID" ] && ps -p "$PID" > /dev/null 2>&1; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Déploiement déjà en cours (PID: $PID)"
            exit 0
        else
            # Lock file orphelin, le supprimer
            rm -f "$LOCK_FILE"
        fi
    fi
fi

# Créer le lock file
echo $$ > "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

# Exécuter le déploiement
"$DEPLOY_SCRIPT"

# Supprimer le lock file
rm -f "$LOCK_FILE"

