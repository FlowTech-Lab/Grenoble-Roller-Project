REFONTE COMPLÈTE - ARCHITECTURE ADMIN PROFESSIONAL
Date : 2025-12-21
Objectif : Transformer le flux chaotique en architecture Shopify/Amazon-like
Complexité : ⭐⭐⭐⭐⭐ (Architecture complète)

> ⚠️ **IMPORTANT - ADAPTATION À LA STRUCTURE ACTUELLE**  
> Ce document a été adapté pour être cohérent avec le `schema.rb` existant.  
> Voir `docs/development/admin-panel/incoherences-schema-refonte.md` pour les détails des migrations nécessaires.

## 🔄 ADAPTATIONS À LA STRUCTURE ACTUELLE

### **Tables existantes à adapter :**
- ✅ `product_categories` → À renommer en `categories` + ajouter hiérarchie
- ✅ `products` → Existe, ajouter `product_template_id`
- ✅ `product_variants` → Existe, à renommer en `variants` OU adapter le code
- ✅ `option_types`, `option_values`, `variant_option_values` → Existent

### **Tables à créer :**
- ❌ `inventories` → Nouvelle table (migrer `stock_qty` depuis `product_variants`)
- ❌ `inventory_movements` → Nouvelle table

> ⚠️ **SIMPLIFICATION** : `product_templates` et `option_sets` sont **SKIP** pour l'instant (overkill pour le cas d'usage actuel).  
> Voir section "Recommandations" pour détails.

### **Images :**
- ✅ **Active Storage déjà configuré** → Utiliser directement (pas besoin de table `variant_images`)

### **Stratégie recommandée (SIMPLIFIÉE) :**
1. **Phase 1** : Adapter le code pour utiliser les tables existantes (`product_variants`, `product_categories`)
2. **Phase 2** : Créer les nouvelles tables (`inventories`, `inventory_movements`)
3. **Phase 3** : Migrer les données (stock depuis `product_variants.stock_qty`, images depuis `image_url` vers Active Storage)
4. **Phase 4** : Renommer les tables si souhaité (`product_variants` → `variants`)

> ⚠️ **SKIP** : `product_templates` et `option_sets` → À ajouter dans 6-12 mois si besoin réel

---

