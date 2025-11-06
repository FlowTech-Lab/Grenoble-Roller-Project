#!/bin/bash
# Docker-only setup script for Grenoble Roller Project
# Quick setup using Docker (recommended)

set -e  # Exit on error

echo "🐳 Grenoble Roller Project - Docker Setup"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker first."
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose not found. Please install Docker Compose first."
    exit 1
fi

# Check for master.key
if [ ! -f "config/master.key" ]; then
    echo "⚠️  config/master.key not found"
    echo "   You may need to regenerate credentials:"
    echo "   bin/rails credentials:edit"
    echo ""
fi

# Ask which environment
echo "Which environment do you want to set up?"
echo "1) Development (default)"
echo "2) Staging"
read -p "Choice [1]: " choice
choice=${choice:-1}

case $choice in
    1)
        ENV="dev"
        COMPOSE_FILE="ops/dev/docker-compose.yml"
        CONTAINER="grenoble-roller-dev"
        ;;
    2)
        ENV="staging"
        COMPOSE_FILE="ops/staging/docker-compose.yml"
        CONTAINER="grenoble-roller-staging"
        
        # Check for staging branch
        if [ "$(git branch --show-current)" != "staging" ]; then
            echo "⚠️  You're not on the staging branch"
            read -p "Switch to staging branch? [y/N]: " switch
            if [ "$switch" = "y" ] || [ "$switch" = "Y" ]; then
                git checkout staging
                git pull origin staging
            fi
        fi
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "🚀 Starting Docker setup for $ENV environment..."
echo ""

# Build and start containers
echo "📦 Building and starting containers..."
docker compose -f $COMPOSE_FILE up -d --build

echo ""
echo "⏳ Waiting for services to be healthy..."
sleep 5

# Check container status
if docker ps | grep -q $CONTAINER; then
    echo "✅ Container is running"
else
    echo "❌ Container failed to start. Check logs:"
    echo "   docker logs $CONTAINER"
    exit 1
fi

# Run migrations
echo ""
echo "🗄️  Running database migrations..."
docker exec $CONTAINER bin/rails db:migrate

# Ask about seeds
echo ""
read -p "Run database seeds? [y/N]: " seed
if [ "$seed" = "y" ] || [ "$seed" = "Y" ]; then
    echo "🌱 Seeding database..."
    docker exec $CONTAINER bin/rails db:seed
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""

if [ "$ENV" = "dev" ]; then
    echo "🌐 Application available at: http://localhost:3000"
else
    echo "🌐 Application available at: http://localhost:3001"
fi

echo ""
echo "Useful commands:"
echo "  View logs:    docker logs -f $CONTAINER"
echo "  Rails console: docker exec -it $CONTAINER bin/rails console"
echo "  Stop:         docker compose -f $COMPOSE_FILE down"
echo ""

