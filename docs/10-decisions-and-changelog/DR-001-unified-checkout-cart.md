---
title: "DR-001: Unified checkout — cart vs direct HelloAsso for shop, memberships, and paid events"
status: "accepted"
version: "1.1"
created: "2026-06-08"
updated: "2026-06-08"
authors: ["Florian (Mestryx)", "Agent"]
tags: ["product", "decision", "checkout", "helloasso", "events", "memberships", "cart"]
---

# DR-001: Unified checkout — cart vs direct HelloAsso

## Status

**Accepted** (2026-06-08) — full epic on `feature/unified-checkout`.

**Implementation plans:**

- **Authoritative (agents):** [PLAN-unified-checkout-MASTER.md](PLAN-unified-checkout-MASTER.md)
- **Summary index:** [PLAN-unified-checkout-3-phases.md](PLAN-unified-checkout-3-phases.md)

## Context

### Current payment flows (as of 2026-06)

| Flow | Cart (`session[:cart]`) | Local record before pay | HelloAsso | Post-pay sync |
|------|-------------------------|------------------------|-----------|---------------|
| **Shop (products)** | Yes — `{ variant_id => qty }` | `Order` (`pending`) + `OrderItem`s, stock **reserved** | `create_checkout_intent` | Polling (`SyncHelloAssoPaymentsJob`) → `Order` paid |
| **Memberships (adult / teen / children)** | **No** | `Membership` (`pending`), multi-child = one grouped intent | `create_membership_checkout_intent` / `create_multiple_memberships_checkout_intent` | Same polling → `Membership` active |
| **Events (randos)** | **No** | Registration → `Attendance` (`registered` immediately) | **Not implemented** | N/A |

**Display vs payment:** `Event#price_cents` can be shown for information (e.g. external organizer) without collecting money. A separate admin flag **`payment_required`** (manual, default `false`) is required — not inferred from price.

**Paid event target behaviour (product):**

- Register → **seat reserved** (`Attendance` `pending`) → pay within **15 minutes** → confirmed registration.
- **No waitlist** when `payment_required` is true.
- HelloAsso `redirectUrl` TTL is **15 minutes** (official API), aligned with reservation window.

**User question:** Shop products already go through the **cart**; should **memberships (parent + children)** and **paid event registrations** use the same cart to harmonize UX and a single checkout?

## Decision (accepted 2026-06-08)

**All online payments** (shop, memberships, paid randos) flow through an **account-based cart** (`CartLine`) → **unified checkout** → **one HelloAsso payment** per checkout session.

- **`payment_required`** on randos (`Event`, not `Event::Initiation`): manual flag, default `false`.
- **Partial payment:** checkout accepts a **subset** of cart lines (per-line checkboxes); unselected lines remain in cart.
- **Donation:** optional free donation shown on **every** checkout (always offered, including non-shop carts); added to HelloAsso total.
- **Initiations:** never paid — member-only registration unchanged; explicitly out of scope for cart/checkout.
- **Session cart** (`session[:cart]`) deprecated; migrate to DB per user.
- **UX:** full cart/checkout redesign — see [unified-cart-ux.md](../09-product/unified-cart-ux.md).
- **Rollout:** feature flag `UNIFIED_CART_ENABLED`; Waves 0–6 in [PLAN-unified-checkout-MASTER.md](PLAN-unified-checkout-MASTER.md).

### Supersedes earlier “Phase 1 silos” proposal

Paid events no longer use a standalone HelloAsso redirect outside the cart; they add a `CartLine` with 15-minute expiry, same as the unified model.

## Historical context (pre-decision analysis)

### Why products use the cart today

- `Order` / `OrderItem` / `Inventory` reservation map cleanly to **product variants**.
- Cart is session-based and cleared after `POST /orders`.

### Why memberships bypass the cart

- Business rules: season, child count, trial vs paid, grouped multi-child payment, optional t-shirt embedded in membership price.
- Checkout intents already support **multiple memberships in one payment** without a cart (`create_multiple_memberships_checkout_intent`).
- Forcing memberships into product `OrderItem` would require nullable FKs or parallel tables and duplicate HelloAsso reconciliation.

