---
title: "Patch note Dev UX — memberships + shop catalog (v2.3.2)"
status: "active"
version: "2.3.2"
created: "2026-08-03"
updated: "2026-08-03"
tags: ["release", "patchnote", "Dev", "ux", "memberships", "shop", "changelog"]
---

# Patch note — v2.3.2 (UX memberships + boutique)

**Target:** merge `ux/pages-verification` → `Dev` (PR [#253](https://github.com/Grenoble-roller/Grenoble-Roller-Website/pull/253))  
**Next step after Dev validation:** Dev → staging (separate PR)  
**Changelog:** [`CHANGELOG.md`](CHANGELOG.md)  
**Plan:** [`PLAN-ux-pages-verification.md`](PLAN-ux-pages-verification.md)

**Migrations:** none  
**ENV:** none  
**Rollback:** revert merge / redeploy previous `Dev` image

---

## Patch note (human / Discord)

### Headline

**Grenoble Roller — Dev v2.3.2**  
Adhésions plus claires · boutique type étagère · renouvellement cohérent adulte/enfant

### What’s new (user-facing)

1. **Adhésions (`/memberships`)**
   - Barre de progression = **jours restants** (urgence visuelle)
   - Bouton **Réadhérer** aussi sur la carte **adulte** (plus seulement dans le bandeau)
   - Le bouton **disparaît** dès qu’une adhésion saison suivante (active / en attente) existe
   - Sidebar : plus de « Pas d’adhésion active » pendant la fenêtre de renouvellement
   - Centrage icônes / boutons (Bootstrap Icons)

2. **Boutique (`/shop`)**
   - Vignettes catalogue **carrées (1:1)** — fiche produit reste **16:9**
   - Cartes plus denses (titres clampés), grille plus serrée
   - Carte entière cliquable (plus de « Choisir les options » / « Voir le produit » sur la grille)
   - Filtres : rail sticky desktop + chips mobile
   - Bannière HelloAsso migration **conservée**
   - Compteur produits côté contrôleur ; lien panier dans l’en-tête

3. **Commandes / checkout (léger)**
   - Hero `/orders` équilibré ; lien boutique sidebar masqué si liste vide
   - Checkout en `container` (largeur site)

### Not in this slice

- Refonte dense SaaS de `/orders` (lignes type billing) — **proposée**, pas encore livrée (slices A/B/C)
- Staging / production — uniquement `Dev` pour l’instant

---

## Commits (highlights on `ux/pages-verification`)

| Area | Focus |
| --- | --- |
| Memberships | Progress remaining days, CTA hygiene, adult Réadhérer, successor hide |
| Shop | Square thumbs, clickable cards, filter rail/chips, HelloAsso banner |
| Orders/checkout | Hero/sidebar hygiene, container width |
| Quality | RSpec renew + shop catalog ; image-format exception doc ; PLAN tracker |

---

## Smoke checklist (Dev / local)

- [ ] `/memberships` — Réadhérer adulte + enfants (&lt;30 j) ; masqué après renew saison suivante
- [ ] `/shop` — thumbs 1:1, carte cliquable, filtres OK
- [ ] `/shop/:slug` — titre large + image 16:9
- [ ] `/orders` + `/checkout/new` — smoke layout
- [ ] `bundle exec rspec spec/models/membership_spec.rb spec/requests/memberships_spec.rb spec/requests/products_spec.rb`
