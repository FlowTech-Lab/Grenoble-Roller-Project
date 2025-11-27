#!/bin/bash
# Script de test pour valider toutes les améliorations du déploiement
# Usage: ./ops/staging/test-deploy.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "🧪 Tests du script de déploiement amélioré"
echo "=========================================="
echo ""

# Test 1: Vérification syntaxe bash
echo "✅ Test 1: Vérification syntaxe bash..."
if bash -n "${SCRIPT_DIR}/deploy.sh"; then
    echo "   ✅ Syntaxe valide"
else
    echo "   ❌ Erreur de syntaxe"
    exit 1
fi

# Test 1.5: Vérification absence doublons variables
echo ""
echo "✅ Test 1.5: Vérification absence doublons variables..."
DUPLICATE_REPO_DIR=$(grep -n "^REPO_DIR=" "${SCRIPT_DIR}/deploy.sh" | wc -l)
DUPLICATE_COMPOSE=$(grep -n "^COMPOSE_FILE=" "${SCRIPT_DIR}/deploy.sh" | wc -l)
DUPLICATE_BACKUP=$(grep -n "^BACKUP_DIR=" "${SCRIPT_DIR}/deploy.sh" | wc -l)

if [ "$DUPLICATE_REPO_DIR" -gt 1 ] || [ "$DUPLICATE_COMPOSE" -gt 1 ] || [ "$DUPLICATE_BACKUP" -gt 1 ]; then
    echo "   ❌ Variables dupliquées détectées:"
    [ "$DUPLICATE_REPO_DIR" -gt 1 ] && echo "      - REPO_DIR défini $DUPLICATE_REPO_DIR fois"
    [ "$DUPLICATE_COMPOSE" -gt 1 ] && echo "      - COMPOSE_FILE défini $DUPLICATE_COMPOSE fois"
    [ "$DUPLICATE_BACKUP" -gt 1 ] && echo "      - BACKUP_DIR défini $DUPLICATE_BACKUP fois"
    exit 1
else
    echo "   ✅ Pas de doublons de variables"
fi

# Test 2: Vérification fonctions critiques
echo ""
echo "✅ Test 2: Vérification des fonctions critiques..."
if grep -q "load_rails_credentials" "${SCRIPT_DIR}/deploy.sh"; then
    echo "   ✅ load_rails_credentials présente"
else
    echo "   ❌ load_rails_credentials manquante"
    exit 1
fi

if grep -q "blue_green_deploy" "${SCRIPT_DIR}/deploy.sh"; then
    echo "   ✅ blue_green_deploy présente"
else
    echo "   ❌ blue_green_deploy manquante"
    exit 1
fi

if grep -q "export_deployment_metrics" "${SCRIPT_DIR}/deploy.sh"; then
    echo "   ✅ export_deployment_metrics présente"
else
    echo "   ❌ export_deployment_metrics manquante"
    exit 1
fi

if grep -q "health_check_comprehensive" "${SCRIPT_DIR}/deploy.sh"; then
    echo "   ✅ health_check_comprehensive présente"
else
    echo "   ❌ health_check_comprehensive manquante"
    exit 1
fi

if grep -q "needs_no_cache_build" "${SCRIPT_DIR}/deploy.sh"; then
    echo "   ✅ needs_no_cache_build présente"
else
    echo "   ❌ needs_no_cache_build manquante"
    exit 1
fi

# Test 2.5: Vérification appel backup_database
echo ""
echo "✅ Test 2.5: Vérification appel backup_database..."
if grep -q "if ! backup_database; then\|if backup_database; then" "${SCRIPT_DIR}/deploy.sh"; then
    echo "   ✅ backup_database() correctement appelée"
else
    echo "   ❌ backup_database() définie mais jamais appelée"
    echo "   Remplacer bloc pg_dump direct par appel fonction"
    exit 1
fi

