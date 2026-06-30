# Flux complet : panier unifié → HelloAsso API

**Date** : 2026-06-08  
**Version** : 2.0  
**Status** : Unified checkout (feature flag `UNIFIED_CART_ENABLED`)

---

## Vue d'ensemble

Tous les paiements en ligne (boutique, adhésions, randos payantes) passent par :

**`CartLine` (DB, par utilisateur) → `/checkout` (sélection partielle + don) → HelloAsso → `CheckoutFulfillmentService`**

Le flux legacy `session[:cart]` → `POST /orders` reste actif uniquement quand `UNIFIED_CART_ENABLED=false`.

Références :
- [`PLAN-unified-checkout-MASTER.md`](../10-decisions-and-changelog/PLAN-unified-checkout-MASTER.md)
- [`unified-cart-ux.md`](unified-cart-ux.md)

---

## Flux unifié (flag activé)

### Étape 1 — Ajout au panier

| Type | Entrée | Stockage |
|------|--------|----------|
| Boutique | `POST /cart/add_item` | `CartLine` `product_variant` |
| Adhésion | création membership + redirect cart | `CartLine` `membership` |
| Rando payante | `POST /events/:id/attendances` | `Attendance` pending + `CartLine` `event_registration` (timer 15 min) |

Le badge navbar compte **toutes** les lignes (`ApplicationHelper#cart_items_count` → `CartLineService.count`).

### Étape 2 — Page panier (`GET /cart`)

- Sections : Événements, Adhésions, Boutique
- Alertes d'expiration (< 5 min) pour les réservations événement
- CTA : **Passer au paiement** → `/checkout`

### Étape 3 — Checkout (`GET/POST /checkout`)

1. Cases à cocher par ligne (sélection partielle)
2. Don optionnel **toujours visible** (`donation_cents`)
3. `CheckoutService.build_from_cart` crée `Checkout` + `CheckoutLine` snapshots
4. Pour les lignes boutique : `Order` pending créé (sans email immédiat)
5. `HelloassoService.create_unified_checkout_intent(checkout)` → redirect HelloAsso

### Étape 4 — Retour et polling

- `GET /checkout/:id` — page de retour
- `SyncHelloAssoPaymentsJob` (5 min) + `ExpireCartLinesJob` (2 min)
- `CheckoutFulfillmentService.fulfill!` sur paiement confirmé

### Étape 5 — Post-paiement (fulfillment)

| Ligne | Action |
|-------|--------|
| `product_variant` | `Order` → `paid`, email `order_confirmation` |
| `membership` | `Membership` → `active` |
| `event_registration` | `Attendance` → `registered`, email `attendance_confirmed` |

Les lignes non sélectionnées restent dans le panier.

---

## Flux legacy (flag désactivé)

### Boutique seule

1. `POST /orders` — panier `session[:cart]`
2. `Order` pending + `OrderMailer.order_confirmation` immédiat
3. `HelloassoService.create_checkout_intent(order)`
4. Polling → `Order` paid

### Adhésions

`Memberships::PaymentsController` → HelloAsso direct (sans panier).

---

## Feature flag

| Env | Valeur | Usage |
|-----|--------|-------|
| Staging | `UNIFIED_CART_ENABLED=true` | QA manuelle (checklist MASTER §G) |
| Production | `false` jusqu'à sign-off humain | Rollback : repasser à `false` (voir MASTER §H) |

Template : `ops/dokploy/env/staging.env.example`

---

## Points techniques HelloAsso

- Endpoint : `POST /v5/organizations/{slug}/checkout-intents`
- Payload unifié : `totalAmount`, `itemName`, `containsDonation`, `metadata` (`checkoutId`, `donationCents`, lignes snapshot)
- TTL redirect HelloAsso : 15 min
- Pas de webhooks — polling uniquement

---

## Admin

- Checkouts unifiés : `/admin-panel/checkouts` (lecture seule, audit)
- Événements : champ `payment_required` visible sur la fiche admin
