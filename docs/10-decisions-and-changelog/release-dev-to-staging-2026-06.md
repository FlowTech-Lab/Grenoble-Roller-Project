---
title: "Release Dev → staging (June 2026)"
status: "active"
version: "2.0"
created: "2026-06-07"
updated: "2026-06-08"
tags: ["release", "staging", "changelog", "unified-checkout"]
---

# Release Dev → staging (June 2026)

**Target branch:** merge `Dev` → `staging` (PR)  
**Commit range:** `1b877166` … `db0f091b` (`origin/staging` … `Dev`)  
**Head on Dev:** `db0f091b` — `fix(checkout): membership cart UX and UnifiedCart autoload`

**Agent SSOT for checkout epic:** [`PLAN-unified-checkout-MASTER.md`](PLAN-unified-checkout-MASTER.md) (Waves 0–6 complete on `Dev`).

---

## Summary / scope

This release bundles:

1. **Unified account cart + checkout (major)** — feature-flagged via `UNIFIED_CART_ENABLED`; shop, memberships, and paid events share one cart and one HelloAsso checkout with **partial payment** (per-line checkboxes) and **optional donation** on every checkout. Initiations remain free; cash/check memberships bypass the cart.
2. **June 2026 public/admin batch** — events lifecycle/UI, admin panel (organizers, goodies, mail logs, carousel), Umami analytics, Turnstile on contact, roller stock reservations (v2.3), homepage hero image, dev tooling (mise, dotenv).

