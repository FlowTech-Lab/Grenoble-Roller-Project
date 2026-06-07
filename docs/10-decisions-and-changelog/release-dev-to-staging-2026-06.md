---
title: "Release Dev → staging (June 2026)"
status: "active"
version: "1.0"
created: "2026-06-07"
tags: ["release", "staging", "changelog"]
---

# Release Dev → staging (June 2026)

**Target branch:** merge `Dev` into `staging`  
**Commit range:** `2e627ba8` … `c09b9f51` (22 commits on `Dev` ahead of `origin/staging`)  
**Includes uncommitted work:** roller stock reservation model (Option 2) — see [Roller stock](#roller-stock-reservations-v23)

---

## Summary / scope

This release bundles public-site UX improvements (events, homepage, analytics), admin-panel capabilities (event read access, organizers, goodies tracking, mail logs, carousel settings), security (Turnstile on contact form), developer tooling (mise, dotenv, vendor cleanup), and a **breaking operational change** for roller stock: physical quantities are no longer decremented on registration; availability is computed from active reservations per initiation.

**Out of scope for this release doc:** Dependabot config, vendor/bundle removal from git (no runtime impact on staging after deploy).

---

## Features by domain

### Events

| Change | Description |
| --- | --- |
| Past/upcoming lifecycle | Events classified as past when **end time** (`start_at + duration_min`) has passed; **ongoing** badge while in progress |
| Multi-loop UI | Overlay loop cards on show pages; per-loop distance labels; compact practical info grid |
| Route map viewer | Fullscreen pinch-zoom viewer (`route_image_viewer_controller.js`) on route/loop map images |
| Admin route names hidden | Internal route names not exposed on public show pages |
| Mobile past events | Improved layout for past events on small screens |
| Multi-loop preload | Routes preloaded on edit; per-loop distances shown on show |
| Event organizers | `EventOrganizer` model; optional `organizer_id` on events; admin CRUD + public display on event forms/show |
| Registration emails | Participant name (parent or child) shown in attendance confirmation emails |

### Admin panel

| Change | Description |
| --- | --- |
| Events read access | Level ≥ 40 (ORGANIZER, MODERATOR, …) can **view** randos in admin panel; write remains level ≥ 60 |
| Event organizers | CRUD at `/admin-panel/event-organizers`; linked from events submenu (admin) or direct link (organizer) |
| Goodies distribution | `memberships.goodies_distributed` flag; filter/scope in memberships admin |
| Mail logs | `OutboundEmailLog` persisted via ActiveJob subscriber; mail-logs panel shows outbound history |
| Homepage carousel | `HomepageCarouselSetting` singleton: autoplay on/off and interval (2–30 s) configurable in admin |
| Role guards | `UserPolicy` + `RoleAssignmentService` prevent admins from editing/deleting super admins |
| Membership edit | Fix for child membership edit form |

### Memberships

- Track **goodies distributed** per membership (`goodies_distributed` boolean, indexed).

### Homepage

- Configurable carousel autoplay and slide interval (admin → carousel index → settings).

### Analytics

- **Umami** tracking injected only when `UMAMI_SCRIPT_URL` + `UMAMI_WEBSITE_ID` are set **and** user consented to analytics cookies.
- Optional public stats link via `UMAMI_SHARE_URL` (footer + `/about`).

### Security

- **Cloudflare Turnstile** on contact form (`ContactMessagesController#create`).
- `TURNSTILE_SITE_KEY` / `TURNSTILE_SECRET_KEY` ENV override Rails credentials (useful for local dev and per-environment Dokploy keys).

### Dev tooling

- **mise** + Ruby 3.4.2 native setup (`mise.toml`, `script/setup-local-env.sh`, `script/install-native-deps.sh`).
- `.env.example` for native PostgreSQL dev; `vendor/bundle` removed from git tracking.
- Dependabot targets `Dev` branch.
- `AGENT.md` replaces `CLAUDE.md`; repo URLs updated to `Grenoble-roller/Grenoble-Roller-Website`.

### Roller stock reservations (v2.3 — includes uncommitted changes)

- `RollerStock.quantity` = **physical** inventory (admin-adjusted only).
- **Reservations** = active equipment requests on initiations where `stock_returned_at` is nil.
- Available size = physical − active reservations (all non-closed initiations).
- Button renamed **« Clôturer les prêts terminés »** (`POST /admin-panel/roller-stocks/return_all`); sets `stock_returned_at`, does not change physical stock.
- `ReturnRollerStockJob` **enabled** (daily ~2h via `config/recurring.yml`).

---

## Database migrations

Run automatically on deploy if `DB_BOOT_TASK=prepare` (Dokploy default).

| Migration | Purpose |
| --- | --- |
| `20260607021500_create_outbound_email_logs` | Persist outbound email job metadata for admin mail logs |
| `20260607025621_create_event_organizers` | Organizer entities (name, url, is_active) |
| `20260607025623_add_organizer_to_events` | Optional `events.organizer_id` FK |
| `20260607094750_add_goodies_distributed_to_memberships` | Boolean flag + index on memberships |
| `20260607120000_create_homepage_carousel_settings` | Singleton carousel autoplay settings |

**No migration** for roller stock reservations (logic-only change). Existing `stock_returned_at` on events (migration `20260101183839`) is used for closure.

---

## Environment variables (new/changed)

| Variable | Required | Notes |
| --- | --- | --- |
| `UMAMI_SCRIPT_URL` | No | Umami tracker URL; leave unset to disable |
| `UMAMI_WEBSITE_ID` | No | Website UUID; both Umami vars required for tracking |
| `UMAMI_DASHBOARD_URL` | No | Ops reference only |
| `UMAMI_SHARE_URL` | No | Public read-only dashboard link |
| `TURNSTILE_SITE_KEY` | No* | Overrides credentials; Cloudflare test keys for local dev |
| `TURNSTILE_SECRET_KEY` | No* | Server-side verification; see `.env.example` |

\* Turnstile still works from Rails credentials if ENV unset. Contact form + login use Turnstile when configured.

**Templates updated:** `.env.example`, `ops/dokploy/env/staging.env.example`, `ops/dokploy/env/production.env.example`.

**Staging recommendation:** set Umami vars to a **staging-specific** website ID if available; add staging hostname to Turnstile allowed domains or use ENV override with test keys.

---

## Post-deploy actions

### Roller stock (required after first deploy of v2.3)

1. Open **Admin Panel → Stock Rollers**.
2. **Reconcile physical quantities** with real inventory — legacy decrements on registration may have lowered `quantity` incorrectly.
3. Use **« Clôturer les prêts terminés »** for any finished initiations still holding reservations (or wait for `ReturnRollerStockJob`).
4. Verify registration forms show correct availability (physical − reservations).

### Optional

- Configure `UMAMI_*` on staging if analytics validation is needed (accept analytics cookies in browser).
- Confirm Turnstile on `/contact` with staging domain or test keys.
- Smoke-test carousel autoplay settings in admin.

---

## QA / test plan (staging)

### Events (public)

- [ ] Upcoming / ongoing / past badges and listings use end time, not start time only
- [ ] Multi-loop event: loop cards, distances, fullscreen map viewer
- [ ] Single-route event: map opens fullscreen viewer
- [ ] Past events readable on mobile
- [ ] Registration confirmation email shows correct participant name (adult + child)

### Admin panel

- [ ] Level 40 user: can open `/admin-panel/events` (read-only); cannot create/edit events
- [ ] Level 60 user: full event CRUD, event organizers CRUD
- [ ] Memberships: goodies flag, filter « Goodies en attente »
- [ ] Mail logs panel shows sent/queued emails after a test registration
- [ ] Carousel admin: toggle autoplay, change interval, verify homepage behavior

### Roller stock

- [ ] Register for initiation with equipment → physical stock unchanged; availability decreases
- [ ] Cancel registration → reservation released
- [ ] « Matériel rendu » on presences → `stock_returned_at` set; sizes available again
- [ ] « Clôturer les prêts terminés » batch-closes finished initiations

### Security & analytics

- [ ] Contact form blocked without Turnstile token; succeeds with valid token
- [ ] Umami script absent until analytics cookie accepted (if Umami configured)
- [ ] `/admin-panel` pages do not load Umami

### Automated (already green locally)

```bash
bundle exec rspec spec/models/roller_stock_spec.rb \
  spec/models/roller_stock_reservations_spec.rb \
  spec/jobs/return_roller_stock_job_spec.rb \
  spec/requests/admin_panel/roller_stocks_spec.rb
```

---

## Risks and rollback

| Risk | Mitigation / rollback |
| --- | --- |
| Roller stock quantities wrong after reservation model | Manual admin stock adjustment; no DB rollback needed |
| Umami / Turnstile misconfigured on staging | Unset ENV vars to disable; contact form falls back to credentials |
| New migrations fail | Fix forward; rollback = restore DB snapshot + redeploy previous staging SHA |
| Organizers FK on events | Nullable FK; safe to leave null |

**Rollback procedure:** redeploy previous staging commit; restore DB backup if migrations were applied. Roller stock v2.3 logic is backward-compatible with existing `stock_returned_at` column.

---

## Commit reference

```
c09b9f51 feat(memberships): track goodies distribution per membership
dc269014 fix(events): label loop distance fields with loop number
e95101a4 feat(homepage): configurable carousel autoplay and slide interval in admin
eab2f90e fix(mailers): show participant name in registration confirmation emails
4fea62fe feat(admin-panel): allow organizers and moderators to view events
7fab3c74 feat: event organizers, admin role guards, and membership edit fix
657c9b31 feat(events): fullscreen route viewer and overlay loop cards
68d66670 style(events): compact practical info grid on show pages
682fee29 fix(events): hide admin route names and improve past events on mobile
226e0071 fix(events): improve multi-loop cards layout on show page
5544c9bb style(ui): make quick action cards full-width and more compact
15897ba0 feat(security): add Turnstile to contact form and ENV override for local dev
cb24e996 fix(events): preload multi-loop routes on edit and show per-loop distances
bce4521d style(navbar): set glass background to 30% opacity
e63dd370 fix(admin): persist outbound email logs for mail-logs panel
79bc2955 chore(dev): standardize native dev setup with mise and dotenv
108db94a chore: stop tracking vendor/bundle in git
9cefd98d feat(events): treat past/upcoming by end time and show ongoing badge
cc39b1e0 chore(ci): target Dependabot PRs at Dev branch
fb80cc71 chore(dev): add mise Ruby 3.4.2 native setup for dev-workstation
2a113e94 feat(analytics): add Umami tracking gated by cookie consent
2e627ba8 docs(agent): replace CLAUDE.md with AGENT.md and update repo URLs
```

**Uncommitted (include in same deploy):** roller stock reservation model, admin button rename, specs — see `docs/06-events/roller-stock.md` v2.3.

---

## Related documentation

- [`docs/06-events/roller-stock.md`](../06-events/roller-stock.md)
- [`docs/08-security-privacy/umami-analytics.md`](../08-security-privacy/umami-analytics.md)
- [`docs/development/homepage-carousel.md`](../development/homepage-carousel.md)
- [`docs/04-rails/admin-panel/PERMISSIONS.md`](../04-rails/admin-panel/PERMISSIONS.md)
