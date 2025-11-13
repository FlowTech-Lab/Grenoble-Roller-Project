#!/bin/bash
# Script watchdog STAGING - Wrapper pour watchdog.sh
# Usage: À exécuter via cron toutes les 5 minutes
# Usage: ./ops/scripts/watchdog-staging.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/watchdog.sh" staging

