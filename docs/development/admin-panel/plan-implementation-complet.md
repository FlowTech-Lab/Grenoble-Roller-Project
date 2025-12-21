# 📋 Plan d'Implémentation Complet - Admin Panel Refonte

**Date** : 2025-12-21 | **Version** : 1.0 | **État** : 55% complété

---

## 📊 Vue d'ensemble

| Catégorie | Existant | Prévu | À Faire | % Complété |
|-----------|----------|-------|---------|------------|
| **Controllers** | 5 | 7 | 2 | 71% |
| **Modèles** | 0 | 2 | 2 | 0% |
| **Services** | 3 | 5 | 2 | 60% |
| **Policies** | 3 | 4 | 1 | 75% |
| **Routes** | Partiel | Complet | 3 | ~60% |
| **Vues** | 10 | 20+ | 10+ | ~50% |
| **Migrations** | 0 | 7 | 7 | 0% |
| **TOTAL** | — | — | — | **~55%** |

---

## 🎯 Décisions Stratégiques Finales

### ✅ À GARDER (80% de la valeur)

| Item | Raison | Impact |
|------|--------|--------|
| **Inventories table** | CRUCIAL pour tracking stock | HAUTE |
| **InventoryMovements** | Audit trail essentiel | MOYENNE |
| **Active Storage** | Déjà configuré, optimisé | MOYENNE |
| **GRID éditeur** | UX professionnelle | HAUTE |
| **Order workflow** | Reserve/release stock | HAUTE |

### ⚠️ À SIMPLIFIER (Overkill)

| Item | Raison | Report |
|------|--------|--------|
| **ProductTemplate** | Cas d'usage flou pour 3-5 produits | +6 mois |
| **OptionSets** | Redondant avec option_types existants | +6 mois |
| **acts_as_tree** | Hiérarchie inutile actuellement | +3 mois |

### 🔴 À CORRIGER IMMÉDIATEMENT

1. **ProductVariant** : `has_one_attached :image` → `has_many_attached :images`
2. **ProductVariant** : Valider upload fichiers uniquement (pas de `image_url`)
3. **Order** : Ajouter workflow reserve/release stock
4. **GRID** : Implémenter debounce + validation + optimistic locking

---

## 🔴 PHASE 1 : Fondations & Modèles (Semaine 1)

### Migrations Critiques (3 migrations)

#### Migration 1 : Active Storage pour images

```ruby
# db/migrate/YYYYMMDDHHMMSS_migrate_variant_images_to_active_storage.rb
class MigrateVariantImagesToActiveStorage < ActiveRecord::Migration[8.1]
  def up
    ProductVariant.find_each do |variant|
      next if variant.image_url.blank?
      
      begin
        uri = URI.parse(variant.image_url)
        file = uri.open
        
        variant.images.attach(
          io: file,
          filename: File.basename(uri.path),
          content_type: detect_content_type(uri)
        )
        Rails.logger.info "✅ Migré image variant #{variant.id}"
      rescue => e
        Rails.logger.error "❌ Erreur: #{e.message}"
      end
    end
  end
  
  private
  def detect_content_type(uri)
    ext = File.extname(uri.path).downcase
    case ext
    when '.jpg', '.jpeg' then 'image/jpeg'
    when '.png' then 'image/png'
    when '.gif' then 'image/gif'
    when '.webp' then 'image/webp'
    else 'image/jpeg'
    end
  end
end
```

**Checklist** :
- [ ] Créer migration
- [ ] Exécuter sur copie DB
- [ ] Vérifier images migrées
- [ ] Exécuter en production

---

#### Migration 2 : Table inventories

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_inventories.rb
class CreateInventories < ActiveRecord::Migration[8.1]
  def change
    create_table :inventories do |t|
      t.references :product_variant, null: false, foreign_key: true
      t.integer :stock_qty, default: 0, null: false
      t.integer :reserved_qty, default: 0, null: false
      t.timestamps
    end
    
    add_index :inventories, :product_variant_id, unique: true
  end