⚠️ PROBLÈMES IDENTIFIÉS
text
❌ Catégories flottantes (pas d'hiérarchie)
❌ Variantes désorganisées (SKU auto mauvais)
❌ Pas de gestion d'inventaire smart
❌ Prévisualisation manquante
❌ Pas de modèles/templates produits
❌ Workflows mélangés (auto/manuel/édition)
❌ Pas d'images par variante efficace
❌ Pas de historique/audit
❌ Pas de bulk operations
❌ Performance N+1 sur variantes
🎯 ARCHITECTURE NOUVELLE - SHOPIFY-LIKE
Stack Décisions
text
Frontend:
  Layout: Sidebar admin + Main content (comme Shopify)
  Tabs: Dashboard / Products / Variants / Categories / Orders / Settings
  
Product Management:
  Two-step: Product → Variants SÉPARÉS (pas un)
  Inventory: Système agrégé par variante
  Variants: Gestion GRID (tableau éditeur)
  
Templates:
  ⚠️ Product Templates: SKIP (overkill pour cas d'usage actuel)
  ⚠️ Option Sets: SKIP (overkill pour cas d'usage actuel)
  
  → Utiliser OptionTypes directement (existe déjà)
  
UX:
  Drag-drop: Réorganisation
  Bulk Edit: Édition en masse
  Preview: Live product preview
  Audit: Historique complet
📐 NOUVELLE ARCHITECTURE (4 NIVEAUX)
text
NIVEAU 1: CATEGORIES (Hiérarchique)
  ├─ Parent (ex: "Équipement")
  ├─ Child (ex: "Protections")
  └─ Child (ex: "Casques")

NIVEAU 2: PRODUCTS (Entité principale)
  ├─ Infos (Nom, Description, Image hero)
  ├─ Option Types (sélection manuelle)
  └─ Pricing Rules (règles prix)

> ⚠️ **SIMPLIFIÉ** : Product Templates et Option Sets SKIP pour l'instant

NIVEAU 3: VARIANTS (Combinaisons d'options)
  ├─ SKU (unique, format smart)
  ├─ Inventory (Stock, reservé, disponible)
  ├─ Images (multiples par variante)
  ├─ Pricing (override/héritage)
  └─ Metadata (couleur, taille, etc.)

NIVEAU 4: INVENTORY (Tracking)
  ├─ Stock qty (actuel)
  ├─ Reserved qty (en commandes)
  ├─ Available qty (calculé)
  ├─ Historique (log movements)
  └─ Warehouse locations (future)
🗂️ STRUCTURE FICHIERS OPTIMISÉE
text
app/
├── controllers/admin/
│   ├── dashboard_controller.rb          ← NEW: Vue globale
│   ├── base_controller.rb               ← REFACTOR: Pundit + common
│   │
│   ├── product_categories_controller.rb ← EXISTE (dans AdminPanel) → À adapter pour hiérarchie
│   │                                     OU créer categories_controller.rb après migration
│   ├── product_templates_controller.rb  ← NEW: Templates réutilisables
│   ├── option_sets_controller.rb        ← NEW: Ensembles d'options
│   │
│   ├── products_controller.rb           ← REFACTOR: Seulement produit (existe déjà dans AdminPanel)
│   ├── product_variants_controller.rb   ← EXISTE (dans AdminPanel) → À adapter pour GRID
│   │                                     OU créer variants_controller.rb après migration
│   │                                     Images : Utiliser Active Storage directement
│   │
│   ├── inventory_controller.rb          ← NEW: Tracking stock
│   ├── orders_controller.rb             ← REFACTOR: Orders workflow
│   └── exports_controller.rb            ← NEW: Exports/Imports
│
├── views/admin/
│   ├── dashboard/
│   │   ├── index.html.erb              ← Overview KPIs
│   │   └── _stats.html.erb
│   │
│   ├── categories/
│   │   ├── index.html.erb              ← Tree view hiérarchique
│   │   ├── new.html.erb
│   │   ├── edit.html.erb
│   │   └── _form.html.erb
│   │
│   ├── products/
│   │   ├── index.html.erb              ← Tableau SIMPLE (pas de variantes ici)
│   │   ├── new.html.erb                ← Sélectionner template
│   │   ├── edit.html.erb               ← Infos produit uniquement
│   │   ├── show.html.erb               ← Preview produit
│   │   └── _form.html.erb
│   │
│   ├── product_variants/               ← EXISTE (dans AdminPanel) → À adapter pour GRID
│   │   ├── index.html.erb              ← ADAPTER: Transformer en GRID éditeur (Shopify-like)
│   │   ├── bulk_edit.html.erb          ← NOUVEAU: Édition en masse
│   │   ├── new.html.erb                ← EXISTE
│   │   ├── edit.html.erb               ← EXISTE
│   │   └── _grid_row.html.erb          ← NOUVEAU: Row éditable inline
│   │
│   │   OU après migration :
│   ├── variants/                       ← NOUVEAU (après renommage)
│   │   ├── index.html.erb              ← GRID éditeur (Shopify-like)
│   │   ├── bulk_edit.html.erb          ← Édition en masse
│   │   └── _grid_row.html.erb          ← Row éditable inline
│   │
│   │   Images : Utiliser Active Storage directement (pas besoin de variant_images/)
│   │
│   ├── inventory/
│   │   ├── index.html.erb              ← Dashboard stock
│   │   ├── transfers.html.erb          ← Mouvements stock
│   │   └── _history.html.erb
│   │
│   └── shared/
│       ├── _sidebar.html.erb           ← Navigation
│       ├── _breadcrumb.html.erb
│       ├── _pagination.html.erb
│       └── _alerts.html.erb
│
├── models/
│   ├── category.rb                     ← NEW: Avec acts-as-tree (renommé depuis product_categories)
│   ├── product_template.rb             ← NEW: Blueprint réutilisable
│   ├── option_set.rb                   ← NEW: Groupe d'options
│   ├── option_set_option_type.rb       ← NEW: Join table
│   ├── option_type.rb                  ← REFACTOR: Linked à option_sets (via join table)
│   ├── option_value.rb                 ← EXISTE (pas de changement)
│   │
│   ├── product.rb                      ← REFACTOR: Ajouter product_template_id
│   ├── product_variant.rb              ← EXISTE (à renommer en variant.rb après migration)
│   │                                     OU adapter code pour utiliser product_variants
│   │                                     Images : Active Storage (has_many_attached :images)
│   │
│   ├── inventory.rb                    ← NEW: Tracking stock (migrer depuis product_variants.stock_qty)
│   ├── inventory_movement.rb           ← NEW: Historique
│   │
│   ├── order.rb                        ← EXISTE (pas de changement majeur)
│   ├── order_item.rb                   ← EXISTE (variant_id référence product_variants → à mettre à jour)
│   └── user.rb                         ← EXISTE (pas de changement)
│
├── services/
│   ├── variant_generator.rb            ← REFACTOR: Smart SKU
│   ├── inventory_service.rb            ← NEW: Calculs stock
│   ├── product_exporter.rb             ← NEW: CSV/Excel
│   ├── product_importer.rb             ← NEW: Import CSV
│   ├── pricing_service.rb              ← NEW: Règles prix
│   └── audit_service.rb                ← NEW: Historique
│
├── policies/admin/
│   ├── product_policy.rb
│   ├── variant_policy.rb               ← NEW
│   ├── category_policy.rb              ← NEW
│   └── inventory_policy.rb             ← NEW
│
├── javascript/controllers/admin/
│   ├── sidebar_controller.js           ← NEW: Navigation active
│   ├── product_form_controller.js      ← REFACTOR: Seulement produit
│   ├── variants_grid_controller.js     ← NEW: Édition inline grid
│   ├── variant_images_controller.js    ← NEW: Galerie
│   ├── inventory_controller.js         ← NEW: Stock transfers
│   ├── bulk_edit_controller.js         ← NEW: Édition en masse
│   ├── preview_controller.js           ← NEW: Live preview
│   └── search_controller.js            ← NEW: Recherche smart
│
└── helpers/admin/
    ├── categories_helper.rb            ← NEW
    ├── products_helper.rb              ← REFACTOR
    ├── variants_helper.rb              ← NEW
    └── inventory_helper.rb             ← NEW
🏗️ MODÈLES DATA - STRUCTURE ADAPTÉE À LA BASE ACTUELLE

> ⚠️ **NOTE IMPORTANTE** : Cette architecture nécessite des migrations pour adapter la structure existante.  
> Voir `docs/development/admin-panel/incoherences-schema-refonte.md` pour les détails complets.

### 📋 MIGRATIONS PRÉALABLES REQUISES

Avant d'implémenter cette architecture, les migrations suivantes sont nécessaires :

1. **Renommer `product_categories` → `categories`** + ajouter `parent_id` et `is_active`
2. **Renommer `product_variants` → `variants`** (ou adapter le code pour utiliser `product_variants`)
3. **Créer `product_templates`**, `option_sets`, `inventories`, `inventory_movements`
4. **Migrer `stock_qty`** de `product_variants` vers `inventories`
5. **Migrer `image_url`** vers Active Storage (recommandé)

---

1️⃣ CATEGORIES (Hiérarchique) - **ADAPTÉ**

> ⚠️ **Migration requise** : Renommer `product_categories` → `categories` + ajouter `parent_id`

```ruby
# app/models/category.rb
# Table actuelle : product_categories (à renommer en categories)
# Migration : Ajouter parent_id, is_active

class Category < ApplicationRecord
  # Utilise acts_as_tree gem pour hiérarchie
  acts_as_tree order: 'name'
  
  # Relations
  has_many :products, dependent: :nullify, foreign_key: 'category_id'
  has_many :product_templates, dependent: :nullify
  
  # Validations
  validates :name, presence: true, uniqueness: { scope: :parent_id }
  validates :slug, presence: true, uniqueness: true
  
  # Scopes
  scope :roots, -> { where(parent_id: nil) }
  scope :active, -> { where(is_active: true) }
  
  # Helpers
  def display_name
    "#{"─ " * depth}#{name}"
  end
  
  def depth
    ancestors.count
  end
  
  # Migration : Colonnes à ajouter :
  # - parent_id (bigint, nullable)
  # - is_active (boolean, default: true)
end
```
2️⃣ PRODUCT TEMPLATES - **SKIP** ⚠️

> ⚠️ **DÉCISION** : Product Templates sont **SKIP** pour l'instant (overkill pour le cas d'usage actuel).

**Raison** :
- Cas d'usage réel : 3-5 catégories MAX (T-shirts, Casquettes, Vestes)
- Chaque produit a ses propres tailles/couleurs (pas de réutilisation réelle)
- Complexité ajoutée sans valeur immédiate

**Alternative** :
- Créer produit → Sélectionner `option_types` manuellement
- Générer variantes avec `ProductVariantGenerator` (existe déjà)
- Templates = Nice-to-have PLUS TARD (6-12 mois) si besoin réel apparaît

**Si besoin futur** : Voir section "Extensions futures" en fin de document.
3️⃣ OPTION SETS - **SKIP** ⚠️

> ⚠️ **DÉCISION** : Option Sets sont **SKIP** pour l'instant (overkill pour le cas d'usage actuel).

**Raison** :
- Tu as DÉJÀ `option_types` et `option_values` (existants)
- OptionSets = Juste un regroupement d'option_types
- Utilité réelle : Utile si 100+ produits avec mêmes combinaisons
- Cas actuel : 3-5 produits MAX → Overkill

**Alternative** :
- Utiliser `OptionType` directement (existe déjà)
- Sélectionner manuellement les option_types lors de la création produit
- OptionSets = Nice-to-have PLUS TARD (6-12 mois) si besoin réel apparaît

**Si besoin futur** : Voir section "Extensions futures" en fin de document.
4️⃣ PRODUCTS (Entité simple) - **ADAPTÉ**

> ⚠️ **Migration requise** : Ajouter `product_template_id` (nullable)

```ruby
# app/models/product.rb
# Table actuelle : products (existe déjà)
# Colonnes actuelles : id, category_id, name, slug, description, price_cents, currency, stock_qty, image_url, is_active
# Migration : Ajouter product_template_id (nullable)

class Product < ApplicationRecord
  # Relations
  belongs_to :category, class_name: 'ProductCategory'  # Temporaire, deviendra Category après migration
  belongs_to :product_template, optional: true  # NOUVEAU (après migration)
  
  # ⚠️ IMPORTANT : Utiliser product_variants pour l'instant, deviendra variants après migration
  has_many :product_variants, dependent: :destroy, class_name: 'ProductVariant'
  # Après migration : has_many :variants, dependent: :destroy
  
  has_one_attached :image_hero  # Active Storage (déjà configuré)
  
  # Validations
  validates :name, presence: true, length: { maximum: 140 }
  validates :slug, presence: true, uniqueness: true, length: { maximum: 160 }
  validates :category_id, presence: true
  
  # Scopes
  scope :with_associations, -> {
    includes(:category, :product_template, product_variants: [:variant_option_values, :option_values])
    # Après migration : includes(:category, :product_template, variants: :inventory)
  }
  
  # Méthodes stock (adaptées à la structure actuelle)
  def total_stock
    # Actuellement : product_variants.sum(:stock_qty)
    # Après migration : variants.joins(:inventory).sum('inventories.stock_qty')
    product_variants.where(is_active: true).sum(:stock_qty)
  end
  
  def available_stock
    # Après migration : variants.joins(:inventory).sum('inventories.available_qty')
    total_stock  # Simplifié pour l'instant
  end
  
  # Migration : Colonnes à ajouter :
  # - product_template_id (bigint, nullable)
  # Note : stock_qty et image_url peuvent être supprimés après migration vers inventories/Active Storage
end
```
5️⃣ VARIANTS (Entité complète) - **ADAPTÉ**

> ⚠️ **Migration requise** : Renommer `product_variants` → `variants` OU adapter le code pour utiliser `product_variants`

```ruby
# app/models/product_variant.rb (ACTUEL) → app/models/variant.rb (APRÈS MIGRATION)
# Table actuelle : product_variants (existe déjà)
# Colonnes actuelles : id, product_id, sku, price_cents, currency, stock_qty, image_url, is_active
# Migration : Renommer table → variants, créer inventories, migrer stock_qty

# OPTION A : Utiliser ProductVariant pour l'instant (compatibilité)
class ProductVariant < ApplicationRecord
  belongs_to :product
  has_many :variant_option_values, foreign_key: 'variant_id', dependent: :destroy
  has_many :option_values, through: :variant_option_values
  
  # Active Storage pour images (déjà configuré)
  # ⚠️ IMPORTANT : Upload de FICHIERS uniquement (pas de liens image_url)
  has_many_attached :images  # NOUVEAU : Plusieurs images (upload fichiers uniquement)
  
  # ⚠️ TEMPORAIRE : Stock dans la table (sera migré vers inventories)
  # Après migration : has_one :inventory, dependent: :destroy
  
  # ⚠️ Migration : image_url sera supprimé après migration vers Active Storage
  
  validates :sku, presence: true, uniqueness: true,
            format: { with: /\A[A-Z0-9\-]+\z/ }
  validates :product_id, presence: true
  
  scope :active, -> { where(is_active: true) }
  
  # Smart SKU format: PRODUCT-OPTION1-OPTION2
  def smart_sku
    parts = [product.slug.upcase]
    parts += option_values.order(:option_type_id).pluck(:value).map(&:upcase)
    parts.join('-')
  end
  
  # Méthodes stock (adaptées à la structure actuelle)
  def total_stock
    # Actuellement : stock_qty (champ direct)
    # Après migration : inventory.stock_qty
    stock_qty || 0
  end
  
  def available_stock
    # Actuellement : stock_qty (pas de réservation)
    # Après migration : inventory.available_qty
    total_stock  # Simplifié pour l'instant
  end
  
  def reserved_stock
    # Après migration : inventory.reserved_qty
    0  # Pas encore implémenté
  end
  
  def can_fulfill?(quantity)
    available_stock >= quantity
  end
  
  # Callback pour créer inventory après migration
  # after_create :create_inventory_record  # À activer après migration
end

# OPTION B : Après migration (table renommée en variants)
# class Variant < ApplicationRecord
#   # Même code mais table = variants
# end
```
6️⃣ ORDER WORKFLOW - **AMÉLIORÉ** (Stock Reservation/Release)

> ⚠️ **IMPORTANT** : Workflow de réservation/libération du stock lors des changements de statut

```ruby
# app/models/order.rb
# ⚠️ AMÉLIORATION : Ajouter reserve/release stock avec inventories

class Order < ApplicationRecord
  include Hashid::Rails

  belongs_to :user
  belongs_to :payment, optional: true
  has_many :order_items, dependent: :destroy

  # Callbacks pour gérer le stock et les notifications
  after_create :reserve_stock  # NOUVEAU : Réserver stock à la création
  after_update :handle_stock_on_status_change, if: :saved_change_to_status?
  after_update :notify_status_change, if: :saved_change_to_status?

  private

  # NOUVEAU : Réserver le stock à la création de la commande
  def reserve_stock
    return unless status == 'pending'
    
    order_items.includes(:variant).each do |item|
      variant = item.variant
      next unless variant
      
      # Après migration vers inventories :
      # variant.inventory.reserve_stock(item.quantity, self.id)
      
      # TEMPORAIRE : Vérifier stock disponible
      if variant.stock_qty >= item.quantity
        # Stock sera réservé via inventories après migration
        Rails.logger.info "Stock réservé pour variant #{variant.id}: #{item.quantity}"
      else
        Rails.logger.warn "Stock insuffisant pour variant #{variant.id}"
      end
    end
  end

  # AMÉLIORÉ : Gérer stock selon changement de statut
  def handle_stock_on_status_change
    previous_status = attribute_was(:status) || status_before_last_save
    current_status = status
    
    return unless previous_status.present? && previous_status != current_status

    case current_status
    when 'paid', 'preparation'
      # Stock déjà réservé, rien à faire
      Rails.logger.info "Commande #{id} : Stock déjà réservé"
      
    when 'shipped'
      # Déduire définitivement du stock
      order_items.includes(:variant).each do |item|
        variant = item.variant
        next unless variant
        
        # Après migration vers inventories :
        # variant.inventory.move_stock(-item.quantity, 'order_fulfilled', self.id)
        # variant.inventory.release_stock(item.quantity, self.id)
        
        # TEMPORAIRE : Décrémenter stock directement
        variant.decrement!(:stock_qty, item.quantity)
        Rails.logger.info "Stock déduit pour variant #{variant.id}: #{item.quantity}"
      end
      
    when 'cancelled', 'refunded'
      # Libérer le stock réservé
      order_items.includes(:variant).each do |item|
        variant = item.variant
        next unless variant
        
        # Après migration vers inventories :
        # variant.inventory.release_stock(item.quantity, self.id)
        
        # TEMPORAIRE : Remettre en stock
        variant.increment!(:stock_qty, item.quantity)
        Rails.logger.info "Stock libéré pour variant #{variant.id}: #{item.quantity}"
      end
    end
  end

  # Existant : Notification email
  def notify_status_change
    # ... code existant ...
  end
end
```

7️⃣ INVENTORY (Tracking stock) - **NOUVEAU**

> ⚠️ **Migration requise** : Créer table `inventories` + migrer `stock_qty` depuis `product_variants`

```ruby
# app/models/inventory.rb
# Table : inventories (À CRÉER)
# Migration : Créer table + migrer stock_qty depuis product_variants.stock_qty

class Inventory < ApplicationRecord
  # ⚠️ Après migration : belongs_to :variant
  # Pour l'instant : belongs_to :product_variant, foreign_key: 'variant_id', class_name: 'ProductVariant'
  
  belongs_to :product_variant, foreign_key: 'variant_id', class_name: 'ProductVariant'  # TEMPORAIRE
  # Après migration : belongs_to :variant
  
  has_many :movements, class_name: 'InventoryMovement', dependent: :destroy
  
  validates :variant_id, presence: true, uniqueness: true
  validates :stock_qty, numericality: { greater_than_or_equal_to: 0 }
  
  # stock_qty: Quantité totale (migré depuis product_variants.stock_qty)
  # reserved_qty: Réservée en commandes (nouveau, initialisé à 0)
  # available_qty: Calculé = stock_qty - reserved_qty
  
  def available_qty
    stock_qty - reserved_qty
  end
  
  def move_stock(quantity, reason, reference = nil)
    movements.create!(
      quantity: quantity,
      reason: reason,
      reference: reference,
      before_qty: stock_qty,
      user_id: Current.user&.id
    )
    
    update_column(:stock_qty, stock_qty + quantity)
    # Audit log via audit_logs table (existe déjà)
  end
  
  def reserve_stock(quantity, order_id)
    move_stock(0, 'reserved', order_id)
    increment!(:reserved_qty, quantity)
  end
  
  def release_stock(quantity, order_id)
    move_stock(0, 'released', order_id)
    decrement!(:reserved_qty, quantity)
  end
  
  # Migration : Script de migration
  # ProductVariant.find_each do |pv|
  #   Inventory.create!(
  #     variant_id: pv.id,
  #     stock_qty: pv.stock_qty,
  #     reserved_qty: 0
  #   )
  # end
end
```
7️⃣ INVENTORY MOVEMENTS (Audit)
ruby
# app/models/inventory_movement.rb
class InventoryMovement < ApplicationRecord
  belongs_to :inventory
  belongs_to :user, optional: true
  
  REASONS = %w[
    initial_stock
    purchase
    adjustment
    damage
    loss
    return
    reserved
    released
    order_fulfilled
  ].freeze
  
  validates :reason, inclusion: { in: REASONS }
  
  scope :recent, -> { order(created_at: :desc) }
end
🎨 VUES - LAYOUT SHOPIFY-LIKE
LAYOUT PRINCIPAL
text
<!-- app/views/layouts/admin.html.erb -->
<!DOCTYPE html>
<html>
<head>
  <title>Admin Panel - Grenoble Roller</title>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  
  <!-- Bootstrap 5.3 -->
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
  
  <!-- Bootstrap Icons -->
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
  
  <%= stylesheet_link_tag "admin", "data-turbo-track": "reload" %>
  <%= javascript_importmap_tags %>
</head>

<body>
  <div class="d-flex min-vh-100">
    <!-- SIDEBAR -->
    <%= render 'admin/shared/sidebar' %>
    
    <!-- MAIN CONTENT -->
    <main class="flex-grow-1 overflow-hidden d-flex flex-column">
      <!-- TOPBAR -->
      <%= render 'admin/shared/topbar', user: current_user %>
      
      <!-- CONTENT AREA -->
      <div class="flex-grow-1 overflow-y-auto bg-light p-4">
        <!-- BREADCRUMB -->
        <%= render 'admin/shared/breadcrumb' %>
        
        <!-- ALERTS -->
        <%= render 'admin/shared/alerts' %>
        
        <!-- PAGE CONTENT -->
        <%= yield %>
      </div>
    </main>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
SIDEBAR (Navigation)
text
<!-- app/views/admin/shared/_sidebar.html.erb -->
<aside class="sidebar bg-dark text-white p-3" style="width: 250px; min-height: 100vh;">
  <!-- LOGO -->
  <div class="mb-4">
    <h5 class="mb-0">
      <i class="bi bi-gear-fill"></i> Admin Panel
    </h5>
    <small class="text-muted">Grenoble Roller</small>
  </div>

  <!-- NAVIGATION -->
  <nav class="nav flex-column gap-2" data-controller="sidebar">
    <!-- Dashboard -->
    <a href="<%= admin_dashboard_path %>" 
       class="nav-link <%= 'active' if current_page?(admin_dashboard_path) %>">
      <i class="bi bi-speedometer2"></i> Dashboard
    </a>

    <!-- Products Section -->
    <span class="nav-section-title text-muted small text-uppercase mt-4 mb-2">
      <i class="bi bi-box-seam"></i> Produits
    </span>
    
    <a href="<%= admin_categories_path %>" 
       class="nav-link <%= 'active' if current_page?(admin_categories_path) %>">
      <i class="bi bi-tags"></i> Catégories
    </a>
    
    <a href="<%= admin_products_path %>" 
       class="nav-link <%= 'active' if current_page?(admin_products_path) %>">
      <i class="bi bi-bag"></i> Produits
    </a>
    
    <a href="<%= admin_variants_path %>" 
       class="nav-link <%= 'active' if current_page?(admin_variants_path) %>">
      <i class="bi bi-collection"></i> Variantes
    </a>
    
    <a href="<%= admin_product_templates_path %>" 
       class="nav-link <%= 'active' if current_page?(admin_product_templates_path) %>">
      <i class="bi bi-file-earmark-check"></i> Templates
    </a>

    <!-- Sales Section -->
    <span class="nav-section-title text-muted small text-uppercase mt-4 mb-2">
      <i class="bi bi-graph-up"></i> Ventes
    </span>
    
    <a href="<%= admin_orders_path %>" 
       class="nav-link <%= 'active' if current_page?(admin_orders_path) %>">
      <i class="bi bi-cart-check"></i> Commandes
    </a>

    <!-- Inventory Section -->
    <span class="nav-section-title text-muted small text-uppercase mt-4 mb-2">
      <i class="bi bi-boxes"></i> Stock
    </span>
    
    <a href="<%= admin_inventory_path %>" 
       class="nav-link <%= 'active' if current_page?(admin_inventory_path) %>">
      <i class="bi bi-graph-up-arrow"></i> Inventaire
    </a>

    <!-- Settings Section -->
    <span class="nav-section-title text-muted small text-uppercase mt-4 mb-2">
      <i class="bi bi-sliders"></i> Paramètres
    </span>
    
    <a href="<%= admin_settings_path %>" 
       class="nav-link <%= 'active' if current_page?(admin_settings_path) %>">
      <i class="bi bi-sliders"></i> Paramètres
    </a>
  </nav>

  <!-- USER -->
  <div class="mt-auto pt-3 border-top">
    <div class="d-flex align-items-center gap-2">
      <img src="<%= current_user.avatar_url %>" class="rounded-circle" style="width: 40px; height: 40px;">
      <div>
        <small class="d-block"><%= current_user.name %></small>
        <%= link_to 'Logout', destroy_user_session_path, method: :delete, class: 'text-muted text-decoration-none small' %>
      </div>
    </div>
  </div>
</aside>
PRODUCTS INDEX (Liste simple)
text
<!-- app/views/admin/products/index.html.erb -->
<div class="d-flex justify-content-between align-items-center mb-4">
  <h1>Produits</h1>
  <%= link_to '+ Nouveau produit', new_admin_product_path, class: 'btn btn-primary' %>
</div>

<!-- FILTERS -->
<div class="card mb-4">
  <div class="card-body">
    <%= form_with url: admin_products_path, method: :get, local: true, class: 'row g-3' do |f| %>
      <div class="col-md-4">
        <%= f.collection_select :category_id, Category.roots, :id, :name,
            { prompt: 'Toutes catégories' }, class: 'form-select' %>
      </div>
      
      <div class="col-md-4">
        <%= f.search_field :search, placeholder: 'Rechercher...', class: 'form-control' %>
      </div>
      
      <div class="col-md-4">
        <%= f.submit 'Filtrer', class: 'btn btn-secondary' %>
        <%= link_to 'Réinitialiser', admin_products_path, class: 'btn btn-outline-secondary' %>
      </div>
    <% end %>
  </div>
</div>

<!-- PRODUCTS TABLE -->
<div class="card">
  <table class="table table-hover mb-0">
    <thead class="table-light">
      <tr>
        <th>Image</th>
        <th>Nom</th>
        <th>Catégorie</th>
        <th>Variantes</th>
        <th>Stock Total</th>
        <th>Statut</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <% @products.each do |product| %>
        <tr>
          <td>
            <% if product.image_hero.attached? %>
              <%= image_tag product.image_hero, style: 'width: 50px; height: 50px; object-fit: cover; border-radius: 4px;' %>
            <% else %>
              <div class="bg-light p-2 text-center" style="width: 50px; height: 50px; border-radius: 4px;">
                <i class="bi bi-image text-muted"></i>
              </div>
            <% end %>
          </td>
          <td>
            <strong><%= product.name %></strong><br>
            <small class="text-muted"><%= product.slug %></small>
          </td>
          <td><span class="badge bg-light text-dark"><%= product.category.name %></span></td>
          <td>
            <span class="badge bg-info">
              <%= product.variants_count %> variantes
            </span>
          </td>
          <td>
            <% if product.available_stock > 0 %>
              <span class="badge bg-success"><%= product.available_stock %> en stock</span>
            <% else %>
              <span class="badge bg-danger">Rupture</span>
            <% end %>
          </td>
          <td>
            <% if product.is_active %>
              <span class="badge bg-success">Actif</span>
            <% else %>
              <span class="badge bg-secondary">Inactif</span>
            <% end %>
          </td>
          <td>
            <div class="btn-group btn-group-sm">
              <%= link_to admin_product_path(product), class: 'btn btn-outline-info' do %>
                <i class="bi bi-eye"></i>
              <% end %>
              
              <%= link_to edit_admin_product_path(product), class: 'btn btn-outline-warning' do %>
                <i class="bi bi-pencil"></i>
              <% end %>
              
              <%= link_to admin_variants_path(product_id: product.id), class: 'btn btn-outline-primary' do %>
                <i class="bi bi-collection"></i>
              <% end %>
              
              <%= link_to admin_product_path(product), method: :delete, 
                  data: { confirm: 'Confirmer ?' }, class: 'btn btn-outline-danger' do %>
                <i class="bi bi-trash"></i>
              <% end %>
            </div>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>

<%= render 'admin/shared/pagination', pagy: @pagy %>
VARIANTS GRID (Éditeur inline - Shopify-like)
text
<!-- app/views/admin/variants/index.html.erb -->
<div class="d-flex justify-content-between align-items-center mb-4">
  <div>
    <h1><%= link_to @product.name, admin_product_path(@product), class: 'text-dark' %></h1>
    <p class="text-muted mb-0"><%= @product.category.name %> • <%= @product.variants_count %> variantes</p>
  </div>
  
  <div class="btn-group">
    <%= link_to '+ Variante manuelle', new_admin_product_variant_path(@product), class: 'btn btn-primary' %>
    <%= link_to '⚙️ Paramètres', edit_admin_product_path(@product), class: 'btn btn-outline-secondary' %>
  </div>
</div>

<!-- FILTERS -->
<div class="card mb-4">
  <div class="card-body">
    <%= form_with url: admin_product_variants_path(product_id: @product.id), method: :get, local: true, class: 'row g-3' do |f| %>
      <div class="col-md-6">
        <%= f.search_field :search, placeholder: 'Rechercher par SKU...', class: 'form-control' %>
      </div>
      
      <div class="col-md-3">
        <%= f.select :status,
            [['Tous', ''], ['Actifs', 'active'], ['Inactifs', 'inactive']],
            { include_blank: false }, class: 'form-select' %>
      </div>
      
      <div class="col-md-3">
        <%= f.submit 'Filtrer', class: 'btn btn-secondary' %>
      </div>
    <% end %>
  </div>
</div>

<!-- BULK EDIT BAR -->
<div class="alert alert-info mb-4" id="bulk_actions" style="display: none;">
  <div class="d-flex justify-content-between align-items-center">
    <span>
      <input type="checkbox" id="select_all"> 
      <strong id="selected_count">0</strong> variantes sélectionnées
    </span>
    
    <div class="btn-group btn-group-sm">
      <%= link_to 'Modifier en masse', admin_bulk_edit_path(product_id: @product.id), 
          class: 'btn btn-warning', id: 'bulk_edit_btn', disabled: true %>
      <%= link_to 'Dupliquer', '#', class: 'btn btn-info', id: 'bulk_duplicate_btn', disabled: true %>
      <%= link_to 'Supprimer', '#', class: 'btn btn-danger', id: 'bulk_delete_btn', disabled: true, 
          data: { confirm: 'Confirmer ?' } %>
    </div>
  </div>
</div>

<!-- VARIANTS GRID (Éditable) -->
<div class="card" data-controller="variants-grid">
  <div class="table-responsive">
    <table class="table table-hover mb-0" style="font-size: 0.95rem;">
      <thead class="table-light sticky-top">
        <tr>
          <th style="width: 40px;">
            <input type="checkbox" class="form-check-input" id="select_all_checkbox">
          </th>
          <th>SKU</th>
          <th>Options</th>
          <th>Prix</th>
          <th class="text-center" style="width: 150px;">
            <span class="d-block">Stock</span>
            <small class="text-muted">(Dispo / Total)</small>
          </th>
          <th>Images</th>
          <th>Statut</th>
          <th style="width: 120px;">Actions</th>
        </tr>
      </thead>
      <tbody>
        <% @variants.each do |variant| %>
          <%= render 'admin/variants/grid_row', variant: variant %>
        <% end %>
      </tbody>
    </table>
  </div>
</div>

<%= render 'admin/shared/pagination', pagy: @pagy %>

<script>
// Gestion checkbox bulk select
document.getElementById('select_all_checkbox').addEventListener('change', function() {
  const checkboxes = document.querySelectorAll('input[name="variant_ids[]"]');
  checkboxes.forEach(cb => cb.checked = this.checked);
  updateBulkActions();
});

document.querySelectorAll('input[name="variant_ids[]"]').forEach(cb => {
  cb.addEventListener('change', updateBulkActions);
});

function updateBulkActions() {
  const selected = document.querySelectorAll('input[name="variant_ids[]"]:checked').length;
  document.getElementById('bulk_actions').style.display = selected > 0 ? 'block' : 'none';
  document.getElementById('selected_count').textContent = selected;
  document.getElementById('bulk_edit_btn').disabled = selected === 0;
}
</script>
GRID ROW (Éditable inline)
text
<!-- app/views/admin/variants/_grid_row.html.erb -->
<tr class="variant-row" data-variant-id="<%= variant.id %>">
  <td>
    <input type="checkbox" name="variant_ids[]" value="<%= variant.id %>" class="form-check-input">
  </td>
  
  <!-- SKU (Read-only) -->
  <td>
    <code class="user-select-all"><%= variant.sku %></code>
  </td>
  
  <!-- OPTIONS (Badge) -->
  <td>
    <% variant.option_values.each do |ov| %>
      <span class="badge bg-light text-dark">
        <%= ov.option_type.name %>: <%= ov.value %>
      </span>
    <% end %>
  </td>
  
  <!-- PRIX (Éditable inline) -->
  <td data-field="price" class="editable-cell" data-variant-id="<%= variant.id %>">
    <div class="input-group input-group-sm" style="max-width: 120px;">
      <span class="input-group-text">€</span>
      <input type="number" class="form-control form-control-sm text-end" 
             value="<%= variant.price_cents / 100.0 %>" step="0.01"
             data-original="<%= variant.price_cents / 100.0 %>">
    </div>
  </td>
  
  <!-- STOCK (Éditable + Couleur) -->
  <td class="text-center" data-field="stock">
    <div class="d-flex gap-2 align-items-center justify-content-center">
      <!-- Available / Total -->
      <small class="badge bg-<%= variant.available_stock > 0 ? 'success' : 'danger' %>">
        <%= variant.available_stock %> / <%= variant.total_stock %>
      </small>
      
      <!-- Edit btn -->
      <%= link_to '', admin_product_variant_path(@product, variant),
          class: 'btn btn-sm btn-outline-primary bi bi-pencil',
          title: 'Modifier stock' %>
    </div>
  </td>
  
  <!-- IMAGES -->
  <td>
    <% if variant.variant_images.any? %>
      <div class="d-flex gap-1">
        <% variant.variant_images.first(3).each do |img| %>
          <%= image_tag img.image, style: 'width: 30px; height: 30px; object-fit: cover; border-radius: 3px; cursor: pointer;',
              title: 'Voir galerie', data: { action: 'click->variants-grid#showGallery' } %>
        <% end %>
        <% if variant.variant_images.count > 3 %>
          <span class="badge bg-secondary d-flex align-items-center">
            +<%= variant.variant_images.count - 3 %>
          </span>
        <% end %>
      </div>
    <% else %>
      <span class="text-muted small">Aucune image</span>
    <% end %>
  </td>
  
  <!-- STATUT (Toggle) -->
  <td>
    <div class="form-check form-switch m-0">
      <%= check_box_tag "variant_status_#{variant.id}", 1, variant.is_active,
          class: 'form-check-input', data: { action: 'change->variants-grid#toggleStatus', 
          variant_id: variant.id } %>
    </div>
  </td>
  
  <!-- ACTIONS -->
  <td>
    <div class="btn-group btn-group-sm">
      <%= link_to admin_product_variant_path(@product, variant),
          class: 'btn btn-outline-info', title: 'Voir détails' do %>
        <i class="bi bi-eye"></i>
      <% end %>
      
      <%= link_to edit_admin_product_variant_path(@product, variant),
          class: 'btn btn-outline-warning', title: 'Modifier' do %>
        <i class="bi bi-pencil"></i>
      <% end %>
      
      <%= link_to admin_product_variant_path(@product, variant), method: :delete,
          data: { confirm: 'Confirmer ?' }, class: 'btn btn-outline-danger', title: 'Supprimer' do %>
        <i class="bi bi-trash"></i>
      <% end %>
    </div>
  </td>
</tr>
🔄 CONTROLLERS - ARCHITECTURE SÉPARÉE
1️⃣ Products Controller (SIMPLIFIÉ) - **ADAPTÉ**

> ⚠️ **Note** : Le controller existe déjà dans `AdminPanel::ProductsController` → À adapter

```ruby
# app/controllers/admin_panel/products_controller.rb
# EXISTE DÉJÀ → À adapter pour la nouvelle architecture

module AdminPanel
  class ProductsController < BaseController
    include Pagy::Backend
    
    before_action :set_product, only: %i[show edit update destroy]
    before_action :authorize_product, only: %i[show edit update destroy]
    
    def index
      authorize [:admin_panel, Product]
      
      @products = Product
        .with_associations  # Scope existe déjà
        .by_category(params[:category_id])  # Scope à adapter
        .search_by_name(params[:search])  # Scope existe déjà
        .order(created_at: :desc)
      
      @pagy, @products = pagy(@products, items: 25)
    end
    
    def show
      # ⚠️ ADAPTER : Utiliser product_variants pour l'instant
      @variants_count = @product.product_variants.count
      # Après migration : @product.variants_count
    end
    
    def new
      @product = Product.new
      @categories = ProductCategory.order(:name)  # TEMPORAIRE
      # Après migration : Category.roots
      @option_types = OptionType.includes(:option_values).order(:name)
      
      authorize [:admin_panel, @product]
    end
    
    def create
      @product = Product.new(product_params)
      authorize [:admin_panel, @product]
      
      if @product.save
        redirect_to admin_panel_product_path(@product), notice: 'Produit créé'
      else
        @categories = ProductCategory.order(:name)
        @option_types = OptionType.includes(:option_values).order(:name)
        render :new, status: :unprocessable_entity
      end
    end
    
    def edit
      @categories = ProductCategory.order(:name)  # TEMPORAIRE
      @option_types = OptionType.includes(:option_values).order(:name)
    end
    
    def update
      if @product.update(product_params)
        redirect_to admin_panel_product_path(@product), notice: 'Produit mis à jour'
      else
        @categories = ProductCategory.order(:name)
        @option_types = OptionType.includes(:option_values).order(:name)
        render :edit, status: :unprocessable_entity
      end
    end
    
    def destroy
      @product.destroy
      redirect_to admin_panel_products_url, notice: 'Produit supprimé'
    end
    
    private
    
    def set_product
      @product = Product.find(params[:id])
    end
    
    def authorize_product
      authorize [:admin_panel, @product]
    end
    
    def product_params
      params.require(:product).permit(
        :category_id,
        # ⚠️ product_template_id SKIP pour l'instant
        :name,
        :slug,
        :description,
        :price_cents,  # Garder price_cents (existe déjà)
        :currency,
        :is_active,
        :images  # Active Storage (upload fichiers uniquement, pas de liens)
      )
    end
  end
end
```
2️⃣ Variants Controller - **ADAPTÉ**

> ⚠️ **Note** : Le controller existe déjà dans `AdminPanel::ProductVariantsController` → À adapter pour GRID

```ruby
# app/controllers/admin_panel/product_variants_controller.rb
# EXISTE DÉJÀ → À adapter pour GRID éditeur + bulk edit

module AdminPanel
  class ProductVariantsController < BaseController
    before_action :set_product
    before_action :set_variant, only: %i[show edit update destroy]
    
    # ⚠️ ADAPTER : Ajouter action index pour GRID
    def index
      # Route pour afficher le GRID éditeur de toutes les variantes d'un produit
      @variants = @product.product_variants
        .includes(:option_values, :variant_option_values)
        .order(:sku)
      
      # Après migration : .includes(:option_values, :inventory)
      
      @pagy, @variants = pagy(@variants, items: 50)
    end
    
    def show
      # ⚠️ ADAPTER : Utiliser Active Storage pour images
      @images = @variant.images.attached? ? @variant.images : []
      # Après migration : @inventory = @variant.inventory
      # @movements = @variant.inventory&.movements&.recent || []
    end
    
    def new
      @variant = @product.product_variants.build
      @option_types = OptionType.includes(:option_values).order(:name)
      # Après migration : @product.product_template&.option_types || []
    end
    
    def create
      @variant = @product.product_variants.build(variant_params)
      
      if @variant.save
        redirect_to admin_panel_product_path(@product), notice: 'Variante créée'
      else
        @option_types = OptionType.includes(:option_values).order(:name)
        render :new, status: :unprocessable_entity
      end
    end
    
    def edit
      @option_types = OptionType.includes(:option_values).order(:name)
    end
    
    def update
      if @variant.update(variant_params)
        redirect_to admin_panel_product_path(@product), notice: 'Variante mise à jour'
      else
        @option_types = OptionType.includes(:option_values).order(:name)
        render :edit, status: :unprocessable_entity
      end
    end
    
    def destroy
      @variant.destroy
      redirect_to admin_panel_product_path(@product), notice: 'Variante supprimée'
    end
    
    # BULK EDIT - NOUVEAU
    def bulk_edit
      @variant_ids = params[:variant_ids] || []
      @variants = @product.product_variants.where(id: @variant_ids)
    end
    
    def bulk_update
      variant_ids = params[:variant_ids] || []
      updates = params[:updates] || {}
      
      @product.product_variants.where(id: variant_ids).each do |variant|
        variant.update(updates.permit(:price_cents, :stock_qty, :is_active)) if updates.present?
      end
      
      redirect_to admin_panel_product_product_variants_path(@product), 
                  notice: "#{variant_ids.count} variantes mises à jour"
    end
    
    # TOGGLE STATUS - NOUVEAU
    def toggle_status
      @variant.update(is_active: !@variant.is_active)
      render json: { success: true, is_active: @variant.is_active }
    end
    
    private
    
    def set_product
      @product = Product.find(params[:product_id])
    end
    
    def set_variant
      @variant = @product.product_variants.find(params[:id])
    end
    
    def variant_params
      params.require(:product_variant).permit(
        :sku,
        :price_cents,
        :currency,
        :stock_qty,  # TEMPORAIRE (sera dans inventories après migration)
        :is_active,
        :images  # Active Storage (upload fichiers uniquement, pas de liens)
        option_value_ids: []  # ADAPTÉ : Utiliser option_value_ids directement
      )
    end
  end
end
```
3️⃣ Inventory Controller - **NOUVEAU** (À créer)

> ⚠️ **Note** : Controller à créer dans `AdminPanel::InventoryController`

```ruby
# app/controllers/admin_panel/inventory_controller.rb
# NOUVEAU → À créer

module AdminPanel
  class InventoryController < BaseController
    def index
      authorize [:admin_panel, Inventory]
      
      # ⚠️ ADAPTER : Utiliser product_variants pour l'instant
      # Après migration : Variant.joins(:inventory)
      
      @low_stock = ProductVariant
        .where('stock_qty <= ?', 10)
        .where(is_active: true)
        .order(:stock_qty)
      
      @out_of_stock = ProductVariant
        .where('stock_qty <= 0')
        .where(is_active: true)
      
      # Après migration :
      # @low_stock = Variant.joins(:inventory)
      #   .where('inventories.available_qty <= ?', 10)
      #   .order('inventories.available_qty ASC')
      #
      # @inventory_movements = InventoryMovement.recent.limit(50)
    end
    
    def transfers
      # ⚠️ À implémenter après création de inventory_movements
      @movements = InventoryMovement
        .recent
        .includes(:inventory, :user)
        .limit(50)
      
      @pagy, @movements = pagy(@movements, items: 25)
    end
    
    def adjust_stock
      # ⚠️ ADAPTER : Utiliser product_variants pour l'instant
      variant = ProductVariant.find(params[:variant_id])
      quantity = params[:quantity].to_i
      reason = params[:reason]
      
      # Temporaire : Mise à jour directe
      variant.update(stock_qty: variant.stock_qty + quantity)
      
      # Après migration : variant.inventory.move_stock(quantity, reason)
      
      redirect_back notice: 'Stock ajusté'
    end
  end
end
```
🔌 JAVASCRIPT CONTROLLERS
Variants Grid Controller
javascript
// app/javascript/controllers/admin_panel/product_variants_grid_controller.js
// ⚠️ ADAPTÉ : Utilise product_variants (existant) au lieu de variants

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editableCell", "variantRow"]
  static values = { productId: Number }
  
  connect() {
    this.initInlineEditing()
    this.initBulkSelect()
  }
  
  // Édition inline des cellules
  initInlineEditing() {
    this.editableCellTargets.forEach(cell => {
      cell.addEventListener('click', (e) => {
        if (e.target.tagName === 'INPUT') return
        this.makeEditable(cell)
      })
      
      const input = cell.querySelector('input')
      if (input) {
        input.addEventListener('blur', () => this.saveCell(cell))
        input.addEventListener('keydown', (e) => {
          if (e.key === 'Enter') this.saveCell(cell)
          if (e.key === 'Escape') this.cancelEdit(cell)
        })
      }
    })
  }
  
  makeEditable(cell) {
    cell.classList.add('editing')
    const input = cell.querySelector('input')
    input?.focus()
  }
  
  // ⚠️ AMÉLIORÉ : Validation, debounce, optimistic locking
  async saveCell(cell) {
    const variantId = cell.dataset.variantId
    const field = cell.dataset.field
    const newValue = cell.querySelector('input').value
    const original = cell.querySelector('input').dataset.original
    
    if (newValue === original) {
      this.cancelEdit(cell)
      return
    }
    
    // AJOUT : Validation client
    if (field === 'price_cents' && parseFloat(newValue) <= 0) {
      this.showError('Prix doit être > 0')
      this.cancelEdit(cell)
      return
    }
    
    if (field === 'stock_qty' && parseInt(newValue) < 0) {
      this.showError('Stock ne peut pas être négatif')
      this.cancelEdit(cell)
      return
    }
    
    // AJOUT : Indicateur de chargement
    cell.classList.add('saving')
    
    try {
      const response = await fetch(
        `/admin-panel/products/${this.productIdValue}/product_variants/${variantId}`,
        {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
          },
          body: JSON.stringify({ product_variant: { [field]: newValue } })
        }
      )
      
      if (response.ok) {
        const data = await response.json()
        
        // AJOUT : Vérifier version (optimistic locking)
        if (data.version && data.version !== cell.dataset.version) {
          alert('Conflit : un autre admin a modifié cette variante. Rechargez la page.')
          this.cancelEdit(cell)
          return
        }
        
        cell.classList.remove('editing', 'saving')
        cell.querySelector('input').dataset.original = newValue
        if (data.version) cell.dataset.version = data.version
        
        // AJOUT : Feedback visuel
        cell.classList.add('saved')
        setTimeout(() => cell.classList.remove('saved'), 2000)
      } else {
        const errors = await response.json()
        this.showError(errors.message || 'Erreur de sauvegarde')
        this.cancelEdit(cell)
      }
    } catch (error) {
      this.showError('Erreur réseau')
      this.cancelEdit(cell)
    } finally {
      cell.classList.remove('saving')
    }
  }
  
  // AJOUT : Debounce pour éviter spam
  saveCell = this.debounce(this.saveCell.bind(this), 500)
  
  debounce(func, wait) {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout)
        func(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }
  
  showError(message) {
    // Afficher message d'erreur (toast, alert, etc.)
    console.error(message)
    // TODO: Implémenter toast notification
  }
  
  cancelEdit(cell) {
    cell.classList.remove('editing')
    const input = cell.querySelector('input')
    input.value = input.dataset.original
  }
  
  // Toggle statut
  async toggleStatus(event) {
    const variantId = event.target.dataset.variantId
    const isActive = event.target.checked
    
    // ⚠️ ADAPTÉ : Route AdminPanel existante
    await fetch(
      `/admin-panel/products/${this.productIdValue}/product_variants/${variantId}/toggle_status`,
      {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ is_active: isActive })
      }
    )
  }
}
📊 FLUX UTILISATEUR REFACTORISÉ
text
┌─────────────────────────────────────────────────────┐
│           ADMIN PANEL SHOPIFY-LIKE                  │
│                                                      │
│  Sidebar Navigation                                  │
│  ├─ Dashboard                                        │
│  ├─ Catégories (Hiérarchique)                        │
│  ├─ Produits (Liste simple)                         │
│  ├─ Variantes (GRID éditeur)                        │
│  ├─ Templates (Réutilisables)                       │
│  ├─ Commandes (Workflow)                            │
│  └─ Inventaire (Tracking)                           │
└─────────────────────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
    ┌────────┐   ┌──────────┐   ┌──────────┐
    │PRODUCTS│   │ VARIANTS │   │INVENTORY │
    │        │   │          │   │          │
    │List    │   │Grid Edit │   │Dashboard │
    │New     │   │Bulk Edit │   │Transfers │
    │Edit    │   │Images    │   │History   │
    └────────┘   └──────────┘   └──────────┘
        │              │              │
        └──────────────┼──────────────┘
                       ▼
        Database (Optimized, Indexed)
