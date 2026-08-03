#!/usr/bin/env bash
# Post a release announce to Discord via webhook.
# Env:
#   DISCORD_RELEASE_WEBHOOK  — required (GitHub secret)
#   RELEASE_ENV              — staging | production (default: staging)
#   GITHUB_SHA, GITHUB_REPOSITORY, GITHUB_SERVER_URL — from Actions
#   GITHUB_EVENT_BEFORE      — previous SHA on push (optional)
#   ANNOUNCE_FILE            — path to release-discord.yml (default: .github/release-discord.yml)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

ANNOUNCE_FILE="${ANNOUNCE_FILE:-.github/release-discord.yml}"
RELEASE_ENV="${RELEASE_ENV:-staging}"
SHA="${GITHUB_SHA:-$(git rev-parse HEAD)}"
SHORT_SHA="${SHA:0:7}"
REPO="${GITHUB_REPOSITORY:-Grenoble-roller/Grenoble-Roller-Website}"
SERVER="${GITHUB_SERVER_URL:-https://github.com}"
BEFORE="${GITHUB_EVENT_BEFORE:-}"

if [[ -z "${DISCORD_RELEASE_WEBHOOK:-}" ]]; then
  echo "DISCORD_RELEASE_WEBHOOK is empty — skipping announce (no failure)."
  exit 0
fi

case "$RELEASE_ENV" in
  production|main|prod)
    RELEASE_ENV="production"
    LABEL="Patch Production"
    SITE_URL="https://grenoble-roller.org"
    HELLOASSO="HelloAsso **live**"
    COLOR=5763719
    ;;
  *)
    RELEASE_ENV="staging"
    LABEL="Patch Staging"
    SITE_URL="https://staging.grenoble-roller.org"
    HELLOASSO="HelloAsso **sandbox** · **pas la prod**"
    COLOR=15105570
    ;;
esac

COMPARE_URL=""
if [[ -n "$BEFORE" && "$BEFORE" != "0000000000000000000000000000000000000000" ]]; then
  COMPARE_URL="${SERVER}/${REPO}/compare/${BEFORE}...${SHA}"
else
  COMPARE_URL="${SERVER}/${REPO}/commit/${SHA}"
fi

# Parse announce YAML + build Discord payload (Python — available on ubuntu-latest).
PAYLOAD="$(
  ANNOUNCE_FILE="$ANNOUNCE_FILE" \
  RELEASE_ENV="$RELEASE_ENV" \
  LABEL="$LABEL" \
  SITE_URL="$SITE_URL" \
  HELLOASSO="$HELLOASSO" \
  COLOR="$COLOR" \
  SHORT_SHA="$SHORT_SHA" \
  COMPARE_URL="$COMPARE_URL" \
  ROOT="$ROOT" \
  python3 <<'PY'
import json, os, re, pathlib

root = pathlib.Path(os.environ["ROOT"])
path = root / os.environ["ANNOUNCE_FILE"]
label = os.environ["LABEL"]
site = os.environ["SITE_URL"]
hello = os.environ["HELLOASSO"]
color = int(os.environ["COLOR"])
short = os.environ["SHORT_SHA"]
compare = os.environ["COMPARE_URL"]

version = ""
headline = ""
bullets = []

if path.is_file():
    text = path.read_text(encoding="utf-8")
    # Minimal YAML subset (no external deps): version, headline, bullets list.
    m = re.search(r'(?m)^version:\s*["\']?([^"\'\n]+)', text)
    if m:
        version = m.group(1).strip()
    m = re.search(r'(?m)^headline:\s*["\']?(.+?)\s*$', text)
    if m:
        headline = m.group(1).strip().strip("\"'")
    in_bullets = False
    for line in text.splitlines():
        if re.match(r"^bullets:\s*$", line):
            in_bullets = True
            continue
        if in_bullets:
            if re.match(r"^\S", line) and not line.startswith("#"):
                break
            bm = re.match(r'^\s*-\s*["\']?(.*?)["\']?\s*$', line)
            if bm:
                bullets.append(bm.group(1).strip().strip("\"'"))

# Fallback: first CHANGELOG H2
if not version or not headline:
    cl = root / "docs/10-decisions-and-changelog/CHANGELOG.md"
    if cl.is_file():
        for line in cl.read_text(encoding="utf-8").splitlines():
            if line.startswith("## ["):
                # ## [2026-08-03] - Title (v2.3.3)
                vm = re.search(r"\(v([\d.]+)\)", line)
                if vm and not version:
                    version = vm.group(1)
                title = re.sub(r"^##\s*\[[^\]]+\]\s*-\s*", "", line)
                title = re.sub(r"\s*\(v[\d.]+[^)]*\)\s*$", "", title).strip()
                if not headline:
                    headline = title
                break

if not version:
    version = short
if not headline:
    headline = f"Release `{short}`"
if not bullets:
    bullets = [f"Détails : {compare}"]

ver_label = version if version.startswith("v") else f"v{version}"
content = (
    f"🎿 **{label} {ver_label}** — déployé / en ligne\n"
    f"Environnement : **{site}** · {hello}\n"
    f"Commit : `{short}` · {compare}"
)

fields = []
# Discord field value max 1024; keep bullets compact
bullet_text = "\n".join(f"• {b}" for b in bullets[:12])
if len(bullet_text) > 1000:
    bullet_text = bullet_text[:997] + "…"
fields.append({"name": "Changements", "value": bullet_text, "inline": False})
fields.append({"name": "Ops", "value": "Migrations / ENV : voir la release note du repo · Rollback = redeploy image précédente", "inline": False})

payload = {
    "username": "Grenoble Roller — Release",
    "content": content,
    "embeds": [
        {
            "title": headline[:256],
            "color": color,
            "fields": fields,
        }
    ],
}
print(json.dumps(payload, ensure_ascii=False))
PY
)"

HTTP="$(curl -sS -o /tmp/discord-release-out.txt -w '%{http_code}' -X POST \
  -H 'Content-Type: application/json' \
  -d "$PAYLOAD" \
  "$DISCORD_RELEASE_WEBHOOK")"

echo "discord_release_http=${HTTP}"
if [[ "$HTTP" != "204" && "$HTTP" != "200" ]]; then
  echo "Discord webhook failed (HTTP ${HTTP}). Body:" >&2
  cat /tmp/discord-release-out.txt >&2 || true
  exit 1
fi
echo "Discord release announce posted (${RELEASE_ENV})."
