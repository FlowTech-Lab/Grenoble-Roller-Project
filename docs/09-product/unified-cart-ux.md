---
title: "Unified cart — UX specification"
status: "active"
version: "0.3"
created: "2026-06-08"
updated: "2026-06-08"
branch: "feature/unified-checkout"
---

# Unified cart — UX specification

**Audience:** Florian (copy validation), AI agents (implementation Waves 1–5).

**Principle:** One cart per account; all online payments go through **Panier → Paiement → HelloAsso**.

**Implementation authority:** [`docs/10-decisions-and-changelog/PLAN-unified-checkout-MASTER.md`](../10-decisions-and-changelog/PLAN-unified-checkout-MASTER.md).

---

## Locked product decisions (2026-06-08)

| Topic | Decision |
|-------|----------|
| Don libre | **Always** shown on checkout — including membership-only or event-only carts (never hidden) |
| Partial payment | User selects lines via **checkboxes** on checkout; unselected lines stay in cart |
| Initiations | **Never paid** — registration unchanged (membership / free trial); out of scope for cart |
| Combined payment | One HelloAsso session per checkout for **selected** lines + optional donation |

---

## Navigation

- Navbar: cart icon + badge = **total cart line count** (products + memberships + events).
- Label: **Panier**.

---

## `/cart` — Mon panier

### Layout (desktop)

1. Page title: **Mon panier**
2. Alert if any line expires in &lt; 5 min (warning) or expired (removed on load).
3. **Section — Boutique** (collapsible if empty)
   - Line: thumbnail, name, variant, qty stepper, subtotal, remove.
4. **Section — Adhésions**
   - Line: season, adult name OR child name, category, amount, remove (allowed before pay).
   - Note if health questionnaire incomplete: « Le questionnaire de santé doit être complété avant le paiement. »
5. **Section — Événements** (randos payantes uniquement — pas les initiations)
   - Line: event title, date, participant name, price, **countdown** (« Place réservée — payez avant HH:MM »).
   - On expiry: line removed + toast « Votre réservation a expiré. »
6. **Footer sticky (mobile)**
   - Total TTC (all lines)
   - Primary: **Passer au paiement** (disabled if empty or blocking validation errors)
   - Secondary: Continuer mes achats → `/products` or `/events`

**Note:** Line selection (checkboxes) happens on **checkout**, not on the cart page.

### Empty state

- Illustration + « Votre panier est vide. »
- CTAs: Voir la boutique | Voir les événements | Adhérer

---

## `/checkout` — Paiement

### Line selection (partial payment)

- Each line: **checkbox** (checked by default).
- **Tout sélectionner** master checkbox.
- Expired event lines: checkbox disabled + message « Réservation expirée ».
- Live subtotal: sum of **selected** lines only.
- Primary CTA: **Payer la sélection (X €) avec HelloAsso** — disabled if no line selected.

### Donation (always visible)

- Section title: **Souhaitez-vous ajouter un don à Grenoble Roller ?**
- Same presets as shop today: 0 € / 2 € / 3 € / 5 € / montant libre.
- Shown **even when cart has no shop products** (memberships and/or events only).
- Total displayed = sélection + don.

### Legal & actions

- Checkbox CGV / statuts association if required.
- Secondary: **Modifier mon panier** → `/cart`.
- Back from HelloAsso failure: lines preserved if still valid.

### Return from HelloAsso

- Success: « Paiement en cours de confirmation… » + poll UI (reuse membership pattern).
- Only **paid** lines removed from cart; others remain.

---

## Event show — paid rando (`payment_required`)

- Price displayed (may be informational if external organizer).
- CTA primary: **Réserver ma place**.
- Helper: « Vous aurez 15 minutes pour finaliser le paiement depuis votre panier. »
- **No waitlist** block (hidden).
- If line already in cart: **Place réservée — Finaliser le paiement** → cart.

## Event show — free rando

- Unchanged: **S'inscrire** → immediate registration.

## Initiations — unchanged

- **No** `payment_required`, **no** cart, **no** HelloAsso.
- Existing rules: adhésion active ou essai gratuit (see `docs/06-events/logique-essai-gratuit.md`).

---

## Membership flow — online pay

- After form submit: flash « Adhésion ajoutée au panier. » + link panier.
- Remove prominent « Payer HelloAsso » on show page when unified cart enabled.

## Membership — cash/check

- Unchanged offline flow; no cart line.

---

## Admin — event form (randos)

- Checkbox: **Inscription payante en ligne** (`payment_required`).
- Help: « Si coché, l'inscription passe par le panier et HelloAsso. Le prix affiché peut rester informatif si cette case est décochée. »
- **Not shown** (or disabled) on initiation forms.

---

## Copy FR — key strings

| Key | Text |
|-----|------|
| cart.added_product | Article ajouté au panier. |
| cart.added_membership | Adhésion ajoutée au panier. |
| cart.added_event | Place réservée. Finalisez le paiement dans les 15 minutes. |
| cart.expired_event | Votre réservation pour « %{title} » a expiré. |
| checkout.select_all | Tout sélectionner |
| checkout.pay_selection | Payer la sélection (%{amount}) avec HelloAsso |
| checkout.no_selection | Sélectionnez au moins un élément à payer. |
| checkout.expired_line | Réservation expirée — cette ligne ne peut pas être payée. |
| checkout.donation_title | Souhaitez-vous ajouter un don à Grenoble Roller ? |
| checkout.donation_always | Votre don soutient l'association, quel que soit le contenu du panier. |
| checkout.total_selection | Total sélection |
| checkout.total_with_donation | Total à payer |
| event.reserve_cta | Réserver ma place |
| mes_sorties.pending_payment | En attente de paiement — finalisez depuis votre panier. |

---

## Decisions log

| Date | Decision |
|------|----------|
| 2026-06-08 | Donation always on checkout |
| 2026-06-08 | Partial payment via checkout checkboxes |
| 2026-06-08 | Membership line removable from cart before pay (same as products) |
| 2026-06-08 | Cart icon/badge counts all line types |

---

## Resolved — no open questions

All product questions for this epic were locked **2026-06-08** (see [DR-001](../10-decisions-and-changelog/DR-001-unified-checkout-cart.md)). Do not re-open without a new ADR.

| Topic | Resolution |
|-------|------------|
| Partial payment | Checkboxes on `/checkout`; unselected lines stay in cart |
| Donation | Always on checkout |
| Initiations | Never paid; out of scope |
| Post-pay attendance status | `registered` + `payment_id` |
| Combined payment | One HelloAsso intent per checkout for selected lines |
| Waitlist on paid randos | Blocked when `payment_required` |

---

## References

- [`PLAN-unified-checkout-MASTER.md`](../10-decisions-and-changelog/PLAN-unified-checkout-MASTER.md)
- [`DR-001-unified-checkout-cart.md`](../10-decisions-and-changelog/DR-001-unified-checkout-cart.md)