📝 FICHIER ROUTES COMPLÈTES - **ADAPTÉ À LA STRUCTURE ACTUELLE**

```ruby
# config/routes.rb
# ⚠️ ADAPTÉ : Utilise AdminPanel namespace existant + routes adaptées

namespace :admin_panel, path: 'admin-panel' do
  root 'dashboard#index'
  
  # Dashboard
  get 'dashboard', to: 'dashboard#index'
  
  # Categories (Hiérarchique) - ADAPTER product_categories existant
  resources :product_categories, path: 'categories' do
    # Routes hiérarchiques à ajouter après migration
  end
  # Après migration : resources :categories
  
  # Products (Simple CRUD) - EXISTE DÉJÀ
  resources :products do
    member do
      post :publish
      post :unpublish
    end
  end
  
  # ⚠️ Product Templates et Option Sets SKIP pour l'instant
  
  # Variants (Nested + Bulk) - ADAPTER product_variants existant
  resources :products do
    resources :product_variants, path: 'variants', except: [:index, :show] do
      collection do
        get :bulk_edit
        patch :bulk_update
        get :index  # Route pour GRID éditeur
      end
      member do
        patch :toggle_status
      end
    end
  end
  # Après migration : resources :variants (si table renommée)
  
  # Images : Utiliser Active Storage directement (pas de routes spécifiques)
  # Ou routes Active Storage si nécessaire
  
  # Inventory - NOUVEAU
  get 'inventory', to: 'inventory#index'
  get 'inventory/transfers', to: 'inventory#transfers'
  patch 'inventory/adjust_stock', to: 'inventory#adjust_stock'
  
  # Orders - EXISTE DÉJÀ (dans AdminPanel)
  resources :orders do
    member do
      patch :change_status
    end
    collection do
      get :export
    end
  end
  
  # Exports/Imports - PARTIELLEMENT EXISTANT
  # Products export existe déjà
  get 'exports/new', to: 'exports#new'
  post 'exports/create', to: 'exports#create'
  post 'imports/create', to: 'imports#create'
  
  # Settings - À CRÉER
  resources :settings, only: [:index, :update]
end
```
✅ CETTE ARCHITECTURE RÉSOUT
✅ Catégories hiérarchiques (Parent-Child)

