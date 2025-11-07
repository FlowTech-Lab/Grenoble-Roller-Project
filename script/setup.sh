#!/bin/bash
# Setup script for Grenoble Roller Project
# This script helps set up the project on a new machine after git clone/pull

set -e  # Exit on error

echo "🚀 Grenoble Roller Project - Setup Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "Gemfile" ]; then
    echo -e "${RED}❌ Error: Gemfile not found. Are you in the project root?${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Project root detected${NC}"
echo ""

# Check for required tools
echo "📋 Checking prerequisites..."

check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✅ $1 installed${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 not found${NC}"
        return 1
    fi
}

MISSING_TOOLS=0

check_command "docker" || MISSING_TOOLS=1
check_command "docker compose" || MISSING_TOOLS=1
check_command "git" || MISSING_TOOLS=1
check_command "ruby" || MISSING_TOOLS=1
check_command "node" || MISSING_TOOLS=1
check_command "npm" || MISSING_TOOLS=1

if [ $MISSING_TOOLS -eq 1 ]; then
    echo ""
    echo -e "${RED}❌ Some required tools are missing. Please install them first.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ All prerequisites met${NC}"
echo ""

# Check for master.key
echo "🔐 Checking credentials..."
if [ ! -f "config/master.key" ]; then
    echo -e "${YELLOW}⚠️  config/master.key not found${NC}"
    echo "   Generating new credentials..."
    if command -v bundle &> /dev/null; then
        bundle exec rails credentials:edit <<EOF || true
secret_key_base: $(bundle exec rails secret)
EOF
        echo -e "${GREEN}✅ Credentials generated${NC}"
    else
        echo -e "${YELLOW}⚠️  Bundle not available. You may need to run: bin/rails credentials:edit${NC}"
    fi
else
    echo -e "${GREEN}✅ config/master.key found${NC}"
fi
echo ""

# Install Node.js dependencies (if not using Docker)
if [ "$1" != "--docker-only" ]; then
    echo "📦 Installing Node.js dependencies..."
    if [ -f "package-lock.json" ]; then
        npm install
        echo -e "${GREEN}✅ Node.js dependencies installed${NC}"
    else
        echo -e "${YELLOW}⚠️  package-lock.json not found. Run: npm install${NC}"
    fi
    echo ""
fi

# Install Ruby gems (if not using Docker)
if [ "$1" != "--docker-only" ]; then
    echo "💎 Installing Ruby gems..."
    if command -v bundle &> /dev/null; then
        bundle install
        echo -e "${GREEN}✅ Ruby gems installed${NC}"
    else
        echo -e "${YELLOW}⚠️  Bundle not available. Run: bundle install${NC}"
    fi
    echo ""
fi

# Check for .env file
echo "📝 Checking environment variables..."
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file not found${NC}"
    echo "   You may need to create a .env file for staging/production"
    echo "   See docs/07-ops/runbooks/staging-setup.md for details"
else
    echo -e "${GREEN}✅ .env file found${NC}"
fi
echo ""

# Summary
echo "=========================================="
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "Next steps:"
echo ""
echo "📖 For development:"
echo "   docker compose -f ops/dev/docker-compose.yml up -d"
echo "   docker exec grenoble-roller-dev bin/rails db:migrate"
echo "   docker exec grenoble-roller-dev bin/rails db:seed"
echo ""
echo "📖 For staging:"
echo "   git checkout staging"
echo "   docker compose -f ops/staging/docker-compose.yml up -d --build"
echo "   docker exec grenoble-roller-staging bin/rails db:migrate"
echo ""
echo "📚 Documentation:"
echo "   - Local setup: docs/04-rails/setup/local-development.md"
echo "   - Staging setup: docs/07-ops/runbooks/staging-setup.md"
echo ""

