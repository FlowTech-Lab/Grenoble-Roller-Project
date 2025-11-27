#!/bin/bash
# Script de diagnostic : Vérifier pourquoi les fichiers ne sont pas dans le conteneur

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 DIAGNOSTIC : Pourquoi les migrations ne sont pas dans le conteneur ?"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Vérifier que les fichiers existent localement
echo "1️⃣ Vérification fichiers locaux..."
MIGRATION_FILES=(
    "db/migrate/20250126180000_add_donation_cents_to_orders.rb"
    "db/migrate/20251117011815_add_image_url_to_product_variants.rb"
    "db/migrate/20251124013654_add_skill_level_to_users.rb"
    "db/migrate/20251124020634_add_confirmable_to_users.rb"
)

for file in "${MIGRATION_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $(basename $file) existe"
    else
        echo "  ❌ $(basename $file) ABSENT localement"
    fi
done

echo ""

# 2. Vérifier .dockerignore
echo "2️⃣ Vérification .dockerignore..."
if grep -qE "^db/|^db/migrate|^\*\*/migrate" .dockerignore 2>/dev/null; then
    echo "  ❌ PROBLÈME DÉTECTÉ : .dockerignore exclut db/ ou db/migrate"
    grep -E "^db/|^db/migrate|^\*\*/migrate" .dockerignore
else
    echo "  ✅ .dockerignore n'exclut pas db/migrate"
fi

echo ""

# 3. Vérifier build context
echo "3️⃣ Vérification build context..."
BUILD_CONTEXT=$(docker compose -f ops/staging/docker-compose.yml config 2>&1 | grep -A 3 "build:" | grep "context:" | awk '{print $2}' | tr -d '"')
echo "  Build context: $BUILD_CONTEXT"

if [ -d "${BUILD_CONTEXT}/db/migrate" ]; then
    MIGRATION_COUNT=$(find "${BUILD_CONTEXT}/db/migrate" -name "*.rb" -type f | wc -l)
    echo "  ✅ db/migrate existe dans build context (${MIGRATION_COUNT} fichiers)"
    
    for file in "${MIGRATION_FILES[@]}"; do
        if [ -f "${BUILD_CONTEXT}/${file}" ]; then
            echo "    ✅ $(basename $file) dans build context"
        else
            echo "    ❌ $(basename $file) ABSENT du build context"
        fi
    done
else
    echo "  ❌ db/migrate n'existe PAS dans le build context !"
fi

echo ""

# 4. Vérifier Dockerfile COPY
echo "4️⃣ Vérification Dockerfile..."
if grep -q "COPY . ." Dockerfile; then
    echo "  ✅ Dockerfile contient 'COPY . .' (devrait copier db/migrate)"
else
    echo "  ❌ Dockerfile ne contient pas 'COPY . .'"
fi

echo ""

# 5. Test build context avec tar
echo "5️⃣ Test : Simuler ce que Docker envoie au build context..."
# Docker envoie un tar du build context, simuler avec tar
TAR_TEST=$(cd "$BUILD_CONTEXT" && tar --exclude-from=.dockerignore -czf - db/migrate/*.rb 2>&1 | wc -c)
if [ "$TAR_TEST" -gt 0 ]; then
    echo "  ✅ Les fichiers seraient inclus dans le tar du build context"
    cd "$BUILD_CONTEXT" && tar --exclude-from=.dockerignore -czf - db/migrate/*.rb 2>&1 | tar -tzf - | grep -E "20250126180000|20251117011815|20251124013654|20251124020634" | head -4
else
    echo "  ❌ Les fichiers ne seraient PAS inclus dans le tar"
fi

echo ""

# 6. Vérifier cache Docker
echo "6️⃣ Vérification cache Docker..."
CACHE_SIZE=$(docker system df 2>&1 | grep "Build Cache" | awk '{print $4}' || echo "0")
echo "  Cache Docker: ${CACHE_SIZE}"

echo ""

# 7. Vérifier l'image actuelle
echo "7️⃣ Vérification image actuelle..."
if docker images | grep -q "grenoble-roller-staging"; then
    IMAGE_ID=$(docker images --format "{{.ID}}" grenoble-roller-staging | head -1)
    echo "  Image ID: ${IMAGE_ID:0:12}"
    
    # Tester si on peut lister les migrations dans l'image
    echo "  Test extraction migrations depuis image..."
    docker create --name test-extract "$IMAGE_ID" > /dev/null 2>&1 || true
    if docker cp test-extract:/rails/db/migrate/. /tmp/test-migrations/ 2>/dev/null; then
        EXTRACTED_COUNT=$(ls -1 /tmp/test-migrations/*.rb 2>/dev/null | wc -l)
        echo "    ✅ ${EXTRACTED_COUNT} migrations extraites de l'image"
        
        for file in "${MIGRATION_FILES[@]}"; do
            basename_file=$(basename "$file")
            if [ -f "/tmp/test-migrations/${basename_file}" ]; then
                echo "      ✅ $(basename $file) dans l'image"
            else
                echo "      ❌ $(basename $file) ABSENT de l'image"
            fi
        done
        rm -rf /tmp/test-migrations
    else
        echo "    ⚠️  Impossible d'extraire les migrations de l'image"
    fi
    docker rm test-extract > /dev/null 2>&1 || true
else
    echo "  ⚠️  Image grenoble-roller-staging non trouvée"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Diagnostic terminé"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

