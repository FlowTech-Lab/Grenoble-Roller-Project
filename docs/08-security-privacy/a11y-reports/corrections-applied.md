---
title: "Corrections Accessibilité Appliquées"
date: "2025-11-14"
status: "completed"
---

# Corrections Accessibilité Appliquées

**Date** : 2025-11-14  
**Source** : Résultats tests Pa11y  
**Standard** : WCAG 2.1 AA

---

## ✅ Corrections Appliquées

### 1. IDs dupliqués dans boutique (10 erreurs) - **CORRIGÉ**

**Problème** : Plusieurs champs `quantity` avec le même ID `id="quantity"`

**Solution** : Ajout d'IDs uniques par produit
- **Fichier** : `app/views/products/index.html.erb`
- **Changement** : `id="quantity"` → `id="quantity-#{product.id}"`
- **Lignes** : 105, 115

```erb
<!-- Avant -->
<%= hidden_field_tag :quantity, 1 %>

<!-- Après -->
<%= hidden_field_tag :quantity, 1, id: "quantity-#{product.id}" %>
```

---

### 2. Contraste badges `bg-info` (6 erreurs) - **CORRIGÉ**

**Problème** : Ratio contraste 1.96:1 (requis 4.5:1)

**Solution** : Override CSS Bootstrap avec couleur conforme
- **Fichier** : `app/assets/stylesheets/_style.scss`
- **Changement** : `background-color: #00819b !important;` (était `#0dcaf0` par défaut Bootstrap)
- **Ligne** : 369-372

```scss
/* Override Bootstrap bg-info pour contraste WCAG AA */
.badge.bg-info {
  background-color: #00819b !important; /* Corrigé pour contraste 4.5:1 */
  color: white;
}
```

---

### 3. Contraste badges `badge-liquid-primary` (2 erreurs) - **CORRIGÉ**

**Problème** : Ratio contraste 2.47:1 (requis 4.5:1)

**Solution** : Ajustement couleur background
- **Fichier** : `app/assets/stylesheets/_style.scss`
- **Changement** : `background: #2978c9;` (était `#5aa9fa`)
- **Ligne** : 357

```scss
.badge-liquid-primary {
  background: #2978c9; /* Corrigé pour contraste 4.5:1 (était #5aa9fa) */
  color: white;
  border: none;
}
```

---

### 4. Lien mort `#adhesion` (1 erreur) - **CORRIGÉ**

**Problème** : Lien vers ancre `#adhesion` qui n'existe pas

**Solution** : Redirection vers page d'inscription
- **Fichiers** : 
  - `app/views/pages/association.html.erb` (ligne 19)
  - `app/views/pages/index.html.erb` (ligne 31)
- **Changement** : `href="#adhesion"` → `href="<%= new_user_registration_path %>"`

```erb
<!-- Avant -->
<a href="#adhesion" class="btn btn-liquid-primary btn-sm">

<!-- Après -->
<a href="<%= new_user_registration_path %>" class="btn btn-liquid-primary btn-sm">
```

---

### 5. Select sans label (2 erreurs) - **CORRIGÉ**

**Problème** : Select désactivé sans `aria-label` ou label

**Solution** : Ajout `aria-label` descriptif
- **Fichier** : `app/views/products/index.html.erb`
- **Ligne** : 83
- **Changement** : Ajout `aria-label="Taille unique"`

```erb
<!-- Avant -->
<select class="form-select form-select-sm" disabled>

<!-- Après -->
<select class="form-select form-select-sm" disabled aria-label="Taille unique">
```

---

## 📊 Résumé

- **Total erreurs corrigées** : 21 erreurs
- **Fichiers modifiés** : 3 fichiers
- **Lignes modifiées** : 5 modifications

### Fichiers Modifiés

1. `app/views/products/index.html.erb` - IDs uniques + aria-label
2. `app/assets/stylesheets/_style.scss` - Contrastes badges
3. `app/views/pages/association.html.erb` - Lien adhésion
4. `app/views/pages/index.html.erb` - Lien adhésion

---

## 🎯 Prochaine Étape

**Relancer les tests Pa11y** pour valider les corrections :

```bash
npm run test:a11y:pa11y
```

**Objectif** : 6/6 pages conformes (actuellement 2/6)

---

**Status** : ✅ Toutes les corrections appliquées

