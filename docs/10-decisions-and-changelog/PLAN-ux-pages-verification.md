# PLAN — Site-wide UX page verification (priority-gated)

**Date:** 2026-08-03  
**Status:** active (tracking)  
**Branch:** `ux/pages-verification` (merge → `Dev` when a wave is ready; do not land unfinished waves on `Dev`)  
**Owner:** Florian + agents  
**Related:** memberships UX polish (shipped on Dev) · [`unified-cart-ux.md`](../09-product/unified-cart-ux.md) · [`flux-boutique-helloasso.md`](../09-product/flux-boutique-helloasso.md) · [`ux-improvements-backlog.md`](../09-product/ux-improvements-backlog.md) (historical) · Graphify `graphify-out/` (refresh with `graphify update .` before each wave)

---

## Why this exists

We polished the **memberships** member page. That pattern must **not** be copied blindly onto every route.

This file is the **step-by-step control plane** for:

1. **Verify** each surface (checklist + skills).
2. **Decide** severity (`fix` / `tweak` / `ok` / `defer`).
3. **Change only when justified** — no big refactor by default (YAGNI / KISS).

---

## Principles (locked)

| Rule | Meaning |
|------|---------|
| Verify before change | A page can stay as-is if it passes the checklist |
| Importance gates work | P0 before P1 before P2; skip P3 unless a real bug |
| Small commits | One surface (or one concern) per commit when we change code |
| Preserve liquid/Bootstrap | Match existing design language; no landing redesign on dashboards |
| Graphify is inventory, not UX judge | Use `graphify update .` + targeted `rg` on views; Graphify queries lean docs-heavy |
| French UI copy / English commits & this plan | Project language policy |

**Anti-goals:** site-wide visual redesign, admin pixel-perfect pass, rewriting public marketing pages “for consistency”.

---

## Skills by page kind

| Page kind | Primary skills | Secondary |
|-----------|----------------|-----------|
| Member dashboard (memberships, orders) | trust-first density, CTA hierarchy | `accessibility` light pass |
| Commerce (shop, cart, checkout) | conversion clarity, trust banners, empty states | `accessibility`, cart docs |
| Content / marketing (home, about) | `design-taste-frontend` only if redesigning | preserve brand; do **not** apply dashboard rules |
| Forms (membership forms, contact, auth) | stepper clarity, error visibility | a11y focus / labels |
| Event discovery & detail | content hierarchy, mobile media | existing event docs |
| Legal / FAQ | readability, no clutter | a11y |
| Admin panel | defer unless ops pain | separate later wave |

Agent note: announce which skill set applies at the start of each wave; do not force landing-page taste onto shop or admin.

---

## Verification checklist (every page)

Run in order. Mark the tracker row when done.

### A — Layout & hierarchy
- [ ] Primary job of the page is obvious in the first viewport
- [ ] No large empty region that should hold meta/CTA (or intentional whitespace)
- [ ] Container width consistent with siblings (`container` vs accidental `container-fluid`)
- [ ] Mobile (~375px): no overflow, CTAs reachable

### B — CTA hygiene
- [ ] One primary action for the main job (or intentional dual CTAs with clear roles)
- [ ] No duplicate primary buttons for the same job (hero + body + sidebar)
- [ ] Empty state: one clear path; optional secondary links OK

### C — Copy & a11y
- [ ] No obvious FR typos; status text sentence-case where we control it
- [ ] Icons preferred over emoji-only status
- [ ] Interactive controls have accessible names / visible focus

### D — Trust & product truth
- [ ] Temporary banners (HelloAsso migration, etc.) still accurate — remove or reword if obsolete
- [ ] Prices / stock / dates match backend (no misleading UI)

### E — Perf / hygiene (light)
- [ ] No obvious N+1 or `Model.count` in the ERB that belongs in the controller
- [ ] No dead CSS classes introduced; rebuild CSS only if SCSS changed

**Outcome codes:** `ok` · `tweak` (small UI) · `fix` (bug / misleading) · `defer` (known, out of appetite)

---

## Priority map

| Priority | Surfaces | Appetite | Default action |
|----------|----------|----------|----------------|
| **P0** | Shop index `/shop`, product show, cart `/cart`, checkout | High — conversion | Verify → change only if checklist fails |
| **P1** | Orders index, memberships show (detail), attendances | Medium — member trust | Same |
| **P2** | Events index/show, initiations, home, about, contact | Medium/low | Verify; marketing pages: minimal changes |
| **P3** | Legal/FAQ, auth/Devise, membership multi-step forms | Low unless broken | Spot-check |
| **P4** | `admin-panel/*` | Ops-driven | Out of this plan unless blocker |

Memberships **index** = reference completed (2026-08-03 Dev). Re-verify after merge to staging only.

---

## Tracker (update status in place)

Legend: `todo` · `verify` · `done-ok` · `done-tweak` · `done-fix` · `skip`

### Wave 0 — Tooling (once)

| Step | Task | Status | Notes |
|------|------|--------|-------|
| 0.1 | `graphify update .` at repo root | done | 2026-08-03 → commit `d8c45305` |
| 0.2 | Confirm this PLAN linked from `docs/09-product/README.md` | done | 2026-08-03 |
| 0.3 | Optional: Hindsight retain wave start/end | done | Wave 1–2 progress 2026-08-03 |

