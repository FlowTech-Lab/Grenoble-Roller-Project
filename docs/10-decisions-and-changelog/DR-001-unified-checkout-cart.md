---
title: "DR-001: Unified checkout — cart vs direct HelloAsso for shop, memberships, and paid events"
status: "proposed"
version: "1.0"
created: "2026-06-08"
updated: "2026-06-08"
authors: ["Florian (Mestryx)", "Agent"]
tags: ["product", "decision", "checkout", "helloasso", "events", "memberships", "cart"]
---

# DR-001: Unified checkout — cart vs direct HelloAsso

## Status

**Proposed** — awaiting product validation before implementation on branch `feature/unified-checkout`.

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

## Decision (proposed)

Adopt a **phased unified checkout model** — not a literal extension of today’s product-only `session[:cart]` in v1.

### Phase 1 (this branch scope)

1. **`payment_required`** on `Event` (boolean, default `false`).
2. **Paid event registration** via **dedicated checkout** (same *pattern* as memberships: pending record → HelloAsso redirect → polling), **not** the product session cart.
3. **`ExpirePendingEventAttendancesJob`** + extend `HelloassoService#fetch_and_update_payment` for `Attendance`.
4. **No waitlist** when `payment_required`.

### Phase 2 (harmonization — separate milestone)

Introduce a **checkout abstraction** (`Checkout` / polymorphic line items) that can aggregate:

- Product variants (existing shop),
- Membership lines (adult / N children),
- Event registration lines,

…into **one HelloAsso checkout-intent** when the user chooses “pay everything together”, while still allowing **single-purpose checkout** (membership-only, event-only) without forcing a cart UI.

**Do not** migrate memberships into `session[:cart]` as `{ variant_id => qty }` — memberships are not SKUs and carry season/category/trial/t-shirt rules.

### Phase 1 default for memberships

**Keep** current membership → HelloAsso direct flow in Phase 1. Revisit in Phase 2 when the line-item model exists.

## Rationale

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

## Open questions (product)

1. **Post-payment status:** `paid` only, or `registered` for parity with free events?
2. **Multi-seat:** One HelloAsso payment for parent + N children on same event (mirror multi-membership)?
3. **Phase 2 priority:** Combined “membership + event + shop” in one payment — required for 2026 season or nice-to-have?
4. **Webhooks:** Add HelloAsso webhooks for faster confirmation under load?

## Implementation branch

- **Base:** `Dev` (after this DR is merged/pushed).
- **Branch:** `feature/unified-checkout` — Phase 1 paid events first; Phase 2 design doc follow-up.

## References

- [`docs/09-product/flux-boutique-helloasso.md`](../09-product/flux-boutique-helloasso.md)
- [`docs/06-events/logique-essai-gratuit.md`](../06-events/logique-essai-gratuit.md) — attendance status transitions
- [`docs/09-product/user-journeys-analysis.md`](../09-product/user-journeys-analysis.md) — “Inscription avec paiement”
- HelloAsso: [Checkout intents](https://dev.helloasso.com/docs/api-overview), [Webhooks](https://dev.helloasso.com/docs/notifications-webhook)
- Prior agent research: cart vs direct HelloAsso (2026-06)

---

**Related:** Release notes [`release-dev-to-staging-2026-06.md`](release-dev-to-staging-2026-06.md)
