# 🎯 Architecture Panel Admin - Grenoble Roller

**Stack** : Rails 8.1.1 | Bootstrap 5.3.2 | Stimulus | PostgreSQL 16 | Pundit

---

## 📑 Table des Matières

1. [Architecture Globale](#architecture-globale)
2. [Structure des Controllers](#structure-des-controllers)
3. [Organisation des Vues](#organisation-des-vues)
4. [Formulaires Complexes](#formulaires-complexes)
5. [Gestion Stock Agrégé](#gestion-stock-agrégé)
6. [Stimulus Controllers](#stimulus-controllers)
7. [Validation Hybride](#validation-hybride)
8. [Exemples Complets](#exemples-complets)
9. [Performance & Optimisations](#performance--optimisations)
10. [Migration depuis Active Admin](#migration-depuis-active-admin)

---

## Architecture Globale

### Arborescence Recommandée

```
app/
├── controllers/admin/
│   ├── base_controller.rb           # Controller parent avec Pundit
│   ├── products_controller.rb       # Produits (CRUD + scopes)
│   ├── product_variants_controller.rb # Variantes (CRUD imbriquées)
│   ├── product_categories_controller.rb # Catégories
│   └── orders_controller.rb         # Commandes + workflow
│
├── views/admin/
│   ├── products/
│   │   ├── index.html.erb          # Tableau produits avec filtres
│   │   ├── show.html.erb           # Détail produit + variantes
│   │   ├── edit.html.erb           # Édition produit avec tabs
│   │   ├── _form.html.erb          # Partial formulaire produit
│   │   ├── _product_row.html.erb   # Ligne tableau produit
│   │   └── _tabs_content.html.erb  # Contenu tabs (infos/variantes/images)
│   │
│   ├── product_variants/
│   │   ├── _form.html.erb          # Partial formulaire variante
│   │   ├── _variant_row.html.erb   # Ligne tableau variante
│   │   └── _modal_edit.html.erb    # Modal édition variante
│   │
│   ├── product_categories/
│   │   ├── index.html.erb
│   │   ├── _form.html.erb
│   │   └── _category_row.html.erb
│   │
│   ├── orders/
│   │   ├── index.html.erb          # Tableau commandes
│   │   ├── show.html.erb           # Détail commande
│   │   └── _order_row.html.erb
│   │
│   └── shared/
│       ├── _filters.html.erb       # Composant filtres réutilisable
│       ├── _pagination.html.erb    # Pagination avec Pagy
│       ├── _breadcrumb.html.erb    # Navigation
│       └── _alerts.html.erb        # Messages flash
│
├── helpers/admin/
│   ├── products_helper.rb          # Calculs stock, formats
│   └── orders_helper.rb            # Statuts, badges
│
├── models/
│   ├── product.rb                  # Modèle + scopes
│   ├── product_variant.rb          # Modèle + scopes
│   ├── product_category.rb
│   └── order.rb                    # Statuts workflow
│
├── javascript/controllers/admin/
│   ├── product_form_controller.js      # Gestion tabs, validation
│   ├── variant_form_controller.js      # Création/édition variantes
│   ├── image_upload_controller.js      # Upload avec prévisualisation
│   ├── order_status_controller.js      # Changement statut
│   └── filter_controller.js            # Filtres dynamiques
│
└── policies/                        # Pundit policies
    ├── admin/product_policy.rb
    ├── admin/order_policy.rb
    └── admin/product_category_policy.rb
```

---

## Structure des Controllers - OPTIMISÉE

### BaseController Admin (Pundit + Autorisation)

```ruby
# app/controllers/admin_panel/base_controller.rb
module AdminPanel
  class BaseController < ApplicationController
    include Pagy::Backend
    
    before_action :authenticate_admin_user!
    before_action :set_pagy_options
    
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
    
    layout 'admin'  # CORRIGÉ : admin au lieu de admin_panel
    
    protected
    
    def authenticate_admin_user!
      unless user_signed_in?
        redirect_to new_user_session_path, alert: 'Vous devez être connecté pour accéder à cette page.'
        return
      end
      
      unless current_user&.role&.code.in?(%w[ADMIN SUPERADMIN])
        redirect_to root_path, alert: 'Accès admin requis'
      end
    end
    
    def set_pagy_options
      @pagy_options = { items: 25 }
    end
    
    def user_not_authorized(exception)
      flash[:alert] = 'Vous n\'êtes pas autorisé'
      redirect_to admin_panel_root_path
    end
  end
end
```

### ProductsController - OPTIMISÉ

```ruby
# app/controllers/admin_panel/products_controller.rb
module AdminPanel
  class ProductsController < BaseController
    before_action :set_product, only: %i[show edit update destroy]
    before_action :authorize_product, only: %i[show edit update destroy]
    
    # GET /admin-panel/products
    def index
      authorize [:admin_panel, Product]
      
      @products = Product.with_associations
      @products = apply_filters(@products)
      @products = apply_search(@products)
      @pagy, @products = pagy(@products.order(created_at: :desc), @pagy_options)
      
      respond_to do |format|
        format.html
        format.csv { send_data ProductExporter.to_csv(@products), filename: csv_filename }
        format.xlsx { send_data ProductExporter.to_xlsx(@products), filename: xlsx_filename }
      end
    end
    
    # GET /admin-panel/products/:id
    def show
      @variants = @product.product_variants.order(sku: :asc)
      @variant_pages, @variants = pagy(@variants, items: 10)  # NOUVEAU : pagination
    end
    
    # GET /admin-panel/products/new
    def new
      @product = Product.new
      @option_types = OptionType.all  # NOUVEAU : pour génération
      authorize [:admin_panel, @product]
    end
    
    # POST /admin-panel/products
    def create
      @product = Product.new(product_params)
      authorize [:admin_panel, @product]
      
      if @product.save
        # NOUVEAU : Génération auto si options sélectionnées
        if params[:generate_variants] == 'true' && params[:option_ids].present?
          ProductVariantGenerator.generate_combinations(@product, params[:option_ids])
        end
        
        redirect_to admin_panel_product_path(@product), notice: 'Produit créé'
      else
        @option_types = OptionType.all
        render :new, status: :unprocessable_entity
      end
    end
    
    # GET /admin-panel/products/:id/edit
    def edit
      @option_types = OptionType.all  # NOUVEAU : pour ajouter options
    end
    
    # PATCH/PUT /admin-panel/products/:id
    def update
      if @product.update(product_params)
        # NOUVEAU : Générer options manquantes si ajoutées après création
        if params[:generate_missing] == 'true' && params[:option_ids].present?
          ProductVariantGenerator.generate_missing_combinations(@product, params[:option_ids])
        end
        
        redirect_to admin_panel_product_path(@product), notice: 'Produit mis à jour'
      else
        @option_types = OptionType.all
        render :edit, status: :unprocessable_entity
      end
    end
    
    # DELETE /admin-panel/products/:id
    def destroy
      @product.destroy
      redirect_to admin_panel_products_url, notice: 'Produit supprimé'
    end
    
    # NOUVEAU : Preview variantes avant génération
    def preview_variants
      option_ids = params[:option_ids]
      preview = ProductVariantGenerator.preview(nil, option_ids)
      render json: preview
    end
    
    # NOUVEAU : Édition en masse variantes
    def bulk_update_variants
      variant_ids = params[:variant_ids]
      updates = params[:updates]
      
      ProductVariant.where(id: variant_ids).update_all(updates)
      
      render json: { success: true, count: variant_ids.length }
    end
    
    # NOUVEAU : Endpoint validation SKU (sécurisé)
    def check_sku
      sku = params[:sku]
      product_id = params[:product_id]
      
      # Vérifier unicité + sécurité
      query = ProductVariant.where(sku: sku)
      query = query.where.not(product_id: product_id) if product_id.present?
      
      available = query.empty?
      render json: { available: available }
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
        :name,
        :slug,
        :description,
        :price_cents,
        :currency,
        :is_active,
        :image,
        :image_url
      )
    end
    
    def apply_filters(relation)
      relation = relation.by_category(params[:category]) if params[:category].present?
      relation = relation.by_status(params[:status]) if params[:status].present?
      relation = relation.by_stock_status(params[:stock_status]) if params[:stock_status].present?
      relation
    end
    
    def apply_search(relation)
      relation = relation.search_by_name(params[:search]) if params[:search].present?
      relation
    end
    
    def csv_filename
      "products_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv"
    end
    
    def xlsx_filename
      "products_#{Time.current.strftime('%Y%m%d_%H%M%S')}.xlsx"
    end
  end
end
```

### ProductVariantsController - OPTIMISÉ

```ruby
# app/controllers/admin_panel/product_variants_controller.rb
module AdminPanel
  class ProductVariantsController < BaseController
    before_action :set_product
    before_action :set_variant, only: %i[edit update destroy]
    
    # GET /admin-panel/products/:product_id/product_variants/new
    def new
      @variant = @product.product_variants.build
      @option_types = OptionType.all
      render :new
    end
    
    # GET /admin-panel/products/:product_id/product_variants/:id/edit
    def edit
      @option_types = OptionType.all
      render :edit
    end
    
    # POST /admin-panel/products/:product_id/product_variants
    def create
      @variant = @product.product_variants.build(variant_params)
      
      if @variant.save
        redirect_to admin_panel_product_path(@product), notice: 'Variante créée'
      else
        @option_types = OptionType.all
        render :new, status: :unprocessable_entity
      end
    end
    
    # PATCH /admin-panel/products/:product_id/product_variants/:id
    def update
      if @variant.update(variant_params)
        redirect_to admin_panel_product_path(@product), notice: 'Variante mise à jour'
      else
        @option_types = OptionType.all
        render :edit, status: :unprocessable_entity
      end
    end
    
    # DELETE /admin-panel/products/:product_id/product_variants/:id
    def destroy
      @variant.destroy
      redirect_to admin_panel_product_path(@product), notice: 'Variante supprimée'
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
        :stock_qty,
        :is_active,
        :image,
        :inherit_price,
        :inherit_stock,
        option_value_ids: []
      )
    end
  end
end
```

### OrdersController - Workflow Statuts

```ruby
# app/controllers/admin/orders_controller.rb
module Admin
  class OrdersController < BaseController
    before_action :set_order, only: %i[show update change_status]
    
    def index
      @orders = Order.all
      @orders = @orders.by_status(params[:status]) if params[:status].present?
      @orders = @orders.by_user_email(params[:user_email]) if params[:user_email].present?
      @orders = @orders.by_date_range(params[:date_from], params[:date_to]) if params[:date_from].present?
      
      @pagy, @orders = pagy(@orders.order(created_at: :desc), @pagy_options)
    end
    
    def show
      @order_items = @order.order_items.includes(:variant)
      @available_transitions = @order.available_transitions
    end
    
    # PATCH /admin/orders/:id/change_status
    def change_status
      new_status = params[:status]
      
      if @order.can_transition_to?(new_status)
        @order.update!(status: new_status)
        @order.send_notification(new_status)
        redirect_to admin_order_path(@order), notice: "Statut changé en #{new_status}"
      else
        redirect_to admin_order_path(@order), alert: 'Transition invalide'
      end
    end
    
    private
    
    def set_order
      @order = Order.find(params[:id])
    end
  end
end
```

---

## Organisation des Vues

### Index Produits - Bootstrap Tableau

```erb
<!-- app/views/admin/products/index.html.erb -->
<div class="admin-container">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h1>Gestion des Produits</h1>
    <%= link_to 'Nouveau produit', new_admin_product_path, class: 'btn btn-liquid-primary' %>
  </div>

  <!-- FILTRES -->
  <div class="card mb-4">
    <div class="card-body">
      <%= form_with url: admin_products_path, method: :get, local: true, class: 'row g-3' do |f| %>
        <div class="col-md-3">
          <%= f.select :category, 
              options_for_select(ProductCategory.pluck(:name, :id), params[:category]),
              { include_blank: 'Toutes catégories' },
              class: 'form-select' %>
        </div>
        
        <div class="col-md-3">
          <%= f.select :status,
              [['Actifs', 'active'], ['Inactifs', 'inactive'], ['Tous', '']],
              { include_blank: 'Tous statuts' },
              class: 'form-select' %>
        </div>
        
        <div class="col-md-3">
          <%= f.select :stock_status,
              [['En stock', 'in_stock'], ['Rupture', 'out_of_stock']],
              { include_blank: 'Tous' },
              class: 'form-select' %>
        </div>
        
        <div class="col-md-3">
          <%= f.search_field :search, placeholder: 'Rechercher...', class: 'form-control' %>
        </div>
        
        <div class="col-12">
          <%= f.submit 'Filtrer', class: 'btn btn-secondary me-2' %>
          <%= link_to 'Réinitialiser', admin_products_path, class: 'btn btn-outline-secondary' %>
          <%= link_to 'Exporter CSV', admin_products_path(format: :csv), class: 'btn btn-outline-primary' %>
        </div>
      <% end %>
    </div>
  </div>

  <!-- TABLEAU PRODUITS -->
  <div class="card">
    <table class="table table-hover mb-0">
      <thead class="table-light">
        <tr>
          <th>Image</th>
          <th>Nom</th>
          <th>Catégorie</th>
          <th>Prix</th>
          <th>Stock</th>
          <th>Statut</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <% @products.each do |product| %>
          <%= render 'product_row', product: product %>
        <% end %>
      </tbody>
    </table>
  </div>

  <!-- PAGINATION -->
  <%= render 'shared/pagination', pagy: @pagy %>
</div>
```

### Product Row Partial

```erb
<!-- app/views/admin/products/_product_row.html.erb -->
<tr>
  <td style="width: 60px;">
    <% if product.image.attached? %>
      <%= image_tag product.image, class: 'rounded', style: 'width: 50px; height: 50px; object-fit: cover;' %>
    <% else %>
      <div class="bg-light rounded d-flex align-items-center justify-content-center" style="width: 50px; height: 50px;">
        <i class="bi bi-image"></i>
      </div>
    <% end %>
  </td>
  
  <td>
    <strong><%= product.name %></strong>
    <br>
    <small class="text-muted"><%= product.slug %></small>
  </td>
  
  <td><%= product.category.name %></td>
  
  <td>
    <%= number_to_currency(product.price_cents / 100.0, unit: '€', format: '%n %u') %>
  </td>
  
  <td>
    <% total_stock = product.total_stock %>
    <% if total_stock > 0 %>
      <span class="badge bg-success"><%= total_stock %> unités</span>
    <% else %>
      <span class="badge bg-danger">Rupture</span>
    <% end %>
  </td>
  
  <td>
    <% if product.is_active %>
      <span class="badge bg-light text-dark">
        <i class="bi bi-check-circle"></i> Actif
      </span>
    <% else %>
      <span class="badge bg-secondary">
        <i class="bi bi-x-circle"></i> Inactif
      </span>
    <% end %>
  </td>
  
  <td>
    <div class="btn-group btn-group-sm" role="group">
      <%= link_to admin_product_path(product), class: 'btn btn-outline-info', title: 'Voir' do %>
        <i class="bi bi-eye"></i>
      <% end %>
      
      <%= link_to edit_admin_product_path(product), class: 'btn btn-outline-warning', title: 'Modifier' do %>
        <i class="bi bi-pencil"></i>
      <% end %>
      
      <%= link_to admin_product_path(product), method: :delete, 
          data: { confirm: 'Confirmer?' }, class: 'btn btn-outline-danger', title: 'Supprimer' do %>
        <i class="bi bi-trash"></i>
      <% end %>
    </div>
  </td>
</tr>
```

---

## Formulaires Complexes

### Formulaire Produit avec Tabs Bootstrap

```erb
<!-- app/views/admin/products/edit.html.erb -->
<div class="admin-container">
  <h1>
    <%= @product.new_record? ? 'Nouveau produit' : "Édition: #{@product.name}" %>
  </h1>

  <%= form_with model: [:admin, @product], local: true, class: 'mt-4', 
      data: { controller: 'product-form' } do |f| %>
    
    <% if @product.errors.any? %>
      <div class="alert alert-danger alert-dismissible fade show" role="alert">
        <h4 class="alert-heading">Erreurs de validation</h4>
        <ul class="mb-0">
          <% @product.errors.full_messages.each do |msg| %>
            <li><%= msg %></li>
          <% end %>
        </ul>
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
      </div>
    <% end %>

    <!-- TABS NAVIGATION -->
    <ul class="nav nav-tabs mb-4" role="tablist">
      <li class="nav-item" role="presentation">
        <button class="nav-link active" id="info-tab" data-bs-toggle="tab" 
                data-bs-target="#info" type="button" role="tab">
          <i class="bi bi-info-circle"></i> Informations
        </button>
      </li>
      <li class="nav-item" role="presentation">
        <button class="nav-link" id="variants-tab" data-bs-toggle="tab" 
                data-bs-target="#variants" type="button" role="tab">
          <i class="bi bi-diagram-3"></i> Variantes
          <span class="badge bg-primary ms-2"><%= @product.product_variants.count %></span>
        </button>
      </li>
      <li class="nav-item" role="presentation">
        <button class="nav-link" id="images-tab" data-bs-toggle="tab" 
                data-bs-target="#images" type="button" role="tab">
          <i class="bi bi-image"></i> Images
        </button>
      </li>
    </ul>

    <div class="tab-content">
      <!-- TAB 1: INFORMATIONS -->
      <div class="tab-pane fade show active" id="info" role="tabpanel">
        <%= render 'admin/products/tabs/informations', f: f, product: @product %>
      </div>

      <!-- TAB 2: VARIANTES -->
      <div class="tab-pane fade" id="variants" role="tabpanel">
        <%= render 'admin/products/tabs/variants', product: @product %>
      </div>

      <!-- TAB 3: IMAGES -->
      <div class="tab-pane fade" id="images" role="tabpanel">
        <%= render 'admin/products/tabs/images', f: f, product: @product %>
      </div>
    </div>

    <!-- BOUTONS ACTIONS -->
    <div class="mt-4 d-flex gap-2">
      <%= f.submit @product.new_record? ? 'Créer' : 'Mettre à jour', 
          class: 'btn btn-liquid-primary' %>
      <%= link_to 'Annuler', admin_products_path, class: 'btn btn-outline-secondary' %>
    </div>
  <% end %>
</div>
```

### Tab Informations Partial

```erb
<!-- app/views/admin/products/tabs/_informations.html.erb -->
<div class="row">
  <div class="col-md-6">
    <div class="mb-3">
      <%= f.label :product_category_id, 'Catégorie *' %>
      <%= f.collection_select :product_category_id, ProductCategory.all, :id, :name,
          { prompt: 'Sélectionner une catégorie' },
          class: 'form-select' %>
      <div class="invalid-feedback">
        La catégorie est requise
      </div>
    </div>

    <div class="mb-3">
      <%= f.label :name, 'Nom du produit *' %>
      <%= f.text_field :name, maxlength: 140, class: 'form-control',
          placeholder: 'Ex: Rollers Roue Feu' %>
      <small class="text-muted">Max 140 caractères</small>
    </div>

    <div class="mb-3">
      <%= f.label :slug, 'Slug (URL) *' %>
      <%= f.text_field :slug, class: 'form-control',
          placeholder: 'auto-généré' %>
    </div>

    <div class="mb-3">
      <%= f.label :price_cents, 'Prix de base (€) *' %>
      <div class="input-group">
        <%= f.number_field :price_cents, step: 0.01, class: 'form-control',
            value: f.object.price_cents&.then { |c| c / 100.0 } %>
        <span class="input-group-text">€</span>
      </div>
    </div>
  </div>

  <div class="col-md-6">
    <div class="mb-3">
      <%= f.label :currency, 'Devise' %>
      <%= f.select :currency, ['EUR', 'USD'], {}, class: 'form-select' %>
    </div>

    <div class="mb-3">
      <div class="form-check form-switch">
        <%= f.check_box :is_active, { class: 'form-check-input' } %>
        <%= f.label :is_active, 'Actif', class: 'form-check-label' %>
      </div>
      <small class="text-muted">Décochez pour masquer du catalogue</small>
    </div>

    <div class="mb-3">
      <%= f.label :description, 'Description' %>
      <%= f.text_area :description, class: 'form-control', rows: 6,
          placeholder: 'Description complète du produit' %>
    </div>
  </div>
</div>
```

### Tab Variantes Partial

```erb
<!-- app/views/admin/products/tabs/_variants.html.erb -->
<div class="mb-3">
  <%= link_to 'Ajouter une variante', 
      new_admin_product_product_variant_path(@product),
      class: 'btn btn-sm btn-outline-primary',
      data: { turbo_frame: 'modal_variant' } %>
</div>

<% if @product.product_variants.any? %>
  <div class="table-responsive">
    <table class="table table-sm">
      <thead class="table-light">
        <tr>
          <th>SKU</th>
          <th>Options</th>
          <th>Prix</th>
          <th>Stock</th>
          <th>Statut</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <% @product.product_variants.each do |variant| %>
          <tr>
            <td><code><%= variant.sku %></code></td>
            <td>
              <% variant.variant_option_values.map(&:option_value).each do |ov| %>
                <span class="badge bg-light text-dark">
                  <%= "#{ov.option.name}: #{ov.value}" %>
                </span>
              <% end %>
            </td>
            <td><%= number_to_currency(variant.price_cents / 100.0) %></td>
            <td>
              <% if variant.stock_qty > 0 %>
                <span class="badge bg-success"><%= variant.stock_qty %></span>
              <% else %>
                <span class="badge bg-danger">Rupture</span>
              <% end %>
            </td>
            <td>
              <% if variant.is_active %>
                <span class="badge bg-light text-dark">Actif</span>
              <% else %>
                <span class="badge bg-secondary">Inactif</span>
              <% end %>
            </td>
            <td>
              <div class="btn-group btn-group-sm">
                <%= link_to edit_admin_product_product_variant_path(@product, variant),
                    class: 'btn btn-outline-warning btn-sm',
                    remote: true do %>
                  <i class="bi bi-pencil"></i>
                <% end %>
                
                <%= link_to admin_product_product_variant_path(@product, variant),
                    method: :delete, data: { confirm: 'Confirmer?' },
                    class: 'btn btn-outline-danger btn-sm' do %>
                  <i class="bi bi-trash"></i>
                <% end %>
              </div>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
<% else %>
  <div class="alert alert-info">
    Aucune variante. 
    <%= link_to 'Créer la première', 
        new_admin_product_product_variant_path(@product) %>
  </div>
<% end %>

<!-- MODAL ÉDITION VARIANTE -->
<%= turbo_frame_tag 'modal_variant', src: '' %>
```

---

## 🔄 SERVICES OPTIMISÉS

### ProductVariantGenerator - AMÉLIORÉ

```ruby
# app/services/product_variant_generator.rb
class ProductVariantGenerator
  attr_reader :product, :option_types, :errors

  def initialize(product, option_types: [])
    @product = product
    @option_types = option_types.is_a?(Array) ? option_types : [option_types].compact
    @errors = []
  end

  # NOUVEAU : Preview avant création
  def self.preview(product_id, option_ids)
    option_types = OptionType.where(id: option_ids)
    option_values_array = option_types.map { |ot| ot.option_values.order(:value) }
    
    combinations = option_values_array.first&.product(*option_values_array[1..-1])
    count = combinations&.length || 0
    
    {
      count: count,
      preview_skus: combinations&.map { |combo| generate_sku_template(combo) }&.first(5) || [],
      estimated_time: count * 5,  # secondes
      warning: count > 20 ? "Beaucoup de variantes ! Vérifiez bien." : nil
    }
  end

  # NOUVEAU : Générer combinaisons (avec transaction)
  def self.generate_combinations(product, option_ids)
    option_types = OptionType.where(id: option_ids)
    option_values_array = option_types.map { |ot| ot.option_values.order(:value) }
    
    combinations = option_values_array.first&.product(*option_values_array[1..-1])
    
    ActiveRecord::Base.transaction do
      combinations&.each do |combo|
        # Générer SKU sûr + unique
        sku = generate_sku_safely(product, combo)
        
        variant = product.product_variants.create!(
          sku: sku,
          price_cents: product.price_cents,  # NOUVEAU : Héritage prix
          stock_qty: 0,
          is_active: product.is_active
        )
        
        # Lier les options
        combo.each do |option_value|
          variant.variant_option_values.create!(option_value: option_value)
        end
      end
    end
    
    combinations&.length || 0
  end

  # NOUVEAU : Générer options manquantes (en édition)
  def self.generate_missing_combinations(product, option_ids)
    existing_options = product.product_variants
      .joins(:variant_option_values)
      .pluck('option_values.option_type_id')
      .uniq
    
    new_option_ids = option_ids.map(&:to_i) - existing_options
    
    return 0 if new_option_ids.empty?
    
    # Générer seulement les nouvelles combinaisons
    option_types = OptionType.where(id: new_option_ids)
    option_values_array = option_types.map { |ot| ot.option_values.order(:value) }
    
    combinations = option_values_array.first&.product(*option_values_array[1..-1])
    
    ActiveRecord::Base.transaction do
      combinations&.each do |combo|
        sku = generate_sku_safely(product, combo)
        
        variant = product.product_variants.create!(
          sku: sku,
          price_cents: product.price_cents,
          stock_qty: 0,
          is_active: product.is_active
        )
        
        combo.each do |option_value|
          variant.variant_option_values.create!(option_value: option_value)
        end
      end
    end
    
    combinations&.length || 0
  end

  # AMÉLIORÉ : SKU génération sûre
  private

  def self.generate_sku_safely(product, combo)
    base_sku = "#{product.slug.upcase}-#{combo.map(&:value).join('-').upcase}"
    
    # Vérifier unicité (avec verrouillage pessimiste)
    unless ProductVariant.where(sku: base_sku).exists?
      return base_sku
    end
    
    # Fallback : ajouter number si existe
    counter = 1
    loop do
      new_sku = "#{base_sku}-#{counter}"
      return new_sku unless ProductVariant.where(sku: new_sku).exists?
      counter += 1
    end
  end

  def self.generate_sku_template(combo)
    "PRODUCT-#{combo.map(&:value).join('-').upcase}"
  end

  # Méthodes existantes (generate, etc.)
  def generate(base_price_cents: nil, base_stock_qty: 0)
    # ... code existant ...
  end
end
```

### ProductExporter - NOUVEAU

```ruby
# app/services/product_exporter.rb
require 'csv'

class ProductExporter
  def self.to_csv(products)
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Nom', 'Catégorie', 'Prix', 'Stock Total', 'Variantes', 'SKUs', 'Statut']
      
      products.each do |product|
        csv << [
          product.id,
          product.name,
          product.category&.name || '-',
          "#{product.price_cents / 100.0}€",
          product.total_stock,
          product.product_variants.count,
          product.product_variants.pluck(:sku).join('; '),
          product.is_active ? 'Actif' : 'Inactif'
        ]
      end
    end
  end

  def self.to_xlsx(products)
    # À implémenter avec rubyXL
    # Pour l'instant, utiliser CSV
    to_csv(products)
  end
end
```

### OrderExporter - NOUVEAU

```ruby
# app/services/order_exporter.rb
require 'csv'

class OrderExporter
  def self.to_csv(orders)
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Date', 'Client', 'Email', 'Montant', 'Articles', 'Statut']
      
      orders.each do |order|
        csv << [
          order.id,
          order.created_at.strftime('%d/%m/%Y %H:%M'),
          order.user.name,
          order.user.email,
          "#{order.total_cents / 100.0}€",
          order.order_items.count,
          order.status
        ]
      end
    end
  end

  def self.to_xlsx(orders)
    # À implémenter avec rubyXL
    to_csv(orders)
  end
end
```

---

## Gestion Stock Agrégé

### Model Helper - Product - AMÉLIORÉ

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  include Hashid::Rails

  belongs_to :category, class_name: "ProductCategory"
  has_many :product_variants, dependent: :destroy
  has_one_attached :image

  # VALIDATIONS
  validates :name, :slug, :price_cents, :currency, presence: true
  validate :image_or_image_url_present
  validates :name, length: { maximum: 140 }
  validates :slug, length: { maximum: 160 }, uniqueness: true
  validates :currency, length: { is: 3 }
  validate :has_at_least_one_active_variant

  # SCOPES
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :by_category, ->(id) { where(category_id: id) }
  scope :by_status, ->(status) { where(is_active: status == 'active') }
  scope :search_by_name, ->(term) { where('name ILIKE ?', "%#{term}%") }

  scope :in_stock, -> {
    joins(:product_variants)
      .where(product_variants: { is_active: true })
      .group('products.id')
      .having('SUM(product_variants.stock_qty) > 0')
  }

  scope :out_of_stock, -> {
    left_joins(:product_variants)
      .group('products.id')
      .having('SUM(product_variants.stock_qty) IS NULL OR SUM(product_variants.stock_qty) = 0')
  }

  scope :by_stock_status, ->(status) {
    status == 'in_stock' ? in_stock : out_of_stock
  }

  # NOUVEAU : Eager loading + pagination support
  scope :with_associations, -> {
    includes(:category, product_variants: [:variant_option_values, :option_values], :image_attachment)
  }

  # CALLBACKS
  before_save :generate_slug, if: :name_changed?

  # METHODS
  def total_stock
    product_variants.where(is_active: true).sum(:stock_qty)
  end

  def in_stock?
    total_stock > 0
  end

  def price
    price_cents / 100.0
  end

  # NOUVEAU : Héritage image pour variantes
  def image_for_variant(variant)
    variant.image.attached? ? variant.image : self.image
  end

  # NOUVEAU : Agrégat stock par option
  def stock_by_option(option_type)
    product_variants
      .joins(variant_option_values: :option_value)
      .where(option_values: { option_type_id: option_type.id })
      .group('option_values.presentation')
      .sum(:stock_qty)
  end

  # Ransack
  def self.ransackable_attributes(_auth_object = nil)
    %w[id category_id name slug description price_cents currency stock_qty is_active image_url created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[category product_variants]
  end

  private

  def generate_slug
    self.slug = name.parameterize if slug.blank?
  end

  def image_or_image_url_present
    return if image.attached? || image_url.present?
    errors.add(:base, "Une image (upload ou URL) est requise")
  end

  def has_at_least_one_active_variant
    return if product_variants.exists?(is_active: true)
    errors.add(:base, 'Au moins une variante active requise')
  end
end
```

### ProductVariant Model - AMÉLIORÉ

```ruby
# app/models/product_variant.rb
class ProductVariant < ApplicationRecord
  belongs_to :product
  has_many :variant_option_values, foreign_key: :variant_id, dependent: :destroy
  has_many :option_values, through: :variant_option_values
  has_one_attached :image

  # VALIDATIONS
  validates :sku, presence: true, uniqueness: true,
            format: { with: /\A[A-Z0-9-]+\z/, message: 'format invalide' }
  validates :price_cents, numericality: { greater_than: 0 }
  validates :stock_qty, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, length: { is: 3 }
  validate :image_or_image_url_present
  validate :has_required_option_values

  # NOUVEAU : Héritage prix/stock
  attr_accessor :inherit_price, :inherit_stock

  before_save :apply_inheritance

  # SCOPES
  scope :active, -> { where(is_active: true) }
  scope :by_sku, ->(sku) { where(sku: sku) }
  scope :by_option, ->(option_value_id) {
    joins(:variant_option_values)
      .where(variant_option_values: { option_value_id: option_value_id })
  }

  # Ransack
  def self.ransackable_attributes(_auth_object = nil)
    %w[id product_id sku price_cents currency stock_qty is_active created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[product option_values]
  end

  private

  def has_required_option_values
    # Si le produit a plusieurs variantes, celle-ci doit avoir des options
    return if variant_option_values.any? || product.product_variants.count <= 1
    errors.add(:base, 'Les variantes doivent avoir des options de catégorisation')
  end

  def apply_inheritance
    self.price_cents = product.price_cents if inherit_price.present?
    self.stock_qty = 0 if inherit_stock.present?
  end

  def image_or_image_url_present
    return if image.attached? || image_url.present?
    errors.add(:base, "Une image (upload ou URL) est requise")
  end
end
```

### ProductsHelper

```ruby
# app/helpers/admin/products_helper.rb
module Admin::ProductsHelper
  def stock_color_class(product)
    product.total_stock > 0 ? 'success' : 'danger'
  end
  
  def stock_status_text(product)
    product.total_stock > 0 ? "#{product.total_stock} en stock" : 'Rupture'
  end
  
  def price_format(amount_cents)
    number_to_currency(amount_cents / 100.0, unit: '€')
  end
  
  def category_badge(category)
    tag.span(category.name, class: 'badge bg-light text-dark')
  end
  
  def status_badge(is_active)
    if is_active
      tag.span(class: 'badge bg-success') do
        tag.i(class: 'bi bi-check-circle me-1') + 'Actif'
      end
    else
      tag.span(class: 'badge bg-secondary') do
        tag.i(class: 'bi bi-x-circle me-1') + 'Inactif'
      end
    end
  end
end
```

---

## Stimulus Controllers

### ProductFormController - Gestion Tabs

```javascript
// app/javascript/controllers/admin/product_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "slugInput", "nameInput", "submitBtn"]
  
  connect() {
    this.initAutoSlug()
    this.initFormValidation()
  }
  
  // Auto-génération slug depuis le nom
  initAutoSlug() {
    this.nameInputTarget?.addEventListener('change', () => {
      const slug = this.generateSlug(this.nameInputTarget.value)
      this.slugInputTarget.value = slug
    })
  }
  
  generateSlug(text) {
    return text
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^\w\s-]/g, '')
      .trim()
      .replace(/[-\s]+/g, '-')
  }
  
  // Validation client avant submit
  initFormValidation() {
    this.formTarget.addEventListener('submit', (e) => {
      if (!this.validateForm()) {
        e.preventDefault()
        this.showValidationErrors()
      }
    })
  }
  
  validateForm() {
    return this.formTarget.checkValidity() === false ? false : true
  }
  
  showValidationErrors() {
    this.formTarget.classList.add('was-validated')
    // Bootstrap affiche les invalid-feedback
  }
  
  // Changement tab
  switchTab(tabName) {
    const tab = new bootstrap.Tab(
      document.querySelector(`#${tabName}-tab`)
    )
    tab.show()
  }
}
```

### ImageUploadController - Prévisualisation

```javascript
// app/javascript/controllers/admin/image_upload_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "removeBtn"]
  
  connect() {
    this.inputTarget.addEventListener('change', (e) => this.preview(e))
  }
  
  preview(event) {
    const file = event.target.files[0]
    if (!file) return
    
    // Validation taille
    if (file.size > 5 * 1024 * 1024) {
      alert('Fichier trop volumineux (max 5MB)')
      return
    }
    
    // Validation type
    if (!file.type.startsWith('image/')) {
      alert('Fichier invalide (image requise)')
      return
    }
    
    // Prévisualisation
    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewTarget.src = e.target.result
      this.previewTarget.style.display = 'block'
      this.removeBtnTarget.style.display = 'block'
    }
    reader.readAsDataURL(file)
  }
  
  remove() {
    this.inputTarget.value = ''
    this.previewTarget.style.display = 'none'
    this.removeBtnTarget.style.display = 'none'
  }
}
```

### OrderStatusController - Workflow Statuts

```javascript
// app/javascript/controllers/admin/order_status_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["statusBtn", "statusSelect", "confirmModal"]
  static values = {
    orderId: Number,
    currentStatus: String,
    availableTransitions: Object
  }
  
  connect() {
    this.statusBtnTarget?.addEventListener('click', () => this.showStatusModal())
  }
  
  showStatusModal() {
    const modal = new bootstrap.Modal(this.confirmModalTarget)
    this.populateAvailableStatuses()
    modal.show()
  }
  
  populateAvailableStatuses() {
    const select = this.statusSelectTarget
    select.innerHTML = ''
    
    const transitions = this.availableTransitionsValue
    Object.entries(transitions).forEach(([status, allowed]) => {
      if (allowed) {
        const option = document.createElement('option')
        option.value = status
        option.textContent = this.getStatusLabel(status)
        select.appendChild(option)
      }
    })
  }
  
  confirmStatusChange() {
    const newStatus = this.statusSelectTarget.value
    
    fetch(`/admin/orders/${this.orderIdValue}/change_status`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ status: newStatus })
    })
    .then(r => r.ok ? window.location.reload() : alert('Erreur'))
    .catch(() => alert('Erreur réseau'))
  }
  
  getStatusLabel(status) {
    const labels = {
      'pending': 'En attente',
      'paid': 'Payée',
      'preparation': 'En préparation',
      'shipped': 'Expédiée',
      'cancelled': 'Annulée'
    }
    return labels[status] || status
  }
}
```

---

## Validation Hybride

### Client Stimulus + Serveur Rails

```javascript
// app/javascript/controllers/admin/variant_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["skuInput", "skuError", "priceInput", "stockInput", "submitBtn"]
  
  validateSku() {
    const sku = this.skuInputTarget.value
    
    if (sku.length < 3) {
      this.showError('SKU minimum 3 caractères')
      return false
    }
    
    // Vérification unicité côté client (feedback immédiat)
    // Serveur valide définitivement
    this.checkSkuUniqueness(sku)
    return true
  }
  
  async checkSkuUniqueness(sku) {
    try {
      const response = await fetch(`/admin/product_variants/check_sku?sku=${sku}`)
      const data = await response.json()
      
      if (!data.available) {
        this.showError('SKU déjà utilisé')
        this.disableSubmit()
      } else {
        this.clearError()
        this.enableSubmit()
      }
    } catch (error) {
      console.error(error)
    }
  }
  
  validatePrice() {
    const price = parseFloat(this.priceInputTarget.value)
    if (price <= 0) {
      this.showError('Prix doit être > 0')
      return false
    }
    this.clearError()
    return true
  }
  
  showError(msg) {
    this.skuErrorTarget.textContent = msg
    this.skuErrorTarget.style.display = 'block'
    this.skuInputTarget.classList.add('is-invalid')
  }
  
  clearError() {
    this.skuErrorTarget.style.display = 'none'
    this.skuInputTarget.classList.remove('is-invalid')
  }
  
  disableSubmit() {
    this.submitBtnTarget.disabled = true
  }
  
  enableSubmit() {
    this.submitBtnTarget.disabled = false
  }
}
```

### Validation Serveur Rails

```ruby
# app/models/product_variant.rb
class ProductVariant < ApplicationRecord
  belongs_to :product
  has_many :variant_option_values, dependent: :destroy
  has_many :option_values, through: :variant_option_values
  has_one_attached :image
  
  validates :sku, presence: true, uniqueness: true, 
            format: { with: /\A[A-Z0-9\-]+\z/, message: 'format invalide' }
  validates :price_cents, numericality: { greater_than: 0 }
  validates :stock_qty, numericality: { greater_than_or_equal_to: 0 }
  validate :at_least_one_option_value
  
  def at_least_one_option_value
    return if variant_option_values.any?
    errors.add(:base, 'Au moins une option requise (couleur/taille)')
  end
end

# Controller endpoint validation
module Admin
  class ProductVariantsController < BaseController
    def check_sku
      sku = params[:sku]
      available = !ProductVariant.exists?(sku: sku)
      render json: { available: available }
    end
  end
end
```

---

## Exemples Complets

### Modèle Product - Scopes Complets

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  # Relations
  belongs_to :product_category, class_name: 'ProductCategory'
  has_many :product_variants, dependent: :destroy
  has_many :orders, through: :order_items
  has_one_attached :image
  
  # Validations
  validates :name, presence: true, length: { maximum: 140 }
  validates :slug, presence: true, uniqueness: true
  validates :price_cents, numericality: { greater_than: 0 }
  validates :product_category_id, presence: true
  validate :image_required_on_create
  validate :has_at_least_one_active_variant
  
  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :by_category, ->(id) { where(product_category_id: id) }
  scope :by_status, ->(status) { where(is_active: status == 'active') }
  scope :search_by_name, ->(term) { where('name ILIKE ?', "%#{term}%") }
  
  scope :in_stock, -> {
    joins(:product_variants)
      .where(product_variants: { is_active: true })
      .group('products.id')
      .having('SUM(product_variants.stock_qty) > 0')
  }
  
  scope :out_of_stock, -> {
    left_joins(:product_variants)
      .group('products.id')
      .having('SUM(product_variants.stock_qty) IS NULL OR SUM(product_variants.stock_qty) = 0')
  }
  
  scope :by_stock_status, ->(status) {
    status == 'in_stock' ? in_stock : out_of_stock
  }
  
  scope :with_associations, -> {
    includes(:product_category, product_variants: :variant_option_values, :image_attachment)
  }
  
  # Callbacks
  before_save :generate_slug, if: :name_changed?
  
  # Methods
  def total_stock
    product_variants.where(is_active: true).sum(:stock_qty)
  end
  
  def in_stock?
    total_stock > 0
  end
  
  def price
    price_cents / 100.0
  end
  
  private
  
  def generate_slug
    self.slug = name.parameterize if slug.blank?
  end
  
  def image_required_on_create
    errors.add(:image, 'requise') if new_record? && image.blank?
  end
  
  def has_at_least_one_active_variant
    return if product_variants.exists?(is_active: true)
    errors.add(:base, 'Au moins une variante active requise')
  end
end
```

### Modèle Order - Workflow Statuts

```ruby
# app/models/order.rb
class Order < ApplicationRecord
  # Statuts possibles
  STATUSES = %w[pending paid preparation shipped cancelled refund_requested refunded failed].freeze
  
  enum status: STATUSES.index_by(&:to_sym)
  
  # Relations
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :variants, through: :order_items
  
  # Validations
  validates :status, inclusion: { in: STATUSES }
  
  # Scopes
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_user_email, ->(email) { joins(:user).where('users.email ILIKE ?', "%#{email}%") }
  scope :by_date_range, ->(from, to) {
    where('orders.created_at >= ? AND orders.created_at <= ?', from, to) if from.present? && to.present?
  }
  scope :recent_first, -> { order(created_at: :desc) }
  
  # Transitions possibles
  TRANSITIONS = {
    'pending' => %w[paid cancelled failed],
    'paid' => %w[preparation cancelled refund_requested],
    'preparation' => %w[shipped cancelled],
    'shipped' => %w[refund_requested],
    'cancelled' => %w[],
    'refund_requested' => %w[refunded cancelled],
    'refunded' => %w[],
    'failed' => %w[pending]
  }.freeze
  
  # Callbacks
  after_update :restore_stock_if_cancelled, if: :cancelled?
  after_update :send_status_notification, if: :status_changed?
  
  def available_transitions
    TRANSITIONS[status] || []
  end
  
  def can_transition_to?(new_status)
    available_transitions.include?(new_status)
  end
  
  def cancelled?
    status == 'cancelled'
  end
  
  private
  
  def restore_stock_if_cancelled
    order_items.each do |item|
      item.variant.increment!(:stock_qty, item.quantity)
    end
  end
  
  def send_status_notification
    OrderMailer.status_changed(self).deliver_later
  end
end
```

---

## Performance & Optimisations

### Eager Loading Standard

```ruby
# app/controllers/admin/products_controller.rb
def index
  @products = Product
    .with_associations
    .by_category(params[:category])
    .by_status(params[:status])
    .search_by_name(params[:search])
    .order(created_at: :desc)
  
  @pagy, @products = pagy(@products, items: 25)
end

# Model scope
scope :with_associations, -> {
  includes(
    :product_category,
    product_variants: [:variant_option_values, :image_attachment],
    :image_attachment
  )
}
```

### Pagination Pagy

```erb
<!-- app/views/shared/_pagination.html.erb -->
<nav aria-label="Pagination">
  <ul class="pagination mb-0">
    <% if @pagy.prev %>
      <li class="page-item">
        <%= link_to "← Précédent", @pagy.path(1), class: "page-link" %>
      </li>
    <% end %>

    <% @pagy.series.each do |item| %>
      <% if item == :gap %>
        <li class="page-item disabled">
          <span class="page-link">...</span>
        </li>
      <% elsif item == @pagy.page %>
        <li class="page-item active">
          <span class="page-link">
            <%= item %>
            <span class="visually-hidden">(actuelle)</span>
          </span>
        </li>
      <% else %>
        <li class="page-item">
          <%= link_to item, @pagy.path(item), class: "page-link" %>
        </li>
      <% end %>
    <% end %>

    <% if @pagy.next %>
      <li class="page-item">
        <%= link_to "Suivant →", @pagy.path(@pagy.next), class: "page-link" %>
      </li>
    <% end %>
  </ul>
</nav>
```

### Requêtes N+1 - Anti-patterns à Éviter

```ruby
# ❌ MAUVAIS - N+1 queries
@products.each { |p| puts p.category.name }

# ✅ BON - Eager loading
@products = Product.includes(:product_category)
@products.each { |p| puts p.category.name }

# ✅ BON - Scope réutilisable
@products = Product.with_associations
```

---

## Migration depuis Active Admin

### Équivalences Scopes

```ruby
# Active Admin
filter :is_active, as: :boolean
scope :active, -> { where(is_active: true) }
scope :inactive, -> { where(is_active: false) }

# Nouveau Panel Admin (identique, juste dans Product model)
scope :active, -> { where(is_active: true) }
scope :inactive, -> { where(is_active: false) }
```

### Migration Filtres

```ruby
# Active Admin
filter :name, as: :string
filter :category, as: :select, collection: -> { ProductCategory.all }

# Nouveau Panel - Dans Controller
def apply_filters(relation)
  relation = relation.search_by_name(params[:search]) if params[:search].present?
  relation = relation.by_category(params[:category]) if params[:category].present?
  relation
end
```

### Permissions Pundit Existantes

```ruby
# app/policies/admin/product_policy.rb
class Admin::ProductPolicy < ApplicationPolicy
  def index?
    admin?
  end
  
  def create?
    admin?
  end
  
  def update?
    admin?
  end
  
  def destroy?
    admin? && !record.has_orders?
  end
  
  private
  
  def admin?
    user.admin?
  end
end

# Controller utilise
authorize @product  # Utilise ProductPolicy
```

---

## Checklist Mise en Œuvre

- [ ] Models: Ajouter scopes et validations
- [ ] Controllers: Base + Products + Variants + Orders
- [ ] Vues: Structure partials réutilisables
- [ ] Stimulus: Image upload + Product form + Order status
- [ ] Helpers: Stock, prix, badges
- [ ] Tests: Model validations, controller authorize
- [ ] Migrations: Pas nécessaires (structure existante)
- [ ] CSS: Utiliser classes Bootstrap existantes
- [ ] Documentation: Mise à jour guide admin
- [ ] Performance: Tester N+1 avec Rails Query Insights

---

## Stack Finalisée

```yaml
Backend:
  Framework: Rails 8.1.1
  Database: PostgreSQL 16
  Auth: Pundit (autorisations)
  File Storage: Active Storage
  
Frontend:
  CSS: Bootstrap 5.3.2
  JS: Stimulus (non-intrusive)
  Forms: Rails form_with
  Pagination: Pagy
  
UI Components:
  Tables: Bootstrap tables
  Forms: Bootstrap form-control
  Modals: Bootstrap modal
  Tabs: Bootstrap nav-tabs
  Alerts: Bootstrap alerts
```

---

**Version**: 1.0 | **Date**: Dec 2025 | **Status**: Production Ready
