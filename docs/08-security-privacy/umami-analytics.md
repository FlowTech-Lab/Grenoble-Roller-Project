---
title: "Umami web analytics"
status: "active"
version: "1.0"
created: "2026-06-05"
tags: ["analytics", "umami", "rgpd", "cookies"]
---

# Umami web analytics

Privacy-focused page analytics for the public site. Self-hosted Umami instance; no Google Analytics.

## Environment variables

Set in Dokploy / Docker (`ops/dokploy/env/*.env.example`). Leave unset in local dev to disable tracking.

| Variable | Required | Description |
| --- | --- | --- |
| `UMAMI_SCRIPT_URL` | Yes | Tracker script URL, e.g. `https://stats.grenoble-roller.org/script.js` |
| `UMAMI_WEBSITE_ID` | Yes | Website UUID from Umami admin |
| `UMAMI_DASHBOARD_URL` | No | Admin dashboard link (ops reference only, not injected in HTML) |
| `UMAMI_SHARE_URL` | No | Public read-only dashboard — footer link + bouton on `/about` |

## Public stats link

When `UMAMI_SHARE_URL` is set (Umami **Share URL** in admin), the site shows:

- Footer legal nav: **Statistiques du site**
- `/about` section **Transparence** with button **Voir les statistiques publiques**

Partial: `app/views/shared/_umami_public_stats_link.html.erb` — no admin login required.

## Consent (RGPD)

The tracker script is rendered **only** when:

1. Both `UMAMI_*` vars are set, **and**
2. The user opted in to **analytics** cookies (`cookie_consent[:analytics]`).

Umami does not use cookies in its tracker, but audience measurement still requires consent under the site cookie policy. See [`legal-pages-implementation.md`](legal-pages-implementation.md).

## Code

| Piece | Path |
| --- | --- |
| Helper | `app/helpers/analytics_helper.rb` |
| Layout partial | `app/views/layouts/_umami.html.erb` |
| Public stats link | `app/views/shared/_umami_public_stats_link.html.erb` |
| Custom events (optional) | `app/javascript/umami.js` → `trackUmamiEvent(name, data?)` |

**Excluded:** `/admin-panel` uses `layouts/admin.html.erb` without the Umami partial.

## Custom events

Use sparingly for UX funnels (shop, membership, event signup). Do **not** send emails, names, HelloAsso amounts, or user IDs.

```javascript
import { trackUmamiEvent } from "umami"

trackUmamiEvent("shop_checkout_start")
```

## Ops

- Prefer a first-party subdomain (`stats.grenoble-roller.org`) to reduce ad-blocker drops.
- Use separate Umami website IDs per environment when possible (staging vs production).
