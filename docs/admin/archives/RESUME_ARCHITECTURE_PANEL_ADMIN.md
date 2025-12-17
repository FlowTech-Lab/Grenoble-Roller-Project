# 📋 Résumé Architecture Panel Admin - Produits & Boutique

**Source** : [architecture-panel-admin.md](architecture-panel-admin.md) (Réponse Perplexity complète)  
**Date** : 2025-01-27  
**Stack** : Rails 8.1.1 | Bootstrap 5.3.2 | Stimulus | PostgreSQL 16 | Pundit

---

## 🎯 Vue d'Ensemble

Cette architecture couvre la gestion complète des **Produits, Variantes, Catégories et Commandes** dans le nouveau panel admin.

**Guide complet** : Voir [architecture-panel-admin.md](architecture-panel-admin.md) pour tous les détails et exemples de code.

---

## 📁 Structure Recommandée

### Controllers (`app/controllers/admin/`)
- `base_controller.rb` : Controller parent avec Pundit + authentification admin
- `products_controller.rb` : CRUD produits + scopes + filtres
- `product_variants_controller.rb` : CRUD variantes (imbriquées)
- `product_categories_controller.rb` : CRUD catégories
- `orders_controller.rb` : CRUD commandes + workflow statuts

### Vues (`app/views/admin/`)
- **Produits** : `index.html.erb`, `show.html.erb`, `edit.html.erb`, `_form.html.erb`
- **Variantes** : Partials pour formulaires et modals
- **Commandes** : `index.html.erb`, `show.html.erb` avec workflow statuts
- **Shared** : Partials réutilisables (`_filters.html.erb`, `_pagination.html.erb`)

### Stimulus Controllers (`app/javascript/controllers/admin/`)
- `product_form_controller.js` : Gestion tabs, validation
- `variant_form_controller.js` : Création/édition variantes inline
- `image_upload_controller.js` : Upload avec prévisualisation
- `order_status_controller.js` : Changement statut commande
- `filter_controller.js` : Filtres dynamiques

### Helpers (`app/helpers/admin/`)
- `products_helper.rb` : Calcul stock agrégé, formats prix
- `orders_helper.rb` : Badges statuts, workflow

---

## 🔑 Points Clés de l'Architecture

### 1. Formulaires avec Tabs Bootstrap

**Structure** : Formulaire produit avec 3 tabs :
- **Tab "Informations"** : Catégorie, nom, slug, description, prix, devise, statut
- **Tab "Variantes"** : Liste variantes avec création/édition inline (modal ou form nested)
- **Tab "Images"** : Upload Active Storage avec prévisualisation

**Stimulus** : `product_form_controller.js` pour navigation tabs et validation.

### 2. Gestion Stock Agrégé

**Problème** : Le stock réel est dans `ProductVariant`, pas dans `Product`.

**Solution** :
- **Helper** : `stock_total` dans `ProductsHelper` (somme des variantes actives)
- **Scope** : `with_stock` sur Product (joins + where)
- **Affichage** : Badges Bootstrap avec couleurs (vert/jaune/rouge)

```ruby
# app/helpers/admin/products_helper.rb
def stock_total(product)
  product.product_variants.where(is_active: true).sum(:stock_qty)
end
```

### 3. Variantes - Approche Imbriquée

**Deux options** :

**Option A : Formulaire Nested (Recommandé pour MVP)**
- Formulaire produit avec `fields_for :product_variants`
- Création/édition variantes dans le même formulaire
- Plus simple mais moins flexible

**Option B : Approche Séparée (Recommandé pour production)**
- Formulaire produit séparé
- Variantes gérées via modal Stimulus (`variant_form_controller.js`)
- AJAX pour créer/modifier sans recharger
- Plus flexible et meilleure UX

**Recommandation** : Commencer par Option A (MVP), migrer vers Option B plus tard.

### 4. Upload Images avec Prévisualisation

**Stimulus Controller** : `image_upload_controller.js`
- Prévisualisation immédiate après sélection
- Support Active Storage + transition `image_url`
- Validation côté client (taille, format)
- Message d'erreur inline

### 5. Workflow Commandes

**Statuts** : `pending` → `paid` → `preparation` → `shipped`  
**Actions spéciales** : `cancelled`, `refund_requested`, `refunded`, `failed`

**Stimulus Controller** : `order_status_controller.js`
- Dropdown avec transitions valides/invalides
- Confirmation modale pour actions critiques (annulation, remboursement)
- Validation transitions côté serveur

### 6. Validation Hybride

**Client (Stimulus)** :
- Validation sur `blur` et `input`
- Feedback immédiat avec classes Bootstrap `is-invalid` / `invalid-feedback`
- Désactivation submit si erreurs

**Serveur (Rails)** :
- Validations modèles (source de vérité)
- Endpoint AJAX pour validation asynchrone si besoin
- Messages d'erreur avec formatage Bootstrap

### 7. Performance & Optimisations

**Eager Loading** :
```ruby
@products = Product.includes(:category, product_variants: :option_values)
```

**Pagination** : Utiliser **Pagy** (plus léger que Kaminari)

**Scopes réutilisables** :
```ruby
# app/models/product.rb
scope :with_stock, -> { joins(:product_variants).where('product_variants.stock_qty > 0').distinct }
scope :active, -> { where(is_active: true) }
```

