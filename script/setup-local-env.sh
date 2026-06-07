#!/usr/bin/env bash
# Create .env from template for native dev (Postgres local).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -f .env ]]; then
  echo ".env already exists — leave unchanged or edit manually."
else
  cp .env.example .env
  echo "Created .env from .env.example"
fi

echo ""
echo "Next:"
echo "  sudo ./script/setup-local-postgres.sh   # if PostgreSQL server not ready"
echo "  mise install && bundle install"
echo "  npm install"
echo "  bin/rails db:prepare db:seed"
echo "  bin/dev"