✅ Produits simples (Infos uniquement)

✅ Variantes centralisées (GRID éditeur)

✅ Inventaire tracké (Mouvements, historique)

✅ Templates réutilisables (Gain de temps)

✅ Édition en masse (Bulk operations)

✅ SKU smart (Auto-généré avec pattern)

✅ Performance optimale (Eager loading, pas N+1)

✅ Images par variante (Galerie complète)

✅ Audit complet (Qui change quoi, quand)

✅ UX Shopify-like (Professionnelle)

---

## 📋 CHECKLIST DE TRAVAIL - REFONTE ARCHITECTURE ADMIN (ADAPTÉE)

> ⚠️ **IMPORTANT** : Cette checklist a été adaptée pour tenir compte de la structure actuelle.  
> Voir `docs/development/admin-panel/incoherences-schema-refonte.md` pour les détails des migrations.

### 🎯 PHASE 1 : FONDATIONS & MODÈLES (Priorité HAUTE)

#### **1.1 Migrations Base de Données** (ADAPTÉES À LA STRUCTURE ACTUELLE)

**Option A : Renommer les tables existantes (RECOMMANDÉ)**
- [ ] Migration 1 : Renommer `product_categories` → `categories` + ajouter `parent_id`, `is_active`
- [ ] Migration 2 : Renommer `product_variants` → `variants` + mettre à jour foreign keys
- [ ] Migration 3 : Créer `product_templates` (nouvelle table)
- [ ] Migration 4 : Créer `option_sets` + `option_set_option_types` (join table)
- [ ] Migration 5 : Créer `template_option_sets` (join table)
- [ ] Migration 6 : Ajouter `product_template_id` à `products` (nullable)
- [ ] Migration 7 : Créer `inventories` + migrer `stock_qty` depuis `variants` (ou `product_variants`)
- [ ] Migration 8 : Créer `inventory_movements` (historique/audit)
- [ ] Migration 9 : Migrer `image_url` vers Active Storage (recommandé) OU créer `variant_images`
- [ ] Migration 10 : Nettoyer colonnes obsolètes (`stock_qty`, `image_url` de `variants`)

