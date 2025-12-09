#!/bin/bash
###############################################################################
# Script standalone pour installer/mettre à jour le crontab
# Usage: ./ops/scripts/update-crontab.sh [staging|production]
# Auto-détecte l'environnement si non spécifié
###############################################################################

set -euo pipefail

# Détection de l'environnement
ENV="${1:-}"
if [ -z "$ENV" ]; then
    # Auto-détection depuis le répertoire courant ou variables d'environnement
    if [ -n "${RAILS_ENV:-}" ]; then
        ENV="$RAILS_ENV"
    elif [ -d "ops/staging" ] && [ -d "ops/production" ]; then
        echo "❌ Erreur: Environnement non spécifié"
        echo "   Usage: $0 [staging|production]"
        exit 1
    else
        ENV="production"
    fi
fi

# Validation de l'environnement
if [ "$ENV" != "staging" ] && [ "$ENV" != "production" ]; then
    echo "❌ Erreur: Environnement invalide: $ENV"
    echo "   Doit être 'staging' ou 'production'"
    exit 1
fi

# Répertoire du projet
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Charger les modules nécessaires
LIB_DIR="${SCRIPT_DIR}/../lib"
source "${LIB_DIR}/core/colors.sh"
source "${LIB_DIR}/core/logging.sh"
source "${LIB_DIR}/deployment/cron.sh"

# Aller dans le répertoire du projet
cd "$REPO_DIR" || exit 1

# Exporter les variables nécessaires
export REPO_DIR
export ENV

# Installer le crontab
if install_crontab; then
    echo ""
    echo "✅ Crontab installé avec succès pour ${ENV}"
    echo ""
    echo "📋 Pour vérifier les entrées installées:"
    echo "   bundle exec whenever"
    echo ""
    echo "🗑️  Pour supprimer le crontab:"
    echo "   bundle exec whenever --clear-crontab"
    exit 0
else
    echo ""
    echo "❌ Échec de l'installation du crontab"
    exit 1
fi

