#!/bin/bash
# Script watchdog PRODUCTION - Wrapper pour watchdog.sh
# Usage: À exécuter via cron toutes les 10 minutes
# Usage: ./ops/scripts/watchdog-production.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/watchdog.sh" production

