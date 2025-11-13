#!/bin/bash
# Script watchdog DEV - Wrapper pour watchdog.sh
# Usage: À exécuter via cron toutes les 5 minutes
# Usage: ./ops/scripts/watchdog-dev.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/watchdog.sh" dev

