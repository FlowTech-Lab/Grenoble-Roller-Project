#!/usr/bin/env bash
# Cursor / VS Code integrated terminal: load user shell then project Ruby 3.4.2.
[[ -f "${HOME}/.bashrc" ]] && source "${HOME}/.bashrc"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=activate-ruby.sh
source "$ROOT/script/activate-ruby.sh"