### Why not extend `session[:cart]` for everything in v1

| Risk | Detail |
|------|--------|
| Mixed lifecycles | Order cancel vs membership pending vs event 15min hold |
| Stock vs seats | `Inventory` vs `max_participants` / initiation caps |
| Reconciliation | One `Payment` must activate orders, memberships, **and** attendances |
| UX | Event-only users never need “panier boutique” metaphor |

### When a true unified cart *is* worth it (Phase 2)

- User story: “Buy hoodie + renew membership + register for paid rando in **one payment**.”
- HelloAsso supports **one** checkout-intent with summed `totalAmount` and rich `metadata` (already used for shop donations).

Implementation sketch: `CheckoutLine` STI or typed rows (`product_variant_id`, `membership_id`, `attendance_id`) → single `Payment` → fan-out on success.

## Alternatives considered

### A — Extend `session[:cart]` only (products + events + memberships)

- **Pros:** One UI (`/cart`), familiar e-commerce pattern.
- **Cons:** High coupling; membership/event logic in `CartsController`; hardest refunds and partial failures; **not recommended for v1**.

### B — Keep three silos forever (shop cart, membership redirect, event redirect)

- **Pros:** Minimal change for paid events; low regression risk on shop/memberships.
- **Cons:** Three UX paths; no combined payment; user confusion long term.

### C — Phased unified checkout (recommended)

- **Pros:** Ship paid events quickly; clear path to harmonization; reuses HelloAsso patterns.
- **Cons:** Two checkout UIs until Phase 2; requires second migration for line items.

### D — HelloAsso only, no local pending records

- **Pros:** Less code.
- **Cons:** No seat reservation; incompatible with 15min hold and capacity — **rejected**.

## Consequences

### Easier

- Paid events with explicit `payment_required` decoupled from displayed price.
- Future single-payment basket via shared checkout service.
- Consistent HelloAsso polling extension point.

### Harder / risks

- Capacity counting must include **payment-pending** attendances (today `full?` excludes `pending` except waitlist flow).
- Status after pay: align on `paid` vs `registered` (see open questions).
- Polling latency (5 min) vs 15min expiry — expiry job must not rely on poll alone for releasing seats.

## Resolved product questions (2026-06-08)

| Question | Resolution |
|----------|------------|
| Post-payment attendance status | `registered` + `payment_id` (parity with free events) |
| Combined payment (shop + membership + event) | Yes — via cart; user may pay all or a subset per checkout |
| Donation on non-shop checkout | **Always offered** on checkout |
| Partial cart payment | **Yes** — per-line selection at checkout |
| Initiations paid online | **No** — out of scope |
| Webhooks | Deferred; polling only (v1) |

## Implementation branch

- **Base:** `Dev` (after this DR is merged/pushed).
- **Branch:** `feature/unified-checkout` — Phase 1 paid events first; Phase 2 design doc follow-up.

## References

- [`PLAN-unified-checkout-MASTER.md`](PLAN-unified-checkout-MASTER.md) — agent implementation plan
- [`docs/09-product/unified-cart-ux.md`](../09-product/unified-cart-ux.md)
- [`docs/09-product/flux-boutique-helloasso.md`](../09-product/flux-boutique-helloasso.md)
- [`docs/06-events/logique-essai-gratuit.md`](../06-events/logique-essai-gratuit.md) — attendance status transitions
- [`docs/09-product/user-journeys-analysis.md`](../09-product/user-journeys-analysis.md) — “Inscription avec paiement”
- HelloAsso: [Checkout intents](https://dev.helloasso.com/docs/api-overview), [Webhooks](https://dev.helloasso.com/docs/notifications-webhook)
- Prior agent research: cart vs direct HelloAsso (2026-06)

---

**Related:** Release notes [`release-dev-to-staging-2026-06.md`](release-dev-to-staging-2026-06.md)