end
```

---

#### Migration 3 : Table inventory_movements

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_inventory_movements.rb
class CreateInventoryMovements < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_movements do |t|
      t.references :inventory, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.integer :quantity, null: false
      t.string :reason, null: false
      t.string :reference
      t.integer :before_qty, null: false
      t.timestamps
    end
    
    add_index :inventory_movements, :inventory_id
    add_index :inventory_movements, :created_at
  end
end
```

### Modèles Critiques

#### Modèle Inventory

```ruby
# app/models/inventory.rb
class Inventory < ApplicationRecord
  belongs_to :product_variant
  has_many :movements, class_name: 'InventoryMovement', dependent: :destroy
  
  validates :product_variant_id, presence: true, uniqueness: true
  validates :stock_qty, numericality: { greater_than_or_equal_to: 0 }
  validates :reserved_qty, numericality: { greater_than_or_equal_to: 0 }
  
  def available_qty
    stock_qty - reserved_qty
  end
  
  def move_stock(quantity, reason, reference = nil, user = nil)
    movements.create!(
      quantity: quantity,
      reason: reason,
      reference: reference,
      before_qty: stock_qty,
      user: user
    )
    update_column(:stock_qty, stock_qty + quantity)
  end
  
  def reserve_stock(quantity, order_id)
    increment!(:reserved_qty, quantity)
    movements.create!(
      quantity: 0,
      reason: 'reserved',
      reference: order_id.to_s,
      before_qty: stock_qty,
      user: Current.user
    )
  end
  
  def release_stock(quantity, order_id)
    decrement!(:reserved_qty, quantity)
    movements.create!(
      quantity: 0,
      reason: 'released',
      reference: order_id.to_s,
      before_qty: stock_qty,
      user: Current.user
    )
  end
end
```

#### Modèle InventoryMovement

```ruby
# app/models/inventory_movement.rb
class InventoryMovement < ApplicationRecord
  belongs_to :inventory
  belongs_to :user, optional: true
  
  REASONS = %w[
    initial_stock purchase adjustment damage loss return
    reserved released order_fulfilled
  ].freeze
  
  validates :reason, inclusion: { in: REASONS }
  validates :quantity, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
end
```

#### Modifier ProductVariant

**Modifications clés** :

```ruby
# app/models/product_variant.rb

# AVANT
has_one_attached :image

# APRÈS
has_many_attached :images
has_one :inventory, dependent: :destroy

# Callback
after_create :create_inventory_record

# Validation
validate :image_present

private

def image_present
  return if images.attached?
  errors.add(:base, 'Une image (upload fichier) est requise')
end

def create_inventory_record
  Inventory.create!(
    product_variant: self,
    stock_qty: stock_qty || 0,
    reserved_qty: 0
  )
end
```

#### Modifier Order

**Modifications clés** :

```ruby
# app/models/order.rb

after_create :reserve_stock
after_update :handle_stock_on_status_change, if: :saved_change_to_status?

private

def reserve_stock
  return unless status == 'pending'
  
  order_items.includes(:variant).each do |item|
    variant = item.variant
    next unless variant&.inventory
    variant.inventory.reserve_stock(item.quantity, self.id)
  end
end

def handle_stock_on_status_change
  case status
  when 'shipped'
    order_items.includes(:variant).each do |item|
      variant = item.variant
      next unless variant&.inventory
      variant.inventory.move_stock(-item.quantity, 'order_fulfilled', id, Current.user)
      variant.inventory.release_stock(item.quantity, id)
    end
  when 'cancelled', 'refunded'
    order_items.includes(:variant).each do |item|
      variant = item.variant
      next unless variant&.inventory
      variant.inventory.release_stock(item.quantity, id)
    end
  end
end
```

### Service Inventory

```ruby
# app/services/inventory_service.rb
class InventoryService
  def self.reserve_stock(variant, quantity, order_id)
    inventory = variant.inventory || create_inventory(variant)
    inventory.reserve_stock(quantity, order_id)
  end
  
  def self.release_stock(variant, quantity, order_id)
    return unless variant.inventory
    variant.inventory.release_stock(quantity, order_id)
  end
  
  def self.move_stock(variant, quantity, reason, reference = nil)
    inventory = variant.inventory || create_inventory(variant)
    inventory.move_stock(quantity, reason, reference, Current.user)
  end
  
  def self.available_stock(variant)
    return 0 unless variant.inventory
    variant.inventory.available_qty
  end
  
  private
  
  def self.create_inventory(variant)
    Inventory.create!(
      product_variant: variant,
      stock_qty: variant.stock_qty || 0,
      reserved_qty: 0
    )
  end
end
```

