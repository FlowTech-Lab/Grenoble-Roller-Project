---
title: "Discord release announce (GitHub Actions)"
status: "active"
version: "1.1"
created: "2026-08-03"
updated: "2026-08-03"
tags: ["ops", "discord", "ci", "release", "staging", "production"]
---

# Discord release announce (CI)

Automatic **release** announcements when `staging` or `main` is updated (typically after a merge).

**Not** the same as [DR-002](../../10-decisions-and-changelog/DR-002-discord-webhook-notifications.md) (admin runtime ops webhooks inside the Rails app).

| Item | Value |
| --- | --- |
| Workflow | [`.github/workflows/discord-release.yml`](../../../.github/workflows/discord-release.yml) |
| Script | [`.github/scripts/discord-release-announce.sh`](../../../.github/scripts/discord-release-announce.sh) |
| Payload | [`.github/release-discord.yml`](../../../.github/release-discord.yml) |
| Staging channel | `1522208233291382836` (Captain Hook) |
| Production channel | `1513250924489867455` (Grenoble Roller release salon) |
| Secrets | `DISCORD_RELEASE_WEBHOOK_STAGING` · `DISCORD_RELEASE_WEBHOOK_PRODUCTION` |

---

## Behaviour

| Event | Discord label | Channel | Site URL |
| --- | --- | --- | --- |
| Push / merge → `staging` | Patch Staging | Captain Hook | https://staging.grenoble-roller.org |
| Push / merge → `main` | Patch Production | Prod release salon | https://grenoble-roller.org |
| Manual `workflow_dispatch` | Chosen input | Matching secret | Same as above |

**Skip (job stays green):**

- Commit message contains `[skip discord]`
- The webhook secret for that environment is missing / empty

---

## Setup (one-time)

1. Create / copy Discord webhooks:
   - **Staging** → Captain Hook channel `1522208233291382836`
   - **Production** → release salon `1513250924489867455`
2. Store as **GitHub Actions secrets** (never commit URLs):

```bash
# Staging (Captain Hook)
printf '%s' "$DISCORD_RELEASE_WEBHOOK_STAGING" | \
  gh secret set DISCORD_RELEASE_WEBHOOK_STAGING --repo Grenoble-roller/Grenoble-Roller-Website

# Production (GR release salon)
printf '%s' "$DISCORD_RELEASE_WEBHOOK_PRODUCTION" | \
  gh secret set DISCORD_RELEASE_WEBHOOK_PRODUCTION --repo Grenoble-roller/Grenoble-Roller-Website
```

Optional local `.env` (gitignored):

```bash
DISCORD_RELEASE_WEBHOOK_STAGING=...
DISCORD_RELEASE_WEBHOOK_PRODUCTION=...
# Legacy alias still accepted by the script for a single env:
# DISCORD_RELEASE_WEBHOOK=...
```

3. Local smoke:

```bash
export RELEASE_ENV=staging   # or production
.github/scripts/discord-release-announce.sh
```

4. CI dry-run: Actions → **Discord release announce** → Run workflow → choose environment.

---

## Release process (every ship)

1. Update [`.github/release-discord.yml`](../../../.github/release-discord.yml) (`version`, `headline`, `bullets`) in the same PR as the patch note / CHANGELOG.
2. Merge to `staging` → **Captain Hook** gets Patch Staging.
3. After staging validation, merge `staging` → `main` → **prod salon** gets Patch Production.

If you must push without announcing: include `[skip discord]` in the merge commit message.

---

## Rollback / annulation

- Delete the env-specific GitHub secret → that env skips (green).
- Regenerate a Discord webhook → update the matching secret + local `.env`.
- Wrong post: delete the Discord message manually; fix YAML and re-run `workflow_dispatch`.

---

## Security

- Never commit webhook URLs.
- If a webhook was pasted in chat or logs, **regenerate** it in Discord and update the matching GitHub secret.
