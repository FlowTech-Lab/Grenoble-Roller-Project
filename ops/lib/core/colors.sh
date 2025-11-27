#!/bin/bash
###############################################################################
# Module: core/colors.sh
# Description: Constantes de couleurs pour les logs
# Dependencies: Aucune
# Author: FlowTech Lab
# Version: 1.0.0
###############################################################################

# Couleurs ANSI pour les logs (définir seulement si pas déjà définies)
if [ -z "${RED:-}" ]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly NC='\033[0m' # No Color
fi