---

## 🟡 PHASE 2 : Controllers & Routes (Semaine 2)

### Controller Inventory

```ruby
# app/controllers/admin_panel/inventory_controller.rb
module AdminPanel
  class InventoryController < BaseController
    before_action :authorize_inventory
    
    def index
      @low_stock = ProductVariant
        .joins(:inventory)
        .where('inventories.available_qty <= ?', 10)
        .where(is_active: true)
        .order('inventories.available_qty ASC')
      
      @out_of_stock = ProductVariant
        .joins(:inventory)
        .where('inventories.available_qty <= 0')
        .where(is_active: true)
      
      @movements = InventoryMovement
        .recent
        .includes(:inventory, :user)
        .limit(50)
    end
    
    def transfers
      @movements = InventoryMovement
        .recent
        .includes(:inventory, :user, inventory: :product_variant)
      
      @pagy, @movements = pagy(@movements, items: 25)
    end
    
    def adjust_stock
      variant = ProductVariant.find(params[:variant_id])
      quantity = params[:quantity].to_i
      reason = params[:reason]
      
      InventoryService.move_stock(variant, quantity, reason, params[:reference])
      
      redirect_back notice: 'Stock ajusté avec succès'
    end
    
    private
    
    def authorize_inventory
      authorize [:admin_panel, Inventory]
    end
  end
end
```

### Adapter ProductVariantsController

**Ajouter actions** :

```ruby
def index
  @product = Product.find(params[:product_id])
  @variants = @product.product_variants.order(sku: :asc)
  @pagy, @variants = pagy(@variants, items: 50)
end

def bulk_edit
  @product = Product.find(params[:product_id])
  @variant_ids = params[:variant_ids] || []
end

def bulk_update
  variant_ids = params[:variant_ids] || []
  updates = params[:variants] || {}
  
  variant_ids.each do |id|
    variant = ProductVariant.find(id)
    variant.update(updates[id]) if updates[id].present?
  end
  
  redirect_to admin_panel_product_product_variants_path, notice: 'Variantes mises à jour'
end

def toggle_status
  @variant = ProductVariant.find(params[:id])
  @variant.update(is_active: !@variant.is_active)
  
  redirect_back notice: "Variante #{@variant.is_active ? 'activée' : 'désactivée'}"
end
```

### Routes

```ruby
# config/routes.rb
namespace :admin_panel, path: 'admin-panel' do
  root 'dashboard#index'
  
  resources :products do
    member do
      post :publish
      post :unpublish
    end
    resources :product_variants do
      collection do
        get :bulk_edit
        patch :bulk_update
      end
      member do
        patch :toggle_status
      end
    end
  end
  
  # Inventory routes
  get 'inventory', to: 'inventory#index'
  get 'inventory/transfers', to: 'inventory#transfers'
  patch 'inventory/adjust_stock', to: 'inventory#adjust_stock'
  
  resources :orders do
    member { patch :change_status }
  end
  
  resources :product_categories
end
```

### Policy Inventory

```ruby
# app/policies/admin_panel/inventory_policy.rb
module AdminPanel
  class InventoryPolicy < BasePolicy
    def index?
      admin_user?
    end
    
    def transfers?
      admin_user?
    end
    
    def adjust_stock?
      admin_user?
    end
  end
end
```

---

## 🟡 PHASE 3 : Vues (Semaine 3-4)

### Vue Inventory Index

