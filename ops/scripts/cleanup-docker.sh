#!/bin/bash
# Script de nettoyage Docker pour environnement dev
# Usage: ./ops/scripts/cleanup-docker.sh [--aggressive]

set -euo pipefail

AGGRESSIVE=false

# Parse arguments
if [ "${1:-}" = "--aggressive" ]; then
    AGGRESSIVE=true
fi

echo "🧹 Nettoyage Docker..."

# 1. Nettoyer les conteneurs arrêtés
echo "📦 Suppression des conteneurs arrêtés..."
docker container prune -f

# 2. Nettoyer les images non utilisées
echo "🖼️  Suppression des images non utilisées..."
docker image prune -f

# 3. Nettoyer les volumes non utilisés (seulement ceux non référencés)
echo "💾 Suppression des volumes non utilisés..."
docker volume prune -f

# 4. Nettoyer le build cache (optionnel, peut être long)
if [ "$AGGRESSIVE" = true ]; then
    echo "🗑️  Suppression du build cache Docker (peut prendre du temps)..."
    docker builder prune -af
else
    echo "🗑️  Suppression du build cache non utilisé..."
    docker builder prune -f
fi

# 5. Nettoyer les réseaux non utilisés
echo "🌐 Suppression des réseaux non utilisés..."
docker network prune -f

# 6. Afficher l'espace libéré
echo ""
echo "✅ Nettoyage terminé !"
echo ""
echo "📊 Espace disque utilisé par Docker :"
docker system df

echo ""
echo "💡 Pour un nettoyage plus agressif (incluant le build cache) :"
echo "   ./ops/scripts/cleanup-docker.sh --aggressive"

