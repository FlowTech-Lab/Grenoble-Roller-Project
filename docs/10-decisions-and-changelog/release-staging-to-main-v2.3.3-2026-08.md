---
title: "Release staging → main (August 2026 UX — v2.3.3)"
status: "active"
version: "2.3.3"
created: "2026-08-03"
updated: "2026-08-03"
tags: ["release", "production", "main", "changelog", "ux", "shop", "orders", "memberships"]
---

# Release staging → main (v2.3.3)

**Target:** merge `staging` → `main` (production = https://grenoble-roller.org)  
**Commit range:** `764095dd` … `ba965598` (`origin/main` … `origin/staging`)  
**Commits ahead of main:** **34** (Dev → staging **#255** + stock-badge merge)  
**Head on staging:** `ba965598` — `merge: Dev → staging (stock badges after v2.3.3)`

**Staging validation URL:** https://staging.grenoble-roller.org  
**Human sign-off required** before merge. Do **not** merge without Florian approval.

**Detail patch notes:**  
- [`release-ux-pages-verification-2026-08.md`](release-ux-pages-verification-2026-08.md) (v2.3.2)  
- [`release-orders-density-ux-2026-08.md`](release-orders-density-ux-2026-08.md) (v2.3.3)  

**Changelog:** [`CHANGELOG.md`](CHANGELOG.md)

**Migrations:** none  
**ENV:** none  
**Rollback:** redeploy previous `main` image (no DB rollback)

---

## Patch note (human / Discord)

### Headline

**Grenoble Roller — Production v2.3.3**  
Adhésions UX · boutique catalogue/PDP · commandes densifiées · glass/WCAG · badges stock

### What’s new (user-facing)

1. **Adhésions (v2.3.2)**  
   - Barre de jours restants · **Réadhérer** sur carte adulte · sidebar / enfants allégés

2. **Boutique**  
   - Catalogue : vignettes **1:1**, cartes cliquables, filtres  
   - Fiche produit : galerie carrée + vignettes variantes, colonne d’achat compacte, description dessous  
   - Badges stock honnêtes : **En stock** / **Plus que N** (≤5, orange) / **Rupture** (`available_qty`)

3. **Commandes (`/orders`)**  
   - Lignes denses + chips statut accessibles (WCAG)

4. **Design / a11y**  
   - Glass clair/sombre dual-theme · soft status tokens (plus `--bs-warning` illisible)

5. **Panier**  
   - Fix crash si une ligne d’adhésion déjà payée trainait dans le panier

### Smoke checklist (prod)

- [ ] `/memberships` — progress + Réadhérer
- [ ] `/shop` + `/shop/:slug` — catalogue, PDP, badges stock
- [ ] `/orders` — liste dense clair/sombre
- [ ] `/cart` — ouvre sans erreur
- [ ] Theme toggle

---

## Discord (production)

**Target channel (Grenoble Roller guild):** `1513250924489867455`  
**Not** Captain Hook (`1522208233291382836`) — that channel was used by mistake for earlier staging notes.

**Webhook:** store as `GRENOBLE_ROLLER_DISCORD_RELEASE_WEBHOOK` (Agent Vault or local `.env`, chmod 600). Must be created on channel `1513250924489867455`.

### After merge — same model as staging (prod wording)

```text
🎿 **Patch Production v2.3.3** — en ligne sur https://grenoble-roller.org (PR #256)
HelloAsso **live** · migrations : aucune · rollback : redeploy image main précédente

• Adhésions — jours restants, Réadhérer
• Boutique — cartes 1:1, fiche produit galerie, badges stock
• Commandes — liste dense + chips WCAG
• Glass clair/sombre · fix panier adhésion
```

---

## Ops

| Item | Value |
| --- | --- |
| Deploy | Dokploy `main` auto or manual after merge |
| Migrations | **none** |
| ENV | **none** |
| HelloAsso | prod = live (re-smoke one payment if touching checkout UX) |
| Rollback | Redeploy previous `main` image |