### Wave 1 — P0 Commerce

| Step | Route / view | Status | Likely findings (pre-check) | Decision |
|------|--------------|--------|-----------------------------|----------|
| 1.1 | `GET /shop` → [`app/views/products/index.html.erb`](../../app/views/products/index.html.erb) | done-fix | HelloAsso migration banner; title-only header; `Product.count` in view | Count → controller; banner demoted; header + cart link (separate commits) |
| 1.2 | `GET /products/:id` → [`app/views/products/show.html.erb`](../../app/views/products/show.html.erb) | done-tweak | Same banner | Banner demoted only |
| 1.3 | `GET /cart` → [`app/views/carts/show.html.erb`](../../app/views/carts/show.html.erb) | done-ok | Already stronger empty/sticky CTA | No code change |
| 1.4 | Checkout `new` | done-tweak | `container-fluid` vs shop/cart | Switched to `container` |
| 1.4b | Checkout `show` / status | defer | Polling/status UX | Leave unless bug reports |
| 1.5 | Commits on `ux/pages-verification` | done | Independent commits per concern | |

**Wave 1 exit:** P0 shop/cart/checkout-new filled; smoke on staging after PR.

### Wave 2 — P1 Member shell

| Step | Route / view | Status | Notes | Decision |
|------|--------------|--------|-------|----------|
| 2.1 | Orders [`app/views/orders/index.html.erb`](../../app/views/orders/index.html.erb) (`hero-orders`) | done-tweak | Hero balance + empty CTA dedupe + sidebar hide when empty | |
| 2.2 | Orders show | defer | Verify later if needed | |
| 2.3 | Memberships show | defer | Index already polished on this branch | |
| 2.4 | Attendances index | defer | | |

### Wave 3 — P2 Public content

| Step | Route / view | Status | Notes | Decision |
|------|--------------|--------|-------|----------|
| 3.1 | Home `pages#index` | todo | Different brief — do not force dashboard CTAs | |
| 3.2 | About | todo | | |
| 3.3 | Events index / show | todo | Mobile media already improved recently — verify only | |
| 3.4 | Initiations index / show | todo | | |
| 3.5 | Contact | todo | | |

### Wave 4 — P3 Spot-check

| Step | Surface | Status | Decision |
|------|---------|--------|----------|
| 4.1 | Legal pages (CGU/CGV/privacy/mentions/FAQ) | todo | |
| 4.2 | Auth (sign in / sign up / welcome) | todo | |
| 4.3 | Membership forms (adult/child/teen steppers) | todo | Forms ≠ dashboard polish |

### Wave 5 — Closeout

| Step | Task | Status |
|------|------|--------|
| 5.1 | Summarize outcomes in CHANGELOG under Unreleased (if user-facing) | todo |
| 5.2 | `graphify update .` after code waves | todo |
| 5.3 | Optional PR Dev → staging with short Discord note | todo |
| 5.4 | Mark this PLAN status `done` or `parked` | todo |

---

## Shop wave — decision defaults (when verifying)

Use these defaults so agents do not invent scope:

| Topic | Default |
|-------|---------|
| HelloAsso banner | If native shop is the source of truth for saleable SKUs: **remove or demote** banner; if HelloAsso still required for some SKUs: **reword** (“Aussi disponible sur HelloAsso”) not “migration en cours” |
| Header | Light balance only: title + link to cart (and optional season/context) — **not** a full memberships-style hero unless verification says empty/confused |
| `Product.count` in ERB | Move count to controller/instance var if still present |
| Card grid / liquid | Keep; densify only if meta is noisy |
| Refactor Stimulus product-show | **Out of scope** unless broken |

---

## How to run one page (agent recipe)

1. Refresh Graphify if HEAD moved: `graphify update .`
2. Open the view file(s) + related SCSS classes.
3. Apply the checklist A–E; fill the tracker row (`ok` / `tweak` / `fix` / `defer`).
4. If `ok` or `defer`: **stop** (no code).
5. If `tweak` / `fix`: smallest change; conventional commit; rebuild CSS if needed.
6. Smoke the happy path on staging or local Docker.
7. Retain a one-line Hindsight note for non-trivial decisions.

Estimate per page: **15–45 min verify**; **0–0.5 day** if fixes. Full plan if most pages are `ok`: **~2–4 human days** across waves with buffer — uncertainty high until Wave 1 finishes.

---

## Out of scope

- Admin panel redesign
- Changing HelloAsso / checkout business rules
- i18n layer
- Forcing memberships hero A+B onto shop/home
- npm audit / Docker noise (handled elsewhere)

---

## Changelog of this plan

| Date | Change |
|------|--------|
| 2026-08-03 | Initial PLAN after memberships UX polish + Graphify refresh |
| 2026-08-03 | Wave 1 shop/checkout + Wave 2.1 orders on `ux/pages-verification` (atomic commits) |
| 2026-08-03 | Shop catalog cards: fixed 1:1 thumbnails + denser shelf layout (Amazon-style compare) |
