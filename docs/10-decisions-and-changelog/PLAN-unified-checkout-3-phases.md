---
title: "Implementation plan — Unified account cart & checkout (3 phases, AI-driven)"
status: "active"
version: "1.2"
created: "2026-06-08"
updated: "2026-06-08"
branch: "feature/unified-checkout"
tags: ["checkout", "cart", "helloasso", "events", "memberships", "ux", "agents"]
---

# Implementation plan — Unified account cart & checkout

> **Agent note:** This document is a **summary index only**. Do **not** implement from this file alone.
>
> **Single source of truth (SSOT):** **[PLAN-unified-checkout-MASTER.md](PLAN-unified-checkout-MASTER.md)** — migrations, RSpec appendix J, file checklist, partial payment, donation, rollback.

**Decision:** All **monetized** flows (shop, memberships, paid event registrations) go through an **account-scoped cart** → **single checkout** → **one HelloAsso payment** per checkout session.

**Locked 2026-06-08:** Partial payment (subset of cart lines) · Donation on every checkout · Initiations never paid.

**Not in cart:** free event registration, waitlist (disabled when `payment_required`), cash/check membership path (admin/b offline — keep separate), **all initiations** (member gate only).

**Execution:** AI agents on branch `feature/unified-checkout`; human review between waves; RSpec green each wave.

**Estimate:** 4–6 agent iteration cycles (~12–20 human review days with buffer).

---

## Product defaults (locked for implementation)

| Topic | Choice | Rationale |
|-------|--------|-----------|
| `payment_required` | Manual admin flag, default `false` | Price display without payment (external organizer) |
| Event seat hold | 15 min (`payment_expires_at` on line + attendance) | Matches HelloAsso redirect TTL |
| Post-payment attendance | `registered` + `payment_id` | Same UX as free events; payment traceable |
| Waitlist | Hidden/blocked when `payment_required` | PO rule |
| Cart storage | DB per `user_id`, not `session[:cart]` | Multi-device, aligns with pending records |
| Guest shop | Require login to add payable lines | Simplifies cart; show login CTA |
| Combined payment | One HelloAsso intent per checkout | Sum **selected** lines + optional donation |
| Partial payment | Per-line checkboxes on `/checkout` | Unselected `CartLine` rows remain in cart |
| Donation | Always on checkout | Including membership/event-only carts |
| Initiations | Never paid | `Event::Initiation` excluded from `payment_required` |
| Polling | Extend existing job first; webhooks optional later | Lower scope |

---

## Architecture target

```
User action (product / membership form / event register)
        ↓
CartLineService.add!(user, line_type, reference, …)
        ↓
/cart  (sections: Products | Memberships | Events)
        ↓
GET /checkout  →  select lines (checkboxes) + optional donation
        ↓
POST /checkout  →  Checkout (pending) + snapshot of selected lines
        ↓
HelloassoService.create_unified_checkout_intent(checkout)
        ↓
Payment succeeded  →  CheckoutFulfillmentService
        ├─ products: Order + inventory move
        ├─ memberships: status active
        └─ events: Attendance registered
        (unselected cart lines unchanged)
```

### New / changed models

| Model | Role |
|-------|------|
| `CartLine` | `user_id`, `line_type` enum, polymorphic `reference`, `amount_cents`, `label`, `expires_at`, `metadata` jsonb |
| `Checkout` | `user_id`, `status`, `total_cents`, `payment_id`, `metadata` |
| `CheckoutLine` | Snapshot at pay time (immutable audit) |
| `Event` | + `payment_required` boolean |
| `Attendance` | + `payment_expires_at` (nullable); payment-pending uses `status: pending` |

Deprecate: `session[:cart]` after migration shim.

---

## UI / UX — yes, full review required

Current UI assumes **shop-only cart** and **direct Pay on membership/event**. Unified cart requires a **coherent commerce shell**.

### UX principles

1. **One mental model:** “Mon panier” = everything I will pay for.
2. **Clear line types:** icon + badge (Boutique / Adhésion / Événement).
3. **Urgency for events:** countdown on lines with `expires_at` (15 min).
4. **No dead ends:** after “S’inscrire” on paid event → cart with message, not silent redirect to HelloAsso.
5. **Mobile-first:** cart and checkout must match existing liquid/card patterns (`_style.scss`).

### Screens to (re)design

