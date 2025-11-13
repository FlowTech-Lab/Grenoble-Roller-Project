#!/bin/bash
# Script de déploiement DEV - Wrapper pour deploy.sh
# Usage: ./ops/scripts/deploy-dev.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/deploy.sh" dev

