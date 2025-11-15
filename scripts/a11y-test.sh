#!/bin/bash
# Script d'audit accessibilité automatisé

set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:3000}"
OUTPUT_DIR="./docs/08-security-privacy/a11y-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$OUTPUT_DIR"

echo "🔍 Démarrage des tests d'accessibilité..."
echo "Base URL: $BASE_URL"
echo "Output: $OUTPUT_DIR"
echo ""

# Test Pa11y
echo "📊 Exécution de Pa11y..."
npm run test:a11y:pa11y > "$OUTPUT_DIR/pa11y-${TIMESTAMP}.txt" 2>&1 || true

# Test Lighthouse
echo "🚀 Exécution de Lighthouse..."
npm run test:a11y:lighthouse || true

echo ""
echo "✅ Tests terminés. Résultats dans: $OUTPUT_DIR"