**Anti-patterns à éviter** :
- ❌ N+1 queries (mettre des `includes` partout)
- ❌ Requêtes dans les vues (utiliser les helpers)
- ❌ Calculs répétés (mettre en cache ou helper)

---

## 📊 Migration depuis Active Admin

### Équivalences Scopes

| Active Admin | Nouveau Panel |
|--------------|---------------|
| `scope :all` | `Product.all` |
| `scope("Actifs")` | `Product.active` ou `Product.where(is_active: true)` |
| `scope("En rupture")` | `Product.out_of_stock` (scope custom) |
| `scope("En stock")` | `Product.with_stock` (scope custom) |

### Équivalences Filtres

| Active Admin | Nouveau Panel |
|--------------|---------------|
| `filter :name` | Filtre manuel avec `where("LOWER(name) LIKE ?")` |
| `filter :category` | Filtre avec `where(category_id: params[:category_id])` |
| `filter :is_active` | Filtre avec `where(is_active: params[:is_active])` |

**Voir** : [architecture-panel-admin.md](architecture-panel-admin.md) section "Migration depuis Active Admin" pour détails complets.

---

## 🎨 Classes Bootstrap à Utiliser

### Tableaux
- `table`, `table-striped`, `table-hover`
- `table-responsive` pour mobile

### Badges Statuts
- `badge bg-success` : En stock, Actif
- `badge bg-warning` : Stock faible, En préparation
- `badge bg-danger` : Rupture de stock, Annulé
- `badge bg-info` : En attente

### Formulaires
- `form-control`, `form-label`, `form-select`
- `is-invalid`, `invalid-feedback` pour erreurs
- `form-check`, `form-check-input` pour checkboxes

### Tabs
- `nav`, `nav-tabs`, `nav-item`, `nav-link`
- `tab-content`, `tab-pane`, `fade`, `show active`

### Modals
- `modal`, `modal-dialog`, `modal-content`
- `modal-header`, `modal-body`, `modal-footer`

**Référence complète** : [../references/reference-css-classes.md](../references/reference-css-classes.md)

---

## 📝 Prochaines Étapes

### Implémentation Progressive

1. **Phase 1 - MVP (2-3 jours)** :
   - ✅ BaseController avec Pundit
   - ✅ ProductsController avec scopes basiques
   - ✅ Vue `index` avec tableau Bootstrap
   - ✅ Vue `show` avec détails produit

2. **Phase 2 - Formulaires (3-4 jours)** :
   - ✅ Formulaire produit avec tabs Bootstrap
   - ✅ Gestion variantes (approche nested d'abord)
   - ✅ Upload images avec prévisualisation
   - ✅ Validation hybride

3. **Phase 3 - Commandes (2-3 jours)** :
   - ✅ OrdersController avec workflow
   - ✅ Vue commandes avec changement statut
   - ✅ Stimulus pour workflow

4. **Phase 4 - Optimisations (2 jours)** :
   - ✅ Eager loading partout
   - ✅ Pagination Pagy
   - ✅ Helpers stock agrégé
   - ✅ Tests

### Fichiers à Créer en Priorité

1. `app/controllers/admin/base_controller.rb`
2. `app/controllers/admin/products_controller.rb` (mise à jour)
3. `app/views/admin/products/index.html.erb`
4. `app/views/admin/products/show.html.erb`
5. `app/helpers/admin/products_helper.rb`
6. `app/javascript/controllers/admin/product_form_controller.js`

**Voir** : [architecture-panel-admin.md](architecture-panel-admin.md) pour code complet de chaque fichier.

---

## ✅ Checklist Implémentation

### Infrastructure
- [ ] BaseController créé avec Pundit
- [ ] Routes admin configurées
- [ ] Layout admin créé

### Produits
- [ ] ProductsController avec scopes et filtres
- [ ] Vue `index` avec tableau Bootstrap
- [ ] Vue `show` avec détails et variantes
- [ ] Vue `edit` avec formulaire tabs
- [ ] Partial `_form.html.erb`
- [ ] Helper `stock_total`
- [ ] Stimulus `product_form_controller.js`

### Variantes
- [ ] ProductVariantsController
- [ ] Formulaires variantes (nested ou modal)
- [ ] Stimulus `variant_form_controller.js`

### Images
- [ ] Stimulus `image_upload_controller.js`
- [ ] Prévisualisation images
- [ ] Transition `image_url` → Active Storage

### Commandes
- [ ] OrdersController avec workflow
- [ ] Vue commandes avec filtres
- [ ] Stimulus `order_status_controller.js`
- [ ] Gestion transitions statuts

### Performance
- [ ] Eager loading partout
- [ ] Pagination Pagy
- [ ] Scopes réutilisables
- [ ] Helpers optimisés

---

## 📚 Références

### Documentation Complète
- **[architecture-panel-admin.md](architecture-panel-admin.md)** : Guide complet avec tous les exemples de code

### Autres Décisions
- **[form-validation-guide.md](form-validation-guide.md)** : Détails validation hybride
- **[reference-css-classes.md](../references/reference-css-classes.md)** : Classes Bootstrap disponibles

### Planning
- **[plan-implementation.md](../planning/plan-implementation.md)** : Plan global avec user stories
- **[CLARIFICATION_ETAPES.md](../planning/CLARIFICATION_ETAPES.md)** : Méthode étape par étape

---

**Dernière mise à jour** : 2025-01-27  
**Statut** : Architecture complète validée, prête pour implémentation
