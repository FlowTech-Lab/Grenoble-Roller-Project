#!/bin/bash
# Script de déploiement STAGING - Wrapper pour deploy.sh
# Usage: ./ops/scripts/deploy-staging.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/deploy.sh" staging

