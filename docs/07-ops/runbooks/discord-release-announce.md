---
title: "Discord release announce (GitHub Actions)"
status: "active"
version: "1.0"
created: "2026-08-03"
updated: "2026-08-03"
tags: ["ops", "discord", "ci", "release", "staging", "production"]
---

# Discord release announce (CI)

Automatic **release** announcements to the Grenoble Roller Discord channel when `staging` or `main` is updated (typically after a merge).

**Not** the same as [DR-002](../../10-decisions-and-changelog/DR-002-discord-webhook-notifications.md) (admin runtime ops webhooks inside the Rails app).

| Item | Value |
| --- | --- |
| Workflow | [`.github/workflows/discord-release.yml`](../../../.github/workflows/discord-release.yml) |
| Script | [`.github/scripts/discord-release-announce.sh`](../../../.github/scripts/discord-release-announce.sh) |
| Payload | [`.github/release-discord.yml`](../../../.github/release-discord.yml) |
| Target channel | `1513250924489867455` (Grenoble Roller guild) |
| GitHub secret | `DISCORD_RELEASE_WEBHOOK` |

---

## Behaviour

| Event | Discord label | Site URL |
| --- | --- | --- |
| Push / merge → `staging` | Patch Staging | https://staging.grenoble-roller.org |
| Push / merge → `main` | Patch Production | https://grenoble-roller.org |
| Manual `workflow_dispatch` | Chosen input (`staging` / `production`) | Same as above |

**Skip (job stays green):**

- Commit message contains `[skip discord]`
- Secret `DISCORD_RELEASE_WEBHOOK` is missing / empty

---

## Setup (one-time)

1. Discord → salon `1513250924489867455` → Integrations → Webhooks → create (or regenerate if the URL was exposed).
2. Store the URL as a **GitHub Actions secret** (never commit it):

```bash
# From a machine with gh auth (paste URL on stdin, no echo in shell history if possible)
printf '%s' "$GRENOBLE_ROLLER_DISCORD_RELEASE_WEBHOOK" | \
  gh secret set DISCORD_RELEASE_WEBHOOK --repo Grenoble-roller/Grenoble-Roller-Website
```

Or: GitHub → repo → Settings → Secrets and variables → Actions → New repository secret → name `DISCORD_RELEASE_WEBHOOK`.

3. Optional local smoke (same URL in gitignored `.env` as `GRENOBLE_ROLLER_DISCORD_RELEASE_WEBHOOK` or `DISCORD_RELEASE_WEBHOOK`):

```bash
export DISCORD_RELEASE_WEBHOOK=...   # from .env, do not paste in chat
export RELEASE_ENV=staging
.github/scripts/discord-release-announce.sh
```

4. Optional CI dry-run: Actions → **Discord release announce** → Run workflow → choose environment.

---

## Release process (every ship)

1. Update [`.github/release-discord.yml`](../../../.github/release-discord.yml) (`version`, `headline`, `bullets`) in the same PR as the patch note / CHANGELOG.
2. Merge to `staging` → Discord **Patch Staging** posts automatically.
3. After staging validation, merge `staging` → `main` → Discord **Patch Production** posts automatically.

If you must push without announcing: include `[skip discord]` in the merge commit message.

---

## Rollback / annulation

- Disable or delete the GitHub secret → workflow skips (green).
- Delete or regenerate the Discord webhook URL → rotate secret to the new URL.
- Wrong post: delete the Discord message manually; fix YAML and re-run `workflow_dispatch` if needed.

---

## Security

- Never commit webhook URLs.
- If a webhook was pasted in chat or logs, **regenerate** it in Discord and update the GitHub secret + local `.env`.
