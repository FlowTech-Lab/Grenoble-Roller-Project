#!/usr/bin/env bash
# One-time: PostgreSQL server + databases for native dev (Ubuntu).
set -euo pipefail

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends postgresql postgresql-contrib

systemctl enable --now postgresql

# Password auth for local dev (matches .env.example)
sudo -u postgres psql -v ON_ERROR_STOP=1 <<'SQL'
ALTER USER postgres WITH PASSWORD 'postgres';
SQL

sudo -u postgres createdb grenoble_roller_development 2>/dev/null || true
sudo -u postgres createdb grenoble_roller_test 2>/dev/null || true

echo "PostgreSQL ready on localhost:5432"
echo "  development: grenoble_roller_development"
echo "  test:        grenoble_roller_test"
echo "  user/pass:   postgres / postgres"
