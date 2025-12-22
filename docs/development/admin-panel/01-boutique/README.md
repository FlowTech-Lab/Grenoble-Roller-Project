# 🛒 BOUTIQUE - Plan d'Implémentation

**Priorité** : 🔴 HAUTE | **Phase** : 1-3 | **Semaines** : 1-4

---

## 📋 Vue d'ensemble

Gestion complète de la boutique : produits, variantes, inventaire et catégories.

**Objectif** : Transformer la gestion produits en architecture Shopify-like professionnelle avec GRID éditeur et tracking stock avancé.

---

## 📄 Documentation

### **📁 Fichiers détaillés par type (CODE EXACT)**
- [`01-migrations.md`](./01-migrations.md) - Migrations (code exact)
- [`02-modeles.md`](./02-modeles.md) - Modèles (code exact)
- [`03-services.md`](./03-services.md) - Services (code exact)
- [`04-controllers.md`](./04-controllers.md) - Controllers (code exact)
- [`05-routes.md`](./05-routes.md) - Routes (code exact)
- [`06-policies.md`](./06-policies.md) - Policies (code exact)
- [`07-vues.md`](./07-vues.md) - Vues ERB (code exact)
- [`08-javascript.md`](./08-javascript.md) - JavaScript Stimulus (code exact)

### **📁 Fichiers par fonctionnalité**
- [`produits.md`](./produits.md) - Gestion produits (CRUD, export, import)
- [`variantes.md`](./variantes.md) - Gestion variantes (GRID éditeur, bulk edit, images)
- [`inventaire.md`](./inventaire.md) - Tracking stock (inventories, movements, dashboard)
- [`categories.md`](./categories.md) - Gestion catégories (hiérarchie optionnelle)

---

## 🎯 Fonctionnalités Incluses

### ✅ Migrations (3)
- Migration Active Storage (image_url → images)
- Table inventories
- Table inventory_movements

### ✅ Modèles (2 nouveaux + 1 modification)
- `Inventory` - Tracking stock
- `InventoryMovement` - Historique/audit
- `ProductVariant` - Modifications (has_many_attached :images, relation inventory)

### ✅ Services (1)
- `InventoryService` - Calculs stock, réservations

### ✅ Controllers (3)
- `ProductsController` - CRUD produits
- `ProductVariantsController` - GRID éditeur + bulk edit
- `InventoryController` - Dashboard stock

### ✅ Policies (2)
- `ProductPolicy`
- `InventoryPolicy`

### ✅ Vues (5+)
- Products (index, show, new, edit)
- ProductVariants (index GRID, bulk_edit)
- Inventory (index, transfers)

### ✅ JavaScript (1)
- Stimulus controller GRID (édition inline)

---

## ✅ Checklist Globale

### **Phase 1 (Semaine 1) - Migrations & Modèles**
- [ ] Migration Active Storage
- [ ] Migration inventories table
- [ ] Migration inventory_movements table
- [ ] Modèle Inventory
- [ ] Modèle InventoryMovement
- [ ] Modifier ProductVariant (images + inventory)
- [ ] Service InventoryService

### **Phase 2 (Semaine 2) - Controllers & Routes**
- [ ] Controller InventoryController
- [ ] Adapter ProductVariantsController (index, bulk_edit, bulk_update, toggle_status)
- [ ] Adapter ProductsController (publish, unpublish)
- [ ] Routes inventory
- [ ] Routes product_variants
- [ ] Policy InventoryPolicy

### **Phase 3 (Semaine 3-4) - Vues**
- [ ] Vue Inventory Index
- [ ] Vue Inventory Transfers
- [ ] Vue ProductVariants Index (GRID)
- [ ] Vue ProductVariants Bulk Edit
- [ ] Adapter formulaires images

### **Phase 4 (Semaine 4) - JavaScript**
- [ ] Controller Stimulus GRID
- [ ] Validation client
- [ ] Debounce + optimistic locking

---

## 🔴 Points Critiques

1. **ProductVariant** : `has_one_attached :image` → `has_many_attached :images`
2. **ProductVariant** : Validation upload fichiers uniquement (pas de `image_url`)
3. **Inventories** : Migration données depuis `product_variants.stock_qty`

---

## 📊 Estimation

- **Temps** : 3-4 semaines
- **Complexité** : ⭐⭐⭐⭐⭐
- **Dépendances** : Aucune (bloc indépendant)

---

**Retour** : [INDEX principal](../INDEX.md)
