#!/usr/bin/env bash
# APT packages for native Ruby 3.4 (mise) on Ubuntu — aligned with Dockerfile.dev.
# Run once on dev-workstation: sudo ./script/install-native-deps.sh
set -euo pipefail

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends \
  build-essential \
  curl \
  git \
  libffi-dev \
  libgdbm-dev \
  libncurses-dev \
  libpq-dev \
  libreadline-dev \
  libssl-dev \
  libvips42 \
  libvips-dev \
  libyaml-dev \
  pkg-config \
  postgresql-client \
  zlib1g-dev

echo "Native deps installed. Next (as user, no sudo):"
echo "  cd $(dirname "$0")/.."
echo "  mise install"
echo "  bundle config set --local path vendor/bundle"
echo "  bundle install"
