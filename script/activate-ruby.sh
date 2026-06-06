#!/usr/bin/env bash
# Interactive shell: mise Ruby 3.4.2 + repo bin/ before system /usr/bin.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REQUIRED_RUBY="3.4.2"

export PATH="${HOME}/.local/bin:${PATH}"

if ! command -v mise >/dev/null 2>&1; then
  echo "ERROR: mise is not installed. Run: curl https://mise.run | sh" >&2
  return 1 2>/dev/null || exit 1
fi

cd "$REPO_ROOT"
mise install --quiet 2>/dev/null || mise install

case ":${PATH}:" in
  *":${REPO_ROOT}/bin:"*) ;;
  *) export PATH="${REPO_ROOT}/bin:${PATH}" ;;
esac

ACTUAL_RUBY="$(mise exec ruby@3.4.2 -- ruby -e 'print RUBY_VERSION')"
if [[ "$ACTUAL_RUBY" != "$REQUIRED_RUBY" ]]; then
  echo "ERROR: Ruby ${REQUIRED_RUBY} required, but got ${ACTUAL_RUBY}" >&2
  echo "Do not run /usr/bin/bundle (Ruby 3.2). Use: ./bin/bundle install" >&2
  return 1 2>/dev/null || exit 1
fi

# Optional: mise shims for gem, rails, etc. when shell is interactive
if [[ -n "${PS1:-}" ]] && [[ -z "${GRENOBLE_ROLLER_MISE_ACTIVATED:-}" ]]; then
  eval "$(mise activate bash)"
  export GRENOBLE_ROLLER_MISE_ACTIVATED=1
fi
