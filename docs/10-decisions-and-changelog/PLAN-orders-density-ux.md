---
title: "PLAN — Orders density UX (SaaS billing list)"
status: "ready"
version: "1.1"
created: "2026-08-03"
updated: "2026-08-03"
tags: ["ux", "orders", "design-system", "saas", "plan", "a11y"]
related:
  - PLAN-ux-pages-verification.md
  - release-ux-pages-verification-2026-08.md
---

# PLAN — Orders density UX

**Branch:** `ux/orders-density-and-cards`  
**Page:** `/orders` (`app/views/orders/`)  
**Appetite:** one continuous pass (~1–1.5 human days), **not** split A/B/C — same PR, reviewable commits if useful but one delivery.

Why not three tranches? Slices were for optional revert granularity. Florian prefers **one coherent redesign**; we implement the full density pass together, still using **design-system tokens / reusable partials** (no one-off inline styles).

---

## Design read

Liste d’historique commandes **dense + trust-first** (asso boutique), alignée memberships / liquid glass. Inspiration Stripe Billing / Linear / Vercel: **une ligne = une commande**, chip statut, action primaire inline.

---

## Already done (this branch, card-surface pass)

| Item | Change |
|------|--------|
| Body dark `--bs-body-bg` | Fixed `:root` override that broke theme (light body + dark text) |
| `--liquid-glass-bg` | Theme-agnostic `#969ca114`; reduced-transparency keeps fill, drops blur only (never `body-bg` on cards) |
| Order row | Dense single-line layout: meta · chip · price · `Payer` + compact `Voir` (no full-width Détails) |
| Theme script | Blocking apply in `<head>` |
| Stimulus | `#escapeHandler` declared on `route_image_viewer` |
| Soft status tokens | `--status-*-fg/bg/border` light+dark; order chips + `.status-badge` WCAG AA (≥4.5:1). Pending chip no longer uses `--bs-warning` as text (~1.6 fail) |

---

## A11y — soft status chips (wave 1, done)

**Anti-pattern:** pastel fill + Bootstrap semantic as **text** (`--bs-warning` `#ffc107` → ~1.4–1.6:1).

**Fix:** use `--status-pending-fg` (`#7e4900` light / `#ffd27a` dark) on solid soft fills. Same family for prep / sent / cancelled / active / expired.

Wave 1 numeric pass: order chips, `.status-badge`, `badge-liquid-*`, hero-orders/memberships count badges — all ≥4.5:1.

### Wave 2 checklist (deferred)

- [ ] `text-muted` / `.text-muted` on glass `#969ca114` (light + dark)
- [ ] `btn-outline-*` on dark glass cards (Voir, secondary CTAs)
- [ ] Soft alerts (`.alert-liquid-*`) text vs tinted bg
- [ ] Remaining hardcodes `#ffc107` / `#FF9800` as **text** in `_style.scss` (borders/accents OK if not body text)
- [ ] Optional later: Pa11y/Axe page smoke (orders, memberships, shop)

---

## Remaining implementation (single pass)

### 1. Dense order row (core)

- Replace tall card body with **row anatomy**:
  `#id · date · product truncate · status chip · price · [Payer|Voir]`
- Height target ~48–56px desktop; wrap 2 lines mobile.
- Status: Bootstrap Icons + FR label (already started; finish as **chip** / badge, zero emoji).
- Primary action **inline** `btn-sm` — **no** `flex-grow-1` full-width « Détails ».
- Optional: whole-row link to `order_path` with focus-visible; keep `button_to` Payer from double-navigation.

**Files:** `_order_card_compact.html.erb` → prefer rename `_order_row.html.erb`; SCSS `.order-row` next to `.order-card`.

### 2. Index layout hygiene

- Hero: keep `hero-orders`; light badges; CTA = **Payer** if any pending else **Boutique**.
- Sidebar sticky (memberships pattern); **dedupe** quick actions already in hero.
- Section headers compact (pending / shipped / cancelled collapse).
- Preload `order_items: { variant: :product }` in controller if N+1.

**Files:** `orders/index.html.erb`, `_sidebar.html.erb`, `orders_controller.rb`, SCSS `.orders-sidebar`.

### 3. Design-system consistency

- Prefer tokens (`--liquid-glass-*`, `--status-*`, `--card-border-color`) over hex / emoji.
- Reuse `.btn` icon centering already global.
- No new Tailwind; stay Bootstrap + liquid layer.
- Update UI-Kit sample if order component exists.

### 4. Specs + docs

- Request smoke: `/orders` renders status chips / no emoji / liquid class.
- CHANGELOG + short note under Unreleased / next patch when merging.
- Tick PLAN-ux-pages-verification Wave 2.1 → densify or add Wave 2.1b.

---

## Out of scope

- `orders/show` full redesign (verify-only unless chips must match).
- Admin orders, PDF invoices, HelloAsso flow changes.
- Rewrite to another CSS framework.

## Risks

- Row click vs Pay button (Turbo / form nesting).
- Dark-mode chip contrast on glass — mitigated by `--status-*` tokens.
- Mobile wrap of price + CTA.

## Done when

- [ ] `/orders` reads as dense list, not stacked empty cards
- [ ] Cards clearly detached (glass tokens) site-wide where `.card` / `.card-liquid` used
- [ ] No hardcoded card backgrounds / border-left hex in orders views
- [x] Soft status chips AA light+dark (pending / prep / sent / cancelled)
- [ ] Specs green; hard-refresh local `:3001/orders` + memberships + shop smoke

**Estimate:** 1–1.5 days continuous (includes polish + specs).