```erb
<!-- app/views/admin_panel/inventory/index.html.erb -->
<h1>Inventaire - Dashboard</h1>

<div class="row g-4 mb-4">
  <div class="col-md-4">
    <div class="card">
      <div class="card-body">
        <h5 class="card-title">⚠️ Stock Faible</h5>
        <h2 class="text-warning"><%= @low_stock.count %> produits</h2>
        <small class="text-muted">&lt; 10 unités</small>
      </div>
    </div>
  </div>
  
  <div class="col-md-4">
    <div class="card">
      <div class="card-body">
        <h5 class="card-title">🔴 Rupture</h5>
        <h2 class="text-danger"><%= @out_of_stock.count %> produits</h2>
        <small class="text-muted">0 unité disponible</small>
      </div>
    </div>
  </div>
</div>

<div class="card">
  <div class="card-header">
    <h5 class="mb-0">Mouvements Récents</h5>
  </div>
  <table class="table mb-0">
    <thead class="table-light">
      <tr>
        <th>Produit</th>
        <th>Raison</th>
        <th>Quantité</th>
        <th>Avant</th>
        <th>Date</th>
        <th>Par</th>
      </tr>
    </thead>
    <tbody>
      <% @movements.each do |movement| %>
        <tr>
          <td><%= movement.inventory.product_variant.sku %></td>
          <td><span class="badge bg-info"><%= movement.reason %></span></td>
          <td><%= number_with_precision(movement.quantity, precision: 0) %></td>
          <td><%= movement.before_qty %></td>
          <td><%= l(movement.created_at, format: :short) %></td>
          <td><%= movement.user&.name || 'Système' %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

### Vue Product Variants Index (GRID)

```erb
<!-- app/views/admin_panel/product_variants/index.html.erb -->
<div class="d-flex justify-content-between mb-4">
  <h1><%= @product.name %></h1>
  <%= link_to '+ Variante', new_admin_panel_product_product_variant_path(@product), 
      class: 'btn btn-primary' %>
</div>

<div class="card">
  <table class="table table-hover mb-0" data-controller="admin-variants-grid">
    <thead class="table-light">
      <tr>
        <th style="width: 40px;">
          <input type="checkbox" id="select_all" class="form-check-input">
        </th>
        <th>SKU</th>
        <th>Options</th>
        <th>Prix</th>
        <th>Stock (Dispo/Total)</th>
        <th>Statut</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <% @variants.each do |variant| %>
        <%= render 'grid_row', variant: variant %>
      <% end %>
    </tbody>
  </table>
</div>

<%= render 'shared/pagination', pagy: @pagy %>
```

### Partial Grid Row

```erb
<!-- app/views/admin_panel/product_variants/_grid_row.html.erb -->
<tr class="variant-row" data-variant-id="<%= variant.id %>">
  <td>
    <input type="checkbox" name="variant_ids[]" value="<%= variant.id %>" 
        class="form-check-input variant-checkbox">
  </td>
  
  <td>
    <code><%= variant.sku %></code>
  </td>
  
  <td>
    <% variant.option_values.each do |ov| %>
      <span class="badge bg-light text-dark">
        <%= "#{ov.option_type.name}: #{ov.value}" %>
      </span>
    <% end %>
  </td>
  
  <td>
    <input type="number" class="form-control form-control-sm" style="width: 100px;"
        value="<%= variant.price_cents / 100.0 %>" step="0.01"
        data-field="price" data-variant-id="<%= variant.id %>">
  </td>
  
  <td class="text-center">
    <span class="badge bg-<%= variant.inventory&.available_qty&.> 0 ? 'success' : 'danger' %>">
      <%= variant.inventory&.available_qty || 0 %> / <%= variant.inventory&.stock_qty || 0 %>
    </span>
  </td>
  
  <td>
    <% if variant.is_active %>
      <span class="badge bg-success">Actif</span>
    <% else %>
      <span class="badge bg-secondary">Inactif</span>
    <% end %>
  </td>
  
  <td>
    <div class="btn-group btn-group-sm">
      <%= link_to edit_admin_panel_product_product_variant_path(@product, variant),
          class: 'btn btn-outline-warning' do %>
        <i class="bi bi-pencil"></i>
      <% end %>
      
      <%= link_to admin_panel_product_product_variant_path(@product, variant),
          method: :delete, data: { confirm: 'Confirmer ?' },
          class: 'btn btn-outline-danger' do %>
        <i class="bi bi-trash"></i>
      <% end %>
    </div>
  </td>