**Rollback (checkout):** set `UNIFIED_CART_ENABLED=false` and redeploy — see [Rollback](#rollback) and MASTER plan §H.

---

## Unified checkout (epic — merged on `Dev`)

| Area | Change |
| --- | --- |
| Account cart | `CartLine` model — product, membership, event line types per user |
| Checkout | `Checkout` + `CheckoutLine`; partial line selection; donation block |
| HelloAsso | Single unified payload via `CheckoutService` / `CheckoutFulfillmentService` |
| Paid events | Registration → cart hold (15 min) → pay; waitlist blocked when payment required |
| Memberships | Add-to-cart per adhesion (alert block on index); no grouped HelloAsso when flag on |
| Feature flag | `UnifiedCart.enabled?` — `ENV["UNIFIED_CART_ENABLED"]` (default `false`) |
| Admin | Read-only `/admin-panel/checkouts` audit |
| UX | Navbar cart badge, Mes sorties pending banner, mobile sticky cart/checkout footers |

**Canonical docs:**

- [`DR-001-unified-checkout-cart.md`](DR-001-unified-checkout-cart.md)
- [`PLAN-unified-checkout-MASTER.md`](PLAN-unified-checkout-MASTER.md) — QA §G, rollback §H
- [`docs/09-product/unified-cart-ux.md`](../09-product/unified-cart-ux.md)
- [`docs/09-product/flux-boutique-helloasso.md`](../09-product/flux-boutique-helloasso.md) (updated flow)

### Checkout migrations (new)

| Migration | Purpose |
| --- | --- |
| `20260607130200_add_payment_fields_to_events_and_attendances` | Paid event fields, attendance payment expiry |
| `20260607205837_create_cart_lines` | Account cart lines |
| `20260608120000_create_checkouts` | Checkout sessions + checkout lines |

Run via `DB_BOOT_TASK=prepare` on deploy (Dokploy default).

### Checkout environment variables

| Variable | Staging | Production (initial) |
| --- | --- | --- |
| `UNIFIED_CART_ENABLED` | **`true`** (QA) | **`false`** until human sign-off after staging QA |

Template: [`ops/dokploy/env/staging.env.example`](../../ops/dokploy/env/staging.env.example).

### Checkout — post-deploy (staging)

1. Set `UNIFIED_CART_ENABLED=true` in Dokploy staging env; redeploy.
2. Run migrations (automatic if `prepare`).
3. Execute **QA manual checklist** below (MASTER §G).
4. HelloAsso **sandbox** credentials must be active for E2E payment tests.
5. Do **not** enable flag in production until Florian signs off staging QA.

### Checkout — automated tests (green on `Dev`)

```bash
bundle exec rspec spec/models/cart_line_spec.rb spec/models/checkout_spec.rb \
  spec/services/cart_line_service_spec.rb spec/services/checkout_service_spec.rb \
  spec/services/checkout_fulfillment_service_spec.rb spec/requests/carts_spec.rb \
  spec/requests/checkouts_spec.rb spec/requests/memberships/payments_spec.rb \
  spec/lib/unified_cart_spec.rb
```

---

## Features by domain (June batch — prior commits)

### Events

| Change | Description |
| --- | --- |
| Past/upcoming lifecycle | Events classified as past when **end time** has passed; **ongoing** badge while in progress |
| Multi-loop UI | Overlay loop cards; per-loop distance labels; compact practical info grid |
| Route map viewer | Fullscreen pinch-zoom viewer on route/loop map images |
| Event organizers | `EventOrganizer` model; optional `organizer_id`; admin CRUD + public display |
| Registration emails | Participant name (parent or child) in confirmation emails |
| Paid registration | Wave 2: paid randos → cart + timer (with unified checkout epic) |

### Admin panel

| Change | Description |
| --- | --- |
| Events read access | Level ≥ 40 can **view** randos; write ≥ 60 |
| Event organizers | CRUD at `/admin-panel/event-organizers` |
| Goodies distribution | `memberships.goodies_distributed` flag |
| Mail logs | `OutboundEmailLog` + admin mail-logs panel |
| Homepage carousel | Autoplay on/off and interval (2–30 s) |
| Homepage hero | Admin-customizable hero banner image |
| Checkouts audit | `/admin-panel/checkouts` (read-only, unified checkout) |
| Role guards | Prevent admins from editing/deleting super admins |

### Memberships

- Goodies distributed flag.
- Unified cart: per-child « Ajouter au panier » in pending alert; compact mini-cards (WCAG `aria-label` on icon actions).

### Homepage

- Configurable carousel; customizable hero image.

### Analytics & security

- **Umami** — consent-gated tracking (`UMAMI_*`).
- **Turnstile** on contact form (`TURNSTILE_*` ENV or credentials).

### Dev tooling

- mise + Ruby 3.4.2, `.env.example`, Dependabot → `Dev`.
- `AGENT.md` agent guide (replaces `CLAUDE.md`).

### Roller stock reservations (v2.3)

- Physical stock vs active reservations model; « Clôturer les prêts terminés »; `ReturnRollerStockJob` enabled.

---

## Database migrations (full list for this release)

| Migration | Purpose |
| --- | --- |
| `20260607021500_create_outbound_email_logs` | Outbound email metadata for admin |
| `20260607025621_create_event_organizers` | Organizer entities |
| `20260607025623_add_organizer_to_events` | Optional `events.organizer_id` |
| `20260607094750_add_goodies_distributed_to_memberships` | Goodies flag |
| `20260607120000_create_homepage_carousel_settings` | Carousel autoplay settings |
| `20260607130200_add_payment_fields_to_events_and_attendances` | Paid events (checkout epic) |
| `20260607205837_create_cart_lines` | Account cart |
| `20260608120000_create_checkouts` | Unified checkout sessions |

**No migration** for roller stock reservations (logic-only). `stock_returned_at` on events unchanged.

---

## Environment variables (new/changed)

| Variable | Required | Notes |
| --- | --- | --- |
| `UNIFIED_CART_ENABLED` | No | `true` on staging for QA; **`false` in prod** until sign-off |
| `UMAMI_SCRIPT_URL` | No | Umami tracker URL |
| `UMAMI_WEBSITE_ID` | No | Both Umami vars required for tracking |
| `UMAMI_SHARE_URL` | No | Public stats link |
| `TURNSTILE_SITE_KEY` | No* | Contact form + login |
| `TURNSTILE_SECRET_KEY` | No* | Server-side verification |

\* Turnstile falls back to Rails credentials if ENV unset.

**Templates:** `.env.example`, `ops/dokploy/env/staging.env.example`, `ops/dokploy/env/production.env.example`.

---

## Post-deploy actions

### Unified checkout (staging — required)

1. Confirm `UNIFIED_CART_ENABLED=true` in Dokploy staging.
2. Complete QA checklist (section below).
3. Verify HelloAsso sandbox return URLs and webhook/polling still work for mixed carts.

### Roller stock (if not done on prior deploy)

1. Admin Panel → Stock Rollers — reconcile physical quantities.
2. « Clôturer les prêts terminés » for finished initiations.

### Optional

- Configure `UMAMI_*` on staging for analytics validation.
- Confirm Turnstile on `/contact`.

---

## QA / test plan (staging)

### Unified checkout (MASTER §G — human gate)

#### Core flows

- [ ] Add product → cart → checkout (all selected) → HelloAsso sandbox → order paid, stock correct
- [ ] Adult membership → cart → pay → active
- [ ] Two child memberships → two cart lines → one payment (both selected) → both active
- [ ] Paid rando: reserve → cart timer → pay → registered; timer expiry releases seat

#### Partial payment

- [ ] Cart with product + membership + event → uncheck membership → pay → membership remains in cart
- [ ] Select only event line → product and membership still in cart
- [ ] Zero lines or expired event line → rejected with flash

#### Donation

- [ ] Membership-only cart → donation 5 € → HelloAsso total correct
- [ ] Mixed cart + custom donation → metadata contains donation

#### Edge cases

- [ ] Initiation registration unchanged (free, member gate)
- [ ] Cash/check membership → no cart line
- [ ] Login merges legacy session cart (one-time)
- [ ] Unconfirmed email blocked at POST checkout
- [ ] Mobile cart + checkout layout OK
- [ ] Membership index: « Ajouter au panier » per child in pending alert; mini-cards without duplicate CTA

### Events (public)

- [ ] Upcoming / ongoing / past badges use end time
- [ ] Multi-loop event: loop cards, fullscreen map viewer
- [ ] Registration email shows correct participant name

### Admin panel

- [ ] Level 40: read-only events; level 60: full CRUD
- [ ] Mail logs after test registration
- [ ] `/admin-panel/checkouts` lists checkout attempts

### Roller stock

- [ ] Equipment reservation without physical decrement; closure releases sizes

### Security & analytics

- [ ] Contact form Turnstile; Umami consent-gated

---

## Risks and rollback

| Risk | Mitigation / rollback |
| --- | --- |
| Unified checkout regression | `UNIFIED_CART_ENABLED=false` → immediate legacy session cart + direct HelloAsso |
| Mid-flight HelloAsso checkouts | Pending `Checkout` rows remain; manual admin review |
| Orphan `CartLine` rows | Admin clear or optional rake (MASTER §H) |
| Roller stock quantities wrong | Manual admin adjustment |
| Migration failure | DB snapshot + redeploy previous staging SHA |

**Production cutover:** enable `UNIFIED_CART_ENABLED=true` only after staging QA sign-off (Florian).

---

## Commit reference (checkout epic — highlights)

```
db0f091b fix(checkout): membership cart UX and UnifiedCart autoload
f01e7b38 docs(checkout): mark Waves 5–6 DoD complete in MASTER plan
67dec0d2 chore(checkout): wave 6 cleanup and regression specs
4231ed18 feat(checkout): wave 5 UX polish and staging cutover prep
50d00d2d feat(checkout): wave 4 unified checkout partial payment and fulfillment
e7c7b75c feat(checkout): wave 3 memberships via account cart
85bb05e5 feat(checkout): wave 1 account cart and feature flag
0d0f9289 feat(checkout): wave 2 paid event registration via cart
18e0debe docs(checkout): add MASTER plan and unified cart UX spec
4ceced13 docs: add DR-001 unified checkout decision
```

Full Dev log since `origin/staging`: `git log origin/staging..Dev --oneline`

---

## Related documentation

- [`PLAN-unified-checkout-MASTER.md`](PLAN-unified-checkout-MASTER.md)
- [`DR-001-unified-checkout-cart.md`](DR-001-unified-checkout-cart.md)
- [`docs/09-product/unified-cart-ux.md`](../09-product/unified-cart-ux.md)
- [`docs/06-events/roller-stock.md`](../06-events/roller-stock.md)
- [`docs/08-security-privacy/umami-analytics.md`](../08-security-privacy/umami-analytics.md)
- [`AGENT.md`](../../AGENT.md) — agent workflow & staging release process

---

## Maintaining this file

When preparing the next **Dev → staging** PR:

1. Update **commit range** and **head SHA** at the top.
2. Add new features / migrations / ENV vars / QA items.
3. Add a line in [`CHANGELOG.md`](CHANGELOG.md) pointing here.
4. Cross-check [`AGENT.md`](../../AGENT.md) § Release to staging.