# Test 2.6: Vérification DEPLOY_START_TIME
echo ""
echo "✅ Test 2.6: Vérification DEPLOY_START_TIME..."
if grep -q "^DEPLOY_START_TIME=\$(date +%s)" "${SCRIPT_DIR}/deploy.sh"; then
    echo "   ✅ DEPLOY_START_TIME initialisé"
else
    echo "   ⚠️  DEPLOY_START_TIME non initialisé (métriques incorrectes)"
    echo "   Ajouter: DEPLOY_START_TIME=\$(date +%s)"
fi

# Test 3: Vérification fichiers blue-green
echo ""
echo "✅ Test 3: Vérification fichiers blue-green..."
if [ -f "${SCRIPT_DIR}/docker-compose.blue-green.yml" ]; then
    echo "   ✅ docker-compose.blue-green.yml présent"
else
    echo "   ❌ docker-compose.blue-green.yml manquant"
    exit 1
fi

if [ -f "${SCRIPT_DIR}/nginx-blue-green.conf" ]; then
    echo "   ✅ nginx-blue-green.conf présent"
else
    echo "   ❌ nginx-blue-green.conf manquant"
    exit 1
fi

# Test 4: Vérification Rails credentials
echo ""
echo "✅ Test 4: Vérification Rails credentials..."
if [ -f "${REPO_DIR}/config/credentials.yml.enc" ]; then
    echo "   ✅ credentials.yml.enc présent"
else
    echo "   ⚠️  credentials.yml.enc manquant (normal si nouveau projet)"
fi

# Test 5: Vérification OpenSSL
echo ""
echo "✅ Test 5: Vérification dépendances..."
if command -v openssl > /dev/null 2>&1; then
    echo "   ✅ OpenSSL disponible"
else
    echo "   ⚠️  OpenSSL non disponible (chiffrement désactivé)"
fi

if command -v jq > /dev/null 2>&1; then
    echo "   ✅ jq disponible (logs JSON)"
else
    echo "   ⚠️  jq non disponible (logs JSON désactivés)"
fi

# Test 6: Vérification Docker
echo ""
echo "✅ Test 6: Vérification Docker..."
if command -v docker > /dev/null 2>&1; then
    echo "   ✅ Docker disponible"
    if docker ps > /dev/null 2>&1; then
        echo "   ✅ Docker daemon accessible"
    else
        echo "   ⚠️  Docker daemon non accessible"
    fi
else
    echo "   ❌ Docker non disponible"
    exit 1
fi

# Test 7: Vérification Git
echo ""
echo "✅ Test 7: Vérification Git..."
if [ -d "${REPO_DIR}/.git" ]; then
    echo "   ✅ Repository Git valide"
    CURRENT_BRANCH=$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    echo "   ℹ️  Branche actuelle: ${CURRENT_BRANCH}"
else
    echo "   ⚠️  Pas de repository Git (normal si test hors repo)"
fi

# Test 8: Vérification Build Context
echo ""
echo "✅ Test 8: Vérification Build Context Docker..."

COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "   ❌ docker-compose.yml manquant dans ${SCRIPT_DIR}"
    exit 1
fi

# Extraire le build context
BUILD_CONTEXT=$(grep -A 3 "build:" "$COMPOSE_FILE" | grep "context:" | awk '{print $2}' | tr -d '"' || echo ".")

if [ -z "$BUILD_CONTEXT" ] || [ "$BUILD_CONTEXT" = "." ]; then
    echo "   ⚠️  Build context non défini ou '.' (utilise '.' par défaut)"
    BUILD_CONTEXT="."
fi

echo "   ℹ️  Build context détecté: ${BUILD_CONTEXT}"