</tr>
```

---

## 🟡 PHASE 4 : JavaScript Stimulus (Semaine 4)

### Controller GRID

```javascript
// app/javascript/controllers/admin_panel/product_variants_grid_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectAll", "variantCheckbox", "priceInput"]
  
  connect() {
    this.setupCheckboxes()
    this.setupPriceEditing()
  }
  
  setupCheckboxes() {
    this.selectAllTarget?.addEventListener('change', (e) => {
      this.element.querySelectorAll('.variant-checkbox').forEach(cb => {
        cb.checked = e.target.checked
      })
    })
  }
  
  setupPriceEditing() {
    this.element.querySelectorAll('[data-field="price"]').forEach(input => {
      input.addEventListener('change', () => this.savePrice(input))
    })
  }
  
  savePrice(input) {
    const variantId = input.dataset.variantId
    const newPrice = parseFloat(input.value)
    
    if (newPrice <= 0) {
      alert('Prix doit être > 0')
      return
    }
    
    fetch(`/admin-panel/products/1/product_variants/${variantId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({
        product_variant: { price_cents: newPrice * 100 }
      })
    })
    .then(r => r.ok ? null : alert('Erreur de sauvegarde'))
  }
}
```

---

## ✅ Checklist d'Implémentation

### Phase 1 (Semaine 1) - Priorité HAUTE
- [ ] Migration 1 : Active Storage (image_url)
- [ ] Migration 2 : Inventories table
- [ ] Migration 3 : InventoryMovements table
- [ ] Modèle Inventory + tests
- [ ] Modèle InventoryMovement + tests
- [ ] Modifier ProductVariant (has_many_attached :images + validation)
- [ ] Modifier Order (reserve/release workflow)
- [ ] Service InventoryService

### Phase 2 (Semaine 2) - Priorité HAUTE
- [ ] Controller InventoryController
- [ ] Adapter ProductVariantsController (index, bulk_edit, bulk_update, toggle_status)
- [ ] Adapter ProductsController
- [ ] Ajouter routes inventory (3)
- [ ] Ajouter routes product_variants manquantes
- [ ] Policy InventoryPolicy

### Phase 3 (Semaine 3-4) - Priorité MOYENNE
- [ ] Vue Inventory Index
- [ ] Vue Inventory Transfers
- [ ] Vue ProductVariants Index (GRID)
- [ ] Partial grid_row
- [ ] Adapter formulaires images (has_many_attached)

### Phase 4 (Semaine 4) - Priorité MOYENNE
- [ ] Controller Stimulus GRID
- [ ] Validation client
- [ ] Debounce + optimistic locking

### Phase 5+ (Optionnel) - Priorité BASSE
- [ ] Hiérarchie catégories (parent_id)
- [ ] Renommer tables
- [ ] Importer ProductImporter

---

## 📊 Estimation Révisée

| Phase | Estimation | Temps Réel | Écart |
|-------|-----------|-----------|-------|
| PHASE 1 | 1 sem | 1 sem | ✅ OK |
| PHASE 2 | 1 sem | 1 sem | ✅ OK |
| PHASE 3 | 1 sem | 1-2 sem | ⚠️ +1 |
| PHASE 4 | 1 sem | 1-2 sem | ⚠️ +1 |
| PHASE 5 | 1 sem | 1 sem | ✅ OK |
| **TOTAL** | **5 sem** | **6-8 sem** | **+1-3 sem** |

**Plan Minimal Viable** (80% valeur) : **4 semaines** (Phases 1-2 + vues basiques)

---

## 🎯 Recommandation Finale

**Commencer immédiatement** :

1. ✅ Les 3 migrations (image_url, inventories, inventory_movements)
2. ✅ Modèles Inventory + InventoryMovement
3. ✅ Modifications ProductVariant + Order
4. ✅ Service InventoryService

**En parallèle** :
- Adapter ProductVariantsController (index)
- Créer InventoryController
- Routes inventory

**Résultat après 2 semaines** : Architecture stable + workflow stock complet ✅

---

**Créé le** : 2025-12-21 | **Version** : 1.0