| Screen | Changes |
|--------|---------|
| **Navbar** | Cart badge = DB line count; label “Panier” |
| **`/cart`** | Three sections; empty states per type; expiry timers; remove line |
| **`/checkout`** (replaces `/orders/new` for unified flow) | Summary of lines with **checkboxes**; **donation always shown**; T&C; **Payer la sélection (X €) avec HelloAsso** |
| **`/orders/*` return** | Generic checkout return + poll status (membership + shop + events) |
| **Product show** | “Ajouter au panier” unchanged; toast “Voir le panier” |
| **Membership forms** | Replace immediate HelloAsso with “Ajouter au panier” when online pay; keep cash/check path |
| **Membership show** | Remove standalone “Payer HelloAsso” when cart is canonical; link to cart if pending line exists |
| **Event show** | If `payment_required`: CTA “Réserver ma place” → cart; show price + hold notice; hide waitlist |
| **Event show** | If free: unchanged registration |
| **Mes sorties / flash** | Banner if unpaid cart lines expiring |
| **Admin event form** | Checkbox `payment_required` + help text vs `price_cents` |

### UX deliverable (Wave 0)

Agent produces **`docs/09-product/unified-cart-ux.md`** with wireframe descriptions (no Figma required): copy FR, states, error messages, edge cases.

---

## Phase map (implement as one epic, 6 waves)

### Wave 0 — Foundation & UX spec (no production behaviour change)

**Agent tasks**

- [ ] Update DR-001 status → `accepted`; link this plan.
- [ ] Write `docs/09-product/unified-cart-ux.md` (screens, copy, flows).
- [ ] Add feature flag `UNIFIED_CART_ENABLED` (env, default `false`) for safe rollout.
- [ ] Spike: confirm HelloAsso single intent with mixed metadata (sandbox curl or existing service test).

**DoD:** Docs merged; flag in `config/application.rb` or initializer; no user-facing change.

---

### Wave 1 — Account cart + shop migration (Phase 2 foundation)

**Agent tasks**

- [ ] Migration `cart_lines` (+ indexes on `user_id`, `line_type`, `expires_at`).
- [ ] Model `CartLine` + enum `line_type: product_variant, membership, event_registration`.
- [ ] `CartLineService` (add, remove, clear, list, expire_stale!).
- [ ] Job `ExpireCartLinesJob` (every 1–2 min): event lines past `expires_at` → release attendance + delete line.
- [ ] Refactor `CartsController` to use `CartLineService` (keep session shim: on login, merge session → DB once, then clear session).
- [ ] Update `cart/show.html.erb` — product section only (parity with today).
- [ ] Specs: model, service, request cart CRUD.

**DoD:** Shop works via DB cart behind flag; session cart migrated on login; shop regression specs green.

---

### Wave 2 — Paid events (Phase 1 product goal)

**Agent tasks**

- [ ] Migration `events.payment_required`, `attendances.payment_expires_at`.
- [ ] `Event#requires_online_payment?` → `payment_required?`.
- [ ] Capacity: `occupied_spots` includes payment-pending attendances for paid events.
- [ ] `Events::AttendancesController#create`: if `requires_online_payment?` → create `Attendance` pending + `CartLine` event line (`expires_at` 15.minutes.from_now); else unchanged.
- [ ] Block waitlist UI + controller when `payment_required`.
- [ ] Cart UI: event section + countdown partial `_cart_line_event.html.erb`.
- [ ] Event show: new CTA copy + no waitlist.
- [ ] Admin event form: checkbox.
- [ ] Specs: registration, expiry, capacity, waitlist blocked.

**DoD:** Paid event → cart line → (checkout in Wave 4); free events unchanged.

---

### Wave 3 — Memberships into cart (Phase 3 harmonization)

**Agent tasks**

- [ ] After membership `create` (online pay path): add `CartLine` membership instead of `Memberships::PaymentsController` redirect.
- [ ] Multi-child: one line per membership OR one grouped line (prefer **one line per child** for clarity; checkout sums).
- [ ] Guard: health questionnaire complete before add-to-cart or at checkout validation.
- [ ] Remove / hide direct “Payer HelloAsso” buttons when `UNIFIED_CART_ENABLED` (feature flag).
- [ ] Cart UI: membership section with season, child name, amount.
- [ ] Keep **cash/check** path untouched (no cart line).
- [ ] Specs: adult, teen, multi-child cart lines.

**DoD:** New memberships land in cart; old payment controller deprecated behind flag.

---

### Wave 4 — Unified checkout & HelloAsso (all payments)

**Agent tasks**