**Option B : Adapter le code sans renommer (TEMPORAIRE)**
- [ ] Adapter modèles pour utiliser `product_categories` et `product_variants`
- [ ] Créer nouvelles tables (`product_templates`, `option_sets`, `inventories`)
- [ ] Migrer données progressivement
- [ ] Renommer plus tard si nécessaire

#### **1.2 Modèles Ruby** (ADAPTÉS)

- [ ] **Option A** : Créer `app/models/category.rb` avec `acts_as_tree` (après renommage `product_categories`)
  - **Option B** : Adapter `app/models/product_category.rb` pour ajouter hiérarchie
- [ ] ⚠️ **SKIP** : `app/models/product_template.rb` (overkill, à ajouter plus tard si besoin)
- [ ] ⚠️ **SKIP** : `app/models/option_set.rb` (overkill, à ajouter plus tard si besoin)
- [ ] Refactoriser `app/models/product.rb` : adapter relations (sans product_template_id pour l'instant)
- [ ] **Option A** : Créer `app/models/variant.rb` (après renommage `product_variants`)
  - **Option B** : Adapter `app/models/product_variant.rb` pour nouvelle architecture
- [ ] **Images** : Utiliser Active Storage directement (pas besoin de `variant_image.rb`)
  - Ajouter `has_many_attached :images` dans `ProductVariant`/`Variant`
  - ⚠️ **IMPORTANT** : Upload de FICHIERS uniquement (pas de liens `image_url`)
- [ ] Créer `app/models/inventory.rb` avec méthodes `move_stock`, `reserve_stock`
- [ ] Créer `app/models/inventory_movement.rb` avec REASONS
- [ ] ⚠️ **SKIP** : Adapter `app/models/option_type.rb` pour `option_sets` (overkill, utiliser directement)
- [ ] Ajouter scopes et méthodes helper dans tous les modèles

#### **1.3 Services**
- [ ] Refactoriser `app/services/variant_generator.rb` : SKU smart avec pattern
- [ ] Créer `app/services/inventory_service.rb` : calculs stock, réservations
- [ ] Créer `app/services/pricing_service.rb` : règles prix (override/héritage)
- [ ] Créer `app/services/audit_service.rb` : historique complet
- [ ] Améliorer `app/services/product_exporter.rb` : CSV/Excel complet
- [ ] Créer `app/services/product_importer.rb` : Import CSV avec validation

---

### 🎯 PHASE 2 : CONTROLLERS & ROUTES (Priorité HAUTE)

#### **2.1 Controllers Admin** (ADAPTÉS À AdminPanel)

- [ ] Créer `app/controllers/admin_panel/dashboard_controller.rb` (nouveau)
- [ ] Refactoriser `app/controllers/admin_panel/base_controller.rb` : Pundit + common (existe déjà)
- [ ] **Option A** : Créer `app/controllers/admin_panel/categories_controller.rb` (après migration)
  - **Option B** : Adapter `app/controllers/admin_panel/product_categories_controller.rb` pour hiérarchie
- [ ] ⚠️ **SKIP** : `app/controllers/admin_panel/product_templates_controller.rb` (overkill)
- [ ] ⚠️ **SKIP** : `app/controllers/admin_panel/option_sets_controller.rb` (overkill)
- [ ] Refactoriser `app/controllers/admin_panel/products_controller.rb` : SIMPLIFIÉ (existe déjà, à adapter)
- [ ] Adapter `app/controllers/admin_panel/product_variants_controller.rb` : GRID + bulk edit (existe déjà)
  - Ajouter action `index` pour GRID
  - Ajouter `bulk_edit` et `bulk_update`
  - Ajouter `toggle_status`
- [ ] **Images** : Utiliser Active Storage directement (pas besoin de controller séparé)
- [ ] Créer `app/controllers/admin_panel/inventory_controller.rb` : dashboard + transfers (nouveau)
- [ ] Adapter `app/controllers/admin_panel/orders_controller.rb` : workflow complet (existe déjà)
- [ ] Adapter exports dans `ProductsController` et `OrdersController` (existe déjà partiellement)
- [ ] Créer `app/controllers/admin_panel/imports_controller.rb` (nouveau)

#### **2.2 Routes** (ADAPTÉES À AdminPanel)

- [ ] Mettre à jour `config/routes.rb` : namespace `admin_panel` (existe déjà)
- [ ] **Option A** : Routes `categories` hiérarchiques (après migration)
  - **Option B** : Adapter routes `product_categories` existantes
- [ ] Routes `products` simples (CRUD) - **EXISTE DÉJÀ**
- [ ] Adapter routes `product_variants` : ajouter `index`, `bulk_edit`, `bulk_update`, `toggle_status`
- [ ] **Images** : Utiliser Active Storage routes (pas besoin de routes spécifiques)
- [ ] Routes `inventory` (index, transfers, adjust_stock) - **NOUVEAU**
- [ ] Routes `product_templates` + `option_sets` - **NOUVEAU**
- [ ] Routes `exports` / `imports` - **PARTIELLEMENT EXISTANT** (dans products/orders)

#### **2.3 Policies Pundit**
- [ ] Créer `app/policies/admin/product_policy.rb`
- [ ] Créer `app/policies/admin/variant_policy.rb`
- [ ] Créer `app/policies/admin/category_policy.rb`
- [ ] Créer `app/policies/admin/inventory_policy.rb`
- [ ] Créer `app/policies/admin/product_template_policy.rb`

---

### 🎯 PHASE 3 : VUES & LAYOUT (Priorité MOYENNE)

#### **3.1 Layout Principal**
- [ ] Refactoriser `app/views/layouts/admin.html.erb` : Sidebar + Main content
- [ ] Créer `app/views/admin/shared/_sidebar.html.erb` : Navigation Shopify-like
- [ ] Créer `app/views/admin/shared/_topbar.html.erb` : Barre supérieure
- [ ] Créer `app/views/admin/shared/_breadcrumb.html.erb`
- [ ] Créer `app/views/admin/shared/_alerts.html.erb` : Messages flash
- [ ] Créer `app/views/admin/shared/_pagination.html.erb` : Pagy

#### **3.2 Dashboard**
- [ ] Créer `app/views/admin/dashboard/index.html.erb` : KPIs + stats
- [ ] Créer `app/views/admin/dashboard/_stats.html.erb` : Widgets stats

#### **3.3 Catégories**
- [ ] Créer `app/views/admin/categories/index.html.erb` : Tree view hiérarchique
- [ ] Créer `app/views/admin/categories/new.html.erb`
- [ ] Créer `app/views/admin/categories/edit.html.erb`
- [ ] Créer `app/views/admin/categories/_form.html.erb` : Sélection parent

#### **3.4 Produits** (ADAPTÉES)

- [ ] Refactoriser `app/views/admin_panel/products/index.html.erb` : Tableau SIMPLE (existe déjà, à adapter)
- [ ] Adapter `app/views/admin_panel/products/new.html.erb` : Ajouter sélection template (existe déjà)
- [ ] Refactoriser `app/views/admin_panel/products/edit.html.erb` : Infos produit uniquement (existe déjà)
- [ ] Refactoriser `app/views/admin_panel/products/show.html.erb` : Preview produit (existe déjà)
- [ ] Refactoriser `app/views/admin_panel/products/_form.html.erb` : Formulaire simplifié (existe déjà)

#### **3.5 Variantes (GRID Éditeur)** (ADAPTÉES)

- [ ] Créer `app/views/admin_panel/product_variants/index.html.erb` : GRID éditable Shopify-like (nouveau)
  - Ou adapter la vue show du produit pour afficher le GRID
- [ ] Créer `app/views/admin_panel/product_variants/_grid_row.html.erb` : Row éditable inline (nouveau)
- [ ] Créer `app/views/admin_panel/product_variants/bulk_edit.html.erb` : Édition en masse (nouveau)
- [ ] Adapter `app/views/admin_panel/product_variants/new.html.erb` (existe déjà)
- [ ] Adapter `app/views/admin_panel/product_variants/edit.html.erb` (existe déjà)
- [ ] Adapter `app/views/admin_panel/products/show.html.erb` : Afficher variantes en GRID (existe déjà, à transformer)

#### **3.6 Images Variantes** (ADAPTÉES - Active Storage)

- [ ] **Utiliser Active Storage directement** : Pas besoin de vues séparées
- [ ] Adapter formulaires variantes pour `has_many_attached :images`
- [ ] Créer partial `app/views/admin_panel/product_variants/_image_gallery.html.erb` : Galerie avec Active Storage
- [ ] Créer partial `app/views/admin_panel/product_variants/_image_upload.html.erb` : Upload multiple avec Active Storage

#### **3.7 Inventaire**
- [ ] Créer `app/views/admin/inventory/index.html.erb` : Dashboard stock
- [ ] Créer `app/views/admin/inventory/transfers.html.erb` : Mouvements stock
- [ ] Créer `app/views/admin/inventory/_history.html.erb` : Historique

#### **3.8 Templates & Option Sets**
- [ ] Créer `app/views/admin/product_templates/index.html.erb`
- [ ] Créer `app/views/admin/product_templates/_form.html.erb`
- [ ] Créer `app/views/admin/option_sets/index.html.erb`
- [ ] Créer `app/views/admin/option_sets/_form.html.erb`

---

### 🎯 PHASE 4 : JAVASCRIPT & STIMULUS (Priorité MOYENNE)

#### **4.1 Controllers Stimulus** (ADAPTÉS)

- [ ] Créer `app/javascript/controllers/admin_panel/sidebar_controller.js` : Navigation active (nouveau)
- [ ] Refactoriser `app/javascript/controllers/admin_panel/product_form_controller.js` : Seulement produit (existe peut-être)
- [ ] Créer `app/javascript/controllers/admin_panel/product_variants_grid_controller.js` : Édition inline grid (nouveau)
  - Adapter pour utiliser routes `admin_panel` et `product_variants`
- [ ] **Images** : Utiliser Active Storage JavaScript directement (pas besoin de controller séparé)
- [ ] Créer `app/javascript/controllers/admin_panel/inventory_controller.js` : Stock transfers (nouveau)
- [ ] Créer `app/javascript/controllers/admin_panel/bulk_edit_controller.js` : Édition en masse (nouveau)
- [ ] Créer `app/javascript/controllers/admin_panel/preview_controller.js` : Live preview produit (nouveau)
- [ ] Créer `app/javascript/controllers/admin_panel/search_controller.js` : Recherche smart (nouveau)

#### **4.2 Fonctionnalités JavaScript**
- [ ] Édition inline des cellules (prix, stock) dans grid variants
- [ ] Toggle statut variante (AJAX)
- [ ] Bulk select (checkbox all)
- [ ] Drag-drop images variantes
- [ ] Live preview produit (mise à jour temps réel)
- [ ] Recherche smart avec autocomplete

---

### 🎯 PHASE 5 : HELPERS & UTILITAIRES (Priorité BASSE)

#### **5.1 Helpers**
- [ ] Créer `app/helpers/admin/categories_helper.rb` : Tree display
- [ ] Refactoriser `app/helpers/admin/products_helper.rb` : Méthodes simplifiées
- [ ] Créer `app/helpers/admin/variants_helper.rb` : Badges, formats
- [ ] Créer `app/helpers/admin/inventory_helper.rb` : Stock display, mouvements

#### **5.2 CSS & Styles**
- [ ] Créer `app/assets/stylesheets/admin.scss` : Styles sidebar + grid
- [ ] Styles grid variants (édition inline)
- [ ] Styles tree categories
- [ ] Responsive mobile/tablette

---

### 🎯 PHASE 6 : TESTS & VALIDATION (Priorité HAUTE)

#### **6.1 Tests Modèles**
- [ ] Tests `Category` : hiérarchie, scopes
- [ ] Tests `ProductTemplate` : création depuis template
- [ ] Tests `Variant` : SKU smart, validations
- [ ] Tests `Inventory` : mouvements, réservations
- [ ] Tests `InventoryMovement` : audit trail

#### **6.2 Tests Controllers**
- [ ] Tests `ProductsController` : CRUD simplifié
- [ ] Tests `VariantsController` : GRID + bulk edit
- [ ] Tests `InventoryController` : ajustements stock
- [ ] Tests autorisations Pundit

#### **6.3 Tests Services**
- [ ] Tests `VariantGenerator` : SKU smart
- [ ] Tests `InventoryService` : calculs stock
- [ ] Tests `ProductExporter` : CSV/Excel
- [ ] Tests `ProductImporter` : Import validation

---

### 🎯 PHASE 7 : MIGRATION DONNÉES & ROLLOUT (Priorité CRITIQUE)

#### **7.1 Migration Données** (ADAPTÉE À LA STRUCTURE ACTUELLE)

- [ ] **Option A** : Script migration `product_variants` → `variants` (si renommage)
  - **Option B** : Garder `product_variants` et adapter le code
- [ ] Script migration `product_categories` → `categories` + création hiérarchie
- [ ] Script création `inventories` depuis `product_variants.stock_qty` (ou `variants.stock_qty`)
- [ ] Script migration `image_url` vers Active Storage attachments
- [ ] Script création `inventory_movements` initiaux (optionnel, pour historique)
- [ ] Validation données migrées (vérifier `order_items`, `memberships`)

#### **7.2 Documentation**
- [ ] Mettre à jour `admin-panel-strategic-analysis.md`
- [ ] Documenter nouvelle architecture
- [ ] Guide migration pour utilisateurs
- [ ] Guide utilisation nouveaux features

#### **7.3 Déploiement**
- [ ] Tests en staging
- [ ] Backup base de données
- [ ] Migration production
- [ ] Vérification post-migration
- [ ] Formation équipe admin

---

## 📊 ORDRE D'EXÉCUTION RECOMMANDÉ

### **Sprint 1 (Semaine 1) : Fondations**
1. Migrations base de données
2. Modèles Ruby de base
3. Services core (VariantGenerator, InventoryService)

### **Sprint 2 (Semaine 2) : Controllers & Routes**
1. Controllers admin (Products, Variants, Inventory)
2. Routes complètes
3. Policies Pundit

### **Sprint 3 (Semaine 3) : Vues Core**
1. Layout + Sidebar
2. Dashboard
3. Products index/show/edit
4. Variants GRID

### **Sprint 4 (Semaine 4) : Features Avancées**
1. JavaScript Stimulus controllers
2. Bulk edit
3. Images variantes
4. Inventory dashboard

### **Sprint 5 (Semaine 5) : Polish & Tests**
1. Tests complets
2. CSS/UX refinements
3. Documentation
4. Migration données

---

## ⚠️ POINTS D'ATTENTION

- **Migration données** : Tester sur copie DB avant production
- **Performance** : Eager loading partout, éviter N+1
- **UX** : Garder interface simple, ne pas surcharger
- **Backward compatibility** : Vérifier que l'existant fonctionne encore
- **Tests** : Couverture minimale 80% avant déploiement

---

**Date création checklist** : 2025-12-21  
**Estimation totale** : ~5 semaines (1 développeur full-time)  
**Complexité** : ⭐⭐⭐⭐⭐ (Architecture complète)

---

## ⚠️ INCOHÉRENCES SCHEMA IDENTIFIÉES

**📄 Document détaillé** : `docs/development/admin-panel/incoherences-schema-refonte.md`

### **Résumé des incohérences majeures :**

1. **CONFLIT NOMMAGE** : `product_variants` (existant) vs `variants` (proposé)
   - ⚠️ Impact : `order_items`, `memberships`, `variant_option_values` référencent `product_variants`
   - ✅ Solution : Renommer `product_variants` → `variants` (migration)

2. **CONFLIT CATÉGORIES** : `product_categories` (existant) vs `categories` hiérarchiques (proposé)
   - ⚠️ Impact : `products.category_id` référence `product_categories`
   - ✅ Solution : Renommer + ajouter `parent_id` (migration)

3. **STOCK MANQUANT** : `product_variants.stock_qty` vs table `inventories` séparée
   - ⚠️ Impact : Données existantes à migrer
   - ✅ Solution : Créer `inventories` + migrer données

4. **IMAGES** : `product_variants.image_url` vs `variant_images` (multiples)
   - ⚠️ Impact : Une seule image actuellement
   - ✅ Solution : Utiliser Active Storage (déjà configuré) - **RECOMMANDÉ**

5. **TABLES MANQUANTES** :
   - ❌ `product_templates` → À créer
   - ❌ `option_sets` → À créer
   - ❌ `inventory_movements` → À créer

### **📋 Migrations nécessaires : 10 migrations identifiées**

Voir document détaillé `incoherences-schema-refonte.md` pour la checklist complète des migrations.

---

## ✅ RÉSUMÉ DES ADAPTATIONS EFFECTUÉES

### **📝 Modifications principales :**

1. **Modèles adaptés** :
   - ✅ `Category` : Utilise `product_categories` temporairement, avec note pour migration
   - ✅ `Product` : Adapté pour utiliser `product_variants` et `product_categories` existants
   - ✅ `ProductVariant` / `Variant` : Code adapté pour fonctionner avec les deux options (renommage ou non)
   - ✅ `Inventory` : Adapté pour référencer `product_variants` temporairement
   - ✅ Active Storage : Utilisé directement pour les images (pas de table `variant_images`)

2. **Controllers adaptés** :
   - ✅ `AdminPanel::ProductsController` : Utilise les routes et modèles existants
   - ✅ `AdminPanel::ProductVariantsController` : Adapté pour GRID éditeur + bulk edit
   - ✅ `AdminPanel::InventoryController` : Nouveau controller avec adaptation pour structure actuelle
   - ✅ Routes : Toutes adaptées pour utiliser le namespace `admin_panel` existant

3. **Vues adaptées** :
   - ✅ Utilisation d'Active Storage pour les images (pas de vues séparées)
   - ✅ GRID éditeur pour `product_variants` (nouveau)
   - ✅ Adaptation des vues existantes plutôt que création de nouvelles

4. **JavaScript adapté** :
   - ✅ Controllers Stimulus adaptés pour routes `admin_panel`
   - ✅ Utilisation de `product_variants` au lieu de `variants`

### **🎯 Choix stratégiques :**

- **Option A (Recommandée)** : Renommer les tables (`product_categories` → `categories`, `product_variants` → `variants`)
- **Option B (Temporaire)** : Adapter le code pour utiliser les tables existantes, migrer plus tard

### **📚 Documents de référence :**

- `docs/development/admin-panel/incoherences-schema-refonte.md` : Détails complets des migrations
- `db/schema.rb` : Structure actuelle de la base de données
- Ce document : Architecture adaptée à la structure actuelle

---

**Document mis à jour le** : 2025-12-21  
**Version** : 2.1 (Simplifiée selon recommandations d'analyse)

---

## 🚀 EXTENSIONS FUTURES (6-12 mois)

### **Product Templates** (Nice-to-have)
- **Quand** : Si besoin réel de réutiliser des combinaisons d'options
- **Cas d'usage** : 50+ produits avec mêmes combinaisons (Taille + Couleur)
- **Complexité** : Moyenne (table + join tables + UI)

### **Option Sets** (Nice-to-have)
- **Quand** : Si besoin réel de regrouper des option_types
- **Cas d'usage** : 100+ produits avec mêmes ensembles d'options
- **Complexité** : Moyenne (table + join tables + UI)

### **Hiérarchie Catégories** (Nice-to-have)
- **Quand** : Si besoin réel de catégories parent-enfant
- **Cas d'usage** : 20+ catégories nécessitant organisation
- **Complexité** : Faible (ajouter `parent_id` + `acts_as_tree`)

### **GRID Inline Edit Avancé** (Nice-to-have)
- **Quand** : Si besoin réel d'édition inline complexe
- **Améliorations** : Optimistic locking, debounce, validation avancée
- **Complexité** : Élevée (JavaScript + backend)

---

## 📊 ESTIMATION RÉVISÉE

| Phase | Estimation Initiale | Estimation Réaliste | Différence |
|-------|---------------------|---------------------|------------|
| PHASE 1 : Fondations | 1 semaine | 1-2 semaines | +1 semaine (migrations image_url, reserved_qty) |
| PHASE 2 : Controllers | 1 semaine | 1 semaine | OK |
| PHASE 3 : Vues | 1 semaine | 1-2 semaines | +1 semaine (GRID complexe) |
| PHASE 4 : JavaScript | 1 semaine | 1-2 semaines | +1 semaine (debounce, validation) |
| PHASE 5 : Tests | 1 semaine | 1 semaine | OK |
| **TOTAL** | **5 semaines** | **6-8 semaines** | **+1-3 semaines** |

### **Plan Minimal Viable (4 semaines)** - RECOMMANDÉ

**PHASE 1 (Semaine 1) : Migrations essentielles**
- ✅ Categories.parent_id (1 migration)
- ✅ Inventories + InventoryMovements (2 migrations)
- ✅ Migration image_url → Active Storage (1 migration)
- ⚠️ SKIP: ProductTemplate, OptionSets

**PHASE 2 (Semaine 2) : Models + Services**
- ✅ Inventory + InventoryMovement models
- ✅ InventoryService (reserve/release/move)
- ✅ Order workflow (reserve stock on create)
- ✅ ProductVariant : has_many_attached :images (upload fichiers uniquement)

**PHASE 3 (Semaine 3) : Controllers + Vues**
- ✅ InventoryController (dashboard + transfers)
- ✅ ProductVariantsController : GRID simple (pas inline edit v1)
- ✅ Vues index + show adaptées

**PHASE 4 (Semaine 4) : Polish + Tests**
- ✅ Tests Inventory + Order workflow
- ✅ Tests migrations
- ✅ Documentation
- ✅ Déploiement staging

**Résultat** : 80% de la valeur avec 50% du travail.