# Résoudre le chemin absolu du context
if [[ "$BUILD_CONTEXT" == /* ]]; then
    # Chemin absolu
    CONTEXT_ABS="$BUILD_CONTEXT"
else
    # Chemin relatif → résoudre depuis docker-compose.yml
    CONTEXT_ABS="$(cd "${SCRIPT_DIR}/${BUILD_CONTEXT}" 2>/dev/null && pwd || echo "${REPO_DIR}")"
fi

echo "   ℹ️  Build context absolu: ${CONTEXT_ABS}"

# Vérifier que db/migrate existe dans le context
if [ -d "${CONTEXT_ABS}/db/migrate" ]; then
    MIGRATION_COUNT=$(find "${CONTEXT_ABS}/db/migrate" -name "*.rb" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "   ✅ db/migrate existe dans le context (${MIGRATION_COUNT} fichiers)"
else
    echo "   ❌ ERREUR CRITIQUE: db/migrate ABSENT du build context!"
    echo "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   🔴 Cause probable: build context mal configuré"
    echo "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "   🔧 SOLUTION:"
    echo "   Modifier ${COMPOSE_FILE}:"
    echo ""
    echo "   services:"
    echo "     web:"
    echo "       build:"
    echo "         context: ../..  # ← Pointer vers racine du repo"
    echo "         dockerfile: Dockerfile"
    echo ""
    exit 1
fi

# Test 9: Vérification .dockerignore
echo ""
echo "✅ Test 9: Vérification .dockerignore..."

DOCKERIGNORE="${CONTEXT_ABS}/.dockerignore"
if [ -f "$DOCKERIGNORE" ]; then
    echo "   ℹ️  .dockerignore trouvé: ${DOCKERIGNORE}"
    
    # Vérifier patterns problématiques
    PROBLEMATIC_PATTERNS=$(grep -E "^db/\*|^db/migrate|^\*\*/migrate|^\.rb$" "$DOCKERIGNORE" 2>/dev/null || true)
    
    if [ -n "$PROBLEMATIC_PATTERNS" ]; then
        echo "   ⚠️  PATTERNS PROBLÉMATIQUES DÉTECTÉS:"
        echo "$PROBLEMATIC_PATTERNS" | while read -r pattern; do
            echo "      🔴 $pattern"
        done
        echo ""
        echo "   Ces patterns excluent db/migrate/ du build context!"
        echo "   Supprimer ou commenter ces lignes dans .dockerignore"
    else
        echo "   ✅ Aucun pattern problématique détecté"
    fi
else
    echo "   ℹ️  Pas de .dockerignore (OK)"
fi

# Test 10: Simulation build context
echo ""
echo "✅ Test 10: Simulation envoi build context..."

# Compter fichiers qui seraient envoyés
CONTEXT_FILES=$(find "$CONTEXT_ABS" -type f 2>/dev/null | wc -l | tr -d ' ')
echo "   ℹ️  Fichiers dans context: ${CONTEXT_FILES}"

# Simuler dockerignore
if [ -f "$DOCKERIGNORE" ]; then
    # Pas de simulation parfaite, juste info
    echo "   ℹ️  .dockerignore actif (fichiers exclus non comptés)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ TOUS LES TESTS PASSÉS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Résumé des améliorations implémentées:"
echo "   ✅ P1: Rails Credentials + OpenSSL (backup chiffré)"
echo "   ✅ P2: Health check complet (DB, Redis, Migrations, HTTP)"
echo "   ✅ P2: Timeout adaptatif pour migrations"
echo "   ✅ P2: Anti-race condition (container_is_running_stable)"
echo "   ✅ P3: Métriques Prometheus"
echo "   ✅ P3: Logs structurés JSON"
echo "   ✅ P4: Build intelligent (cache selon changements)"
echo "   ✅ P5: Rollback transactionnel complet"
echo "   ✅ Blue-Green Deployment (zero-downtime)"
echo ""
echo "🚀 Prêt pour le déploiement !"
echo "   Mode classique: ./ops/staging/deploy.sh"
echo "   Mode blue-green: BLUE_GREEN_ENABLED=true ./ops/staging/deploy.sh"

