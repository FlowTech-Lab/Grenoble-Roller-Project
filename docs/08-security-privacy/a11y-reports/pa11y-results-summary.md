---
title: "Résultats Tests Pa11y - Résumé"
date: "2025-11-14"
tool: "Pa11y CI"
standard: "WCAG2AA"
---

# Résultats Tests Pa11y - Résumé

**Date** : 2025-11-14  
**Standard** : WCAG 2.1 AA  
**Outils** : Pa11y CI  
**URLs testées** : 6 pages

---

## 📊 Résultats Globaux

- ✅ **2/6 pages** passent sans erreur
- ❌ **4/6 pages** ont des erreurs d'accessibilité
- **Total erreurs** : 20 erreurs

---

## ✅ Pages Conformes

1. ✅ **Connexion** (`/users/sign_in`) - 0 erreur
2. ✅ **Inscription** (`/users/sign_up`) - 0 erreur

---

## ❌ Pages avec Erreurs

### 1. Homepage (`/`) - 1 erreur

**Problème** : Contraste insuffisant
- **Élément** : Badge `bg-info` 
- **Ratio actuel** : 1.96:1
- **Ratio requis** : 4.5:1 (WCAG AA)
- **Recommandation** : Changer background à `#00819b`
- **Localisation** : `#main-content > section > div > div:nth-child(2) > div > article > div:nth-child(2) > header > div:nth-child(3) > span:nth-child(2)`

### 2. Association (`/association`) - 2 erreurs

**Problème 1** : Lien mort
- **Élément** : Lien vers `#adhesion`
- **Problème** : L'ancre `#adhesion` n'existe pas dans le document
- **Localisation** : `#main-content > section:nth-child(1) > div > div:nth-child(1) > div > a`

**Problème 2** : Contraste insuffisant
- **Élément** : Badge `badge-liquid-primary`
- **Ratio actuel** : 2.47:1
- **Ratio requis** : 4.5:1 (WCAG AA)
- **Recommandation** : Changer background à `#2978c9`
- **Localisation** : `#main-content > section:nth-child(3) > div > div:nth-child(2) > div > div:nth-child(2) > div > span`

### 3. Boutique (`/shop`) - 12 erreurs

**Problème 1** : IDs dupliqués (10 occurrences)
- **Élément** : Champs `quantity` avec `id="quantity"`
- **Problème** : Plusieurs produits ont le même ID, ce qui viole l'unicité HTML
- **Solution** : Utiliser des IDs uniques par produit (ex: `quantity-${product.id}`)

**Problème 2** : Select sans label (2 occurrences)
- **Élément** : `<select class="form-select form-select-sm" disabled>`
- **Problème** : Pas de label, `aria-label`, ou `aria-labelledby`
- **Solution** : Ajouter `aria-label="Taille unique"` ou masquer avec `aria-hidden="true"` si décoratif

### 4. Événements (`/events`) - 5 erreurs

**Problème** : Contraste insuffisant (5 occurrences)
- **Éléments** : Badges `bg-info` et `badge-liquid-primary`
- **Ratio actuel** : 1.96:1 à 2.47:1
- **Ratio requis** : 4.5:1 (WCAG AA)
- **Recommandations** :
  - `bg-info` : Changer background à `#00819b`
  - `badge-liquid-primary` : Changer background à `#2978c9`

---

## 🎯 Priorisation des Corrections

### 🔴 Critique (Bloqueurs WCAG AA)

1. **IDs dupliqués dans boutique** (10 erreurs)
   - Impact : Violation HTML, problèmes lecteurs d'écran
   - Effort : Faible (changer `id="quantity"` en `id="quantity-${product.id}"`)
   - Fichier : `app/views/products/index.html.erb`

2. **Contraste badges `bg-info`** (6 occurrences)
   - Impact : Non-conformité WCAG 1.4.3 Level AA
   - Effort : Faible (ajuster couleur CSS)
   - Fichier : `app/assets/stylesheets/_style.scss`

3. **Contraste badges `badge-liquid-primary`** (2 occurrences)
   - Impact : Non-conformité WCAG 1.4.3 Level AA
   - Effort : Faible (ajuster couleur CSS)
   - Fichier : `app/assets/stylesheets/_style.scss`

### 🟡 Important

4. **Lien mort `#adhesion`**
   - Impact : Lien non fonctionnel
   - Effort : Faible (corriger href ou ajouter l'ancre)
   - Fichier : `app/views/pages/association.html.erb`

5. **Select sans label**
   - Impact : Accessibilité formulaires
   - Effort : Très faible (ajouter `aria-label`)
   - Fichier : `app/views/products/index.html.erb`

---

## 📝 Actions Recommandées

1. ✅ **Corriger IDs dupliqués** - `quantity` → `quantity-${product.id}`
2. ✅ **Ajuster contrastes badges** - `bg-info` et `badge-liquid-primary`
3. ✅ **Corriger lien mort** - `#adhesion` → ancre existante ou route
4. ✅ **Ajouter labels selects** - `aria-label` sur selects désactivés

---

**Prochaine étape** : Corriger ces problèmes et relancer les tests.

