---
title: "Plan d'Action Lighthouse - Quick Wins"
date: "2025-11-14"
status: "in_progress"
priority: "quick_wins"
---

# Plan d'Action Lighthouse - Quick Wins

**Stratégie** : Corriger les quick wins sur toutes les pages principales, laisser les optimisations de performance pour la fin du développement.

---

## ✅ **Déjà Fait - Quick Wins Appliqués**

### Meta Description
1. ✅ Meta description ajoutée dans `application.html.erb` (fallback global)
2. ✅ Homepage (`index.html.erb`) - Description ajoutée
3. ✅ Association (`association.html.erb`) - Description ajoutée
4. ✅ Événements liste (`events/index.html.erb`) - Description ajoutée
5. ✅ Événement détail (`events/show.html.erb`) - Description dynamique ajoutée
6. ✅ Boutique (`products/index.html.erb`) - Description ajoutée
7. ✅ Produit détail (`products/show.html.erb`) - Description dynamique ajoutée

### Hiérarchie Headings
1. ✅ Homepage - Modal h5 → h2 corrigé
2. ✅ Association - h2 → h1 corrigé (premier titre)
3. ✅ Événements liste - Modal h5 → h2 corrigé
4. ✅ Événements card - Modals h5 → h2 corrigés (2 modals)
5. ✅ Événement détail - Modals h5 → h2 corrigés (2 modals)
6. ✅ Événement form - Modal h5 → h2 corrigé

**Total** : 7 pages avec meta description + 6 fichiers avec hiérarchie headings corrigée

---

## 📋 **À Faire : Pages Principales**

### 1. Meta Description par Page

**Pages à corriger** :
- ✅ Homepage (`index.html.erb`) - Déjà fait (fallback)
- ⏳ Association (`association.html.erb`)
- ⏳ Événements liste (`events/index.html.erb`)
- ⏳ Événement détail (`events/show.html.erb`)
- ⏳ Boutique (`products/index.html.erb`)
- ⏳ Produit détail (`products/show.html.erb`)

**Méthode** : Ajouter `content_for :description` en haut de chaque page

**Exemple** :
```erb
<% content_for :description, "Description spécifique de la page" %>
```

---

### 2. Hiérarchie Headings

**Pages à vérifier** :
- ✅ Homepage - **CORRIGÉ** (h5 → h2 dans modal)
- ⏳ Association - Vérifier qu'il y a un h1 (actuellement commence par h2)
- ⏳ Événements liste - Vérifier hiérarchie
- ⏳ Événement détail - Vérifier hiérarchie
- ⏳ Boutique - Vérifier hiérarchie

**Règle** : Toujours commencer par `<h1>`, puis `<h2>`, puis `<h3>`, etc.

---

## ⏳ **À Faire Plus Tard (Fin du Dev)**

### Optimisations Performances
- Optimisation images (WebP, compression)
- Purge CSS inutilisé
- Optimisation JavaScript (tree shaking, code splitting)
- Lazy loading images

### Bonnes Pratiques (Production)
- HTTPS
- CSP headers
- HSTS
- COOP
- Trusted Types

**Note** : Ces optimisations seront faites en fin de développement, avant la mise en production.

---

## 🎯 **Plan d'Exécution**

### Phase 1 : Quick Wins (Maintenant) - ~30 min
1. Ajouter meta description sur 5-6 pages principales
2. Vérifier/corriger hiérarchie headings sur 5-6 pages principales

### Phase 2 : Optimisations (Fin du Dev) - 2-4h
1. Optimisation images
2. Purge CSS/JS
3. Configuration sécurité production

---

**Recommandation** : Faire les quick wins maintenant, laisser les optimisations de performance pour la fin du développement.

