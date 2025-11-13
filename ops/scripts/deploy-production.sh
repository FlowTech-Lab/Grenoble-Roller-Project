#!/bin/bash
# Script de déploiement PRODUCTION - Wrapper pour deploy.sh
# Usage: ./ops/scripts/deploy-production.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/deploy.sh" production

