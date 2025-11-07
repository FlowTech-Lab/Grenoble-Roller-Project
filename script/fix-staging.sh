#!/bin/bash
# Quick fix script for staging environment issues

set -e

echo "🔧 Fixing Staging Environment"
echo "============================="
echo ""

# Check if we're in the right directory
if [ ! -f "ops/staging/docker-compose.yml" ]; then
    echo "❌ Error: ops/staging/docker-compose.yml not found"
    echo "   Are you in the project root?"
    exit 1
fi

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker compose -f ops/staging/docker-compose.yml down 2>/dev/null || true

# Rebuild without cache
echo ""
echo "🔨 Rebuilding containers (this may take a while)..."
docker compose -f ops/staging/docker-compose.yml build --no-cache

# Start containers
echo ""
echo "🚀 Starting containers..."
docker compose -f ops/staging/docker-compose.yml up -d

# Wait a bit
echo ""
echo "⏳ Waiting for services to start..."
sleep 10

# Check status
echo ""
echo "📊 Container status:"
docker ps | grep staging || echo "⚠️  No staging containers running"

# Show logs if container exists
if docker ps -a | grep -q grenoble-roller-staging; then
    echo ""
    echo "📋 Recent logs from web container:"
    docker logs --tail 50 grenoble-roller-staging 2>&1 || echo "⚠️  Could not get logs"
fi

echo ""
echo "=========================================="
echo "✅ Fix attempt complete!"
echo ""
echo "If containers are not running, check logs:"
echo "  docker logs grenoble-roller-staging"
echo "  docker compose -f ops/staging/docker-compose.yml logs"
echo ""
echo "Run migrations if needed:"
echo "  docker exec grenoble-roller-staging bin/rails db:migrate"
echo ""