- [ ] Models `Checkout`, `CheckoutLine`.
- [ ] `CheckoutService.build_from_cart(user)` — validates stock, seats, membership rules, non-expired lines.
- [ ] `HelloassoService.create_unified_checkout_intent(checkout)` — replace separate product/membership/event intent builders for cart flow (keep old methods until flag removal).
- [ ] Extend `fetch_and_update_payment` → `CheckoutFulfillmentService` fan-out:
  - Products → `Order` + items + inventory (reuse Order logic)
  - Memberships → `active`
  - Events → attendance `registered`, clear `payment_expires_at`
- [ ] Routes: `POST /checkout`, `GET /checkout/return`, deprecate direct `POST /orders` for cart checkout (redirect).
- [ ] Checkout view (unified) replacing order-new for this path.
- [ ] Specs: integration with HelloAsso stubbed; fulfillment unit tests.

**DoD:** Single “Payer avec HelloAsso” pays entire cart; all line types fulfilled.

---

### Wave 5 — UX polish & cutover

**Agent tasks**

- [ ] Navbar badge, flash messages, empty cart, error states (per UX doc).
- [ ] `Mes sorties`: show “En attente de paiement” for pending attendances linked to cart.
- [ ] Emails: adjust triggers (confirm only after fulfillment, not on pending add).
- [ ] Remove session cart code paths when flag on.
- [ ] Admin docs + update `flux-boutique-helloasso.md`.
- [ ] Enable `UNIFIED_CART_ENABLED` in staging `.env.example`.

**DoD:** Staging QA checklist passed (see below).

---

### Wave 6 — Cleanup & release

**Agent tasks**

- [ ] Delete deprecated redirect flows (or keep 301 to cart).
- [ ] Remove feature flag default false → true in staging, then prod after human sign-off.
- [ ] Update `release-dev-to-staging-*.md` / CHANGELOG.
- [ ] Full RSpec + smoke manual QA on staging.

---

## AI agent orchestration

| Wave | Suggested agent | Parallel? |
|------|-----------------|-----------|
| 0 | docs + spike agent | — |
| 1 | backend agent | — |
| 2 | backend + frontend agent | After 1 |
| 3 | backend + frontend | After 4 design stable (can start UI mock after 1) |
| 4 | backend (critical) | Sequential after 2+3 |
| 5 | frontend + mailers | After 4 |
| 6 | QA agent + docs | After 5 |

**Rules for agents**

1. One wave per PR or one PR per wave (prefer **one PR per wave** for review).
2. Each PR: migrations, code, specs, update UX doc if behaviour changes.
3. Never commit secrets; HelloAsso sandbox only in tests.
4. Human validates UX copy (FR) on Wave 5 before prod.
5. Parent agent runs `bundle exec rspec` scope listed in each wave DoD.

---

## QA checklist (staging)

- [ ] Add product → cart → checkout → HelloAsso sandbox → order paid, stock correct
- [ ] Create adult membership → cart → pay → active
- [ ] Create 2 children → cart shows 2 lines → one payment → both active
- [ ] Paid event: register → cart with timer → pay → registered; seat released if timer expires
- [ ] Event `price_cents > 0` but `payment_required false` → free registration
- [ ] Waitlist unavailable on paid event
- [ ] Cash/check membership still works without cart
- [ ] Login merges old session cart (one-time migration test)
- [ ] Mobile cart + checkout layout OK

---

## Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Large blast radius | Feature flag; wave-by-wave PRs |
| HelloAsso metadata size | Store `checkout_id`; line IDs in metadata, not full blobs |
| 15 min expiry vs 5 min poll | Expiry job releases seats; show “processing” on return URL |
| Email double-send | Defer confirmation mail to fulfillment only |
| Initiation paid events | Out of scope unless PO extends; plan is `Event` base, not `Initiation` STI in v1 |

---

## Out of scope (v1 epic)

- **Paid initiation registration** — initiations stay free; membership gate in `Attendance#can_register_to_initiation` (see [`docs/06-events/logique-essai-gratuit.md`](../06-events/logique-essai-gratuit.md))
- HelloAsso webhooks (polling only)
- Refunds automation (manual admin, as today)
- Guest checkout without account

---

## References

- **[PLAN-unified-checkout-MASTER.md](PLAN-unified-checkout-MASTER.md)** — authoritative agent plan (waves, RSpec, files)
- [DR-001-unified-checkout-cart.md](DR-001-unified-checkout-cart.md)
- [unified-cart-ux.md](../09-product/unified-cart-ux.md)
- [flux-boutique-helloasso.md](../09-product/flux-boutique-helloasso.md)
- [user-journeys-analysis.md](../09-product/user-journeys-analysis.md)
