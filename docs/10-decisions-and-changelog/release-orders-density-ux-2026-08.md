---
title: "Patch note Dev UX — orders density + glass + status chips (v2.3.3)"
status: "active"
version: "2.3.3"
created: "2026-08-03"
updated: "2026-08-03"
tags: ["release", "patchnote", "Dev", "ux", "orders", "a11y", "changelog"]
---

# Patch note — v2.3.3 (Commandes densifiées + glass + WCAG chips)

**Target:** merge `ux/orders-density-and-cards` → `Dev`  
**Next step after Dev validation:** Dev → staging (separate PR)  
**Changelog:** [`CHANGELOG.md`](CHANGELOG.md)  
**Plan:** [`PLAN-orders-density-ux.md`](PLAN-orders-density-ux.md)

**Migrations:** none  
**ENV:** none  
**Rollback:** revert merge / redeploy previous `Dev` image

---

## Patch note (human / Discord)

### Headline

**Grenoble Roller — Dev v2.3.3**  
Liste commandes dense · cartes glass cohérentes clair/sombre · chips statut WCAG AA

### What’s new (user-facing)

1. **Commandes (`/orders`)**
   - Lignes denses type billing : `#id · date · produit · chip · prix · Payer/Voir`
   - Chip statut (icône + libellé FR) — plus d’emoji
   - Actions inline (`Payer` + `Voir` compact) — plus de bandeau « Détails » pleine largeur
   - Accents de statut via classes (pas de hex inline)

2. **Design system — glass**
   - Fond page solide clair/sombre (plus de body quasi transparent qui cassait le thème)
   - `--liquid-glass-bg: #969ca114` (overlay neutre dual-theme)
   - `prefers-reduced-transparency` : coupe le blur seulement — **ne** repeint **pas** les cards avec `body-bg` (`#0f131a`)

3. **Accessibilité — soft status chips**
   - Tokens `--status-*-fg/bg/border` (clair + sombre), contraste ≥4.5:1
   - « En attente » n’utilise plus `--bs-warning` (`#ffc107`) en texte sur pastel (~1.6:1 fail)
   - `.order-card__chip` + `.status-badge` branchés sur ces tokens

### Not in this slice

- Sidebar sticky / dédup CTA hero (reste dans le PLAN)
- Preload N+1 controller + specs request orders (à finaliser si besoin avant merge)
- Vague 2 a11y : `text-muted` sur glass, outlines, soft alerts (checklist dans le PLAN)
- Staging / production — uniquement branche → `Dev` pour l’instant

---

## Commits (this branch)

| Area | Focus |
| --- | --- |
| Orders | Dense row partial, index hygiene, cancelled reuse |
| Glass | Body bg solid, `#969ca114`, reduced-transparency fix |
| A11y | Soft status tokens AA, chips + status-badge |
| Layout | Early theme script in `<head>` |
| Bugfix | Stimulus `route_image_viewer` private field `#escapeHandler` |
| Docs | PLAN orders density + this patch note + CHANGELOG |

---

## Smoke checklist (Dev / local)

- [ ] `/orders` light — chip « En attente » lisible (contraste) ; ligne dense ; Payer/Voir
- [ ] `/orders` dark — cards glass (pas plaque `#0f131a`) ; chips lisibles
- [ ] Hard-refresh après `npm run build:css` (builds gitignored)
- [ ] Toggle thème clair ↔ sombre sans flash / texte illisible
- [ ] `/memberships` — smoke cards + status badges si présents
- [ ] Cursor Simple Browser with reduced transparency — cards still translucent fill
