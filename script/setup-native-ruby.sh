#!/usr/bin/env bash
# Native dev-workstation setup: mise Ruby 3.4.2 + vendor/bundle (not system /usr/bin/ruby).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="${HOME}/.local/bin:${PATH}"

echo "== Ruby $(mise exec ruby@3.4.2 -- ruby --version) =="

echo "== Clean vendor/bundle (removes ruby/3.2.0 from system /usr/bin/bundle) =="
if [[ -d "$ROOT/vendor/bundle/ruby/3.2.0" ]]; then
  echo "Removing vendor/bundle/ruby/3.2.0"
fi
rm -rf "$ROOT/vendor/bundle"

echo "== Bundler 2.7.2 =="
mise exec ruby@3.4.2 -- gem install bundler -v 2.7.2 --no-document

echo "== bundle install =="
"$ROOT/bin/bundle" config set --local path vendor/bundle
"$ROOT/bin/bundle" install

echo "Done. Always use: ./bin/bundle install  (never bare: bundle install)"
