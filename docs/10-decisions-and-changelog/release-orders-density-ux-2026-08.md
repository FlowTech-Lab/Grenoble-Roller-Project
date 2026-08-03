---
title: "Patch note — orders density, PDP, glass, WCAG chips (v2.3.3)"
status: "active"
version: "2.3.3"
created: "2026-08-03"
updated: "2026-08-03"
tags: ["release", "patchnote", "Dev", "staging", "ux", "orders", "shop", "a11y", "changelog"]
---

# Patch note — v2.3.3 (Commandes · PDP · glass · WCAG)

**Branch:** `ux/orders-density-and-cards` → `Dev` → `staging`  
**Changelog:** [`CHANGELOG.md`](CHANGELOG.md)  
**Plan:** [`PLAN-orders-density-ux.md`](PLAN-orders-density-ux.md)

**Migrations:** none  
**ENV:** none  
**Rollback:** revert merge / redeploy previous image on the target env

---

## Patch note (human / Discord)

### Headline

**Grenoble Roller — v2.3.3 (staging)**  
Commandes densifiées · fiche produit pro · glass clair/sombre · chips WCAG · fix panier adhésion

### What’s new (user-facing)

1. **Commandes (`/orders`)**
   - Lignes denses type billing : `#id · date · produit · chip · prix · Payer/Voir`
   - Chip statut (icône + libellé FR)
   - Actions inline — plus de bandeau « Détails » pleine largeur

2. **Fiche produit (`/shop/:slug`)**
   - Layout pro : galerie (photo carrée 1:1 + vignettes multi-photos variantes) | colonne d’achat compacte
   - Description longue **sous** la grille (plus dans la colonne droite)
   - Nav compacte `← Boutique / produit` (plus Accueil)
   - Tuiles taille/couleur ; prix + CTA hiérarchisés

3. **Design system — glass**
   - Fond page solide clair/sombre
   - `--liquid-glass-bg: #969ca114` (overlay neutre dual-theme)
   - `prefers-reduced-transparency` : coupe le blur seulement (pas de plaque `body-bg`)

4. **Accessibilité — soft status chips**
   - Tokens `--status-*-fg/bg/border` (clair + sombre), contraste ≥4.5:1
   - « En attente » conforme WCAG AA (plus `--bs-warning` sur pastel)

5. **Panier**
   - Fix crash `/cart` : lignes d’adhésion déjà payées/actives retirées au refresh (plus d’erreur `Only pending memberships…`)

### Smoke checklist

- [ ] `/orders` clair + sombre — chips lisibles, lignes denses
- [ ] `/shop/:slug` — galerie + buy column + description dessous ; tablette ≥768 horizontal
- [ ] `/cart` — ouvre sans erreur même avec ancienne ligne adhésion active
- [ ] Thème clair ↔ sombre ; hard-refresh après deploy (`npm run build:css` au build)

---

## Discord message (staging)

```text
🎿 Grenoble Roller — staging v2.3.3

Déployé sur staging :

• /orders — liste commandes dense (chip statut, Payer/Voir inline)
• Fiche produit — galerie carrée + vignettes, colonne d’achat compacte, description en dessous
• Glass clair/sombre + chips statut accessibles (WCAG)
• Fix panier — plus de crash si une adhésion déjà payée trainait dans le panier

À tester : /orders, /shop (fiche), /cart, toggle thème.
Rollback : redeploy image staging précédente (pas de migration).
```
