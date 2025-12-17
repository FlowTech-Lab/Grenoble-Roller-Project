# 🎨 Base UX-UI Panel Admin - Guide d'Implémentation

**Objectif** : Mettre en place la base UX-UI du panel admin avec layout, sidebar, dashboard et intégration navbar.

**Approche** : Utiliser uniquement les classes Bootstrap de base pour l'instant, on adaptera les classes Liquid plus tard.

---

## 🎯 Architecture Recommandée

### Layout Admin : Hériter de `application.html.erb` ✅

**Avantages** :
- Réutilise navbar principale (cohérence)
- Dark mode hérité automatiquement
- DRY principle
- Une seule source de vérité CSS/JS

**Structure** : Layout admin avec sidebar + contenu principal

---

## 1️⃣ Layout Admin

### Fichier : `app/views/layouts/admin.html.erb`

```erb
<!DOCTYPE html>
<html lang="fr" data-bs-theme="light">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Admin - <%= content_for(:title) || "Grenoble Roller" %></title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "application.bootstrap", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body class="d-flex flex-column min-vh-100">
    <!-- NAVBAR PRINCIPALE (héritée) -->
    <%= render 'layouts/navbar' %>

    <!-- CONTENEUR ADMIN: Sidebar + Contenu -->
    <div class="d-flex flex-grow-1" style="overflow: hidden;">
      <!-- SIDEBAR ADMIN -->
      <%= render 'admin/shared/sidebar' %>

      <!-- CONTENU PRINCIPAL -->
      <main class="flex-grow-1 d-flex flex-column" style="overflow-y: auto;">
        <div class="container-fluid p-3 p-lg-4">
          <!-- Flash messages -->
          <% if notice %>
            <div class="alert alert-success alert-dismissible fade show" role="alert">
              <%= notice %>
              <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
          <% end %>
          <% if alert %>
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
              <%= alert %>
              <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
          <% end %>

          <!-- Contenu -->
          <%= yield %>
        </div>
      </main>
    </div>

    <!-- Footer optionnel -->
    <footer class="mt-auto py-2 px-3 border-top bg-light">
      <div class="container-fluid text-muted text-center">
        <small>© 2025 Grenoble Roller Admin</small>
      </div>
    </footer>
  </body>
</html>
```

**Note** : Dark mode hérite automatiquement via `data-bs-theme` sur `<html>` (déjà géré dans navbar).

---

## 2️⃣ Routes Admin

### Modification : `config/routes.rb`

**Recommandation** : Utiliser namespace `/admin-panel` pour éviter conflit avec Active Admin

```ruby
Rails.application.routes.draw do
  # ===== ACTIVE ADMIN (ANCIEN) =====
  ActiveAdmin.routes(self)  # /activeadmin/*
  
  # ===== NOUVEAU PANEL ADMIN =====
  namespace :admin_panel, path: 'admin-panel' do
    root 'dashboard#index'  # GET /admin-panel → Dashboard
    
    # Routes futures
    # resources :products
    # resources :orders
    # resources :users
  end

  # ===== ROUTES PUBLIQUES =====
  root 'pages#index'
  devise_for :users
  # ... autres routes
end
```

**Routes générées** :
- `/admin-panel` → Dashboard
- `/activeadmin` → Active Admin (existant)

---

## 3️⃣ BaseController Admin

### Fichier : `app/controllers/admin_panel/base_controller.rb`

```ruby
module AdminPanel
  class BaseController < ApplicationController
    include Pundit::Authorization
    
    before_action :authenticate_admin_user!
    layout 'admin'
    
    private
    
    def authenticate_admin_user!
      unless current_user&.role&.code.in?(%w[ADMIN SUPERADMIN])
        redirect_to root_path, alert: 'Accès administrateur requis'
      end
    end
    
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
    
    def user_not_authorized
      flash[:alert] = 'Vous n\'êtes pas autorisé à effectuer cette action'
      redirect_to admin_panel_root_path
    end
  end
end
```

---

## 4️⃣ DashboardController

### Fichier : `app/controllers/admin_panel/dashboard_controller.rb`

```ruby
module AdminPanel
  class DashboardController < BaseController
    def index
      # Statistiques simples
      @stats = {
        total_users: User.count,
        total_products: Product.count,
        total_orders: Order.count,
        pending_orders: Order.where(status: 'pending').count
      }
      
      # Commandes récentes (5 dernières)
      @recent_orders = Order.includes(:user).order(created_at: :desc).limit(5)
    end
  end
end
```

**Optimisations plus tard** : Cache, requêtes SQL optimisées, etc.

---

## 5️⃣ Vue Dashboard Simple

### Fichier : `app/views/admin_panel/dashboard/index.html.erb`

```erb
<div class="admin-dashboard">
  <!-- HEADER -->
  <div class="mb-4">
    <h1>Dashboard Admin</h1>
    <p class="text-muted">Bienvenue, <%= current_user.first_name || current_user.email %></p>
  </div>

  <!-- STATISTIQUES (4 cartes Bootstrap) -->
  <div class="row g-3 mb-4">
    <div class="col-md-6 col-lg-3">
      <div class="card">
        <div class="card-body">
          <h5 class="card-title text-muted">Utilisateurs</h5>
          <h3 class="mb-0"><%= @stats[:total_users] %></h3>
        </div>
      </div>
    </div>

    <div class="col-md-6 col-lg-3">
      <div class="card">
        <div class="card-body">
          <h5 class="card-title text-muted">Produits</h5>
          <h3 class="mb-0"><%= @stats[:total_products] %></h3>
        </div>
      </div>
    </div>

    <div class="col-md-6 col-lg-3">
      <div class="card">
        <div class="card-body">
          <h5 class="card-title text-muted">Commandes</h5>
          <h3 class="mb-0"><%= @stats[:total_orders] %></h3>
        </div>
      </div>
    </div>

    <div class="col-md-6 col-lg-3">
      <div class="card">
        <div class="card-body">
          <h5 class="card-title text-muted">En attente</h5>
          <h3 class="mb-0"><%= @stats[:pending_orders] %></h3>
        </div>
      </div>
    </div>
  </div>

  <!-- COMMANDES RÉCENTES -->
  <div class="card">
    <div class="card-header">
      <h5 class="mb-0">Commandes Récentes</h5>
    </div>
    <div class="card-body">
      <% if @recent_orders.any? %>
        <div class="table-responsive">
          <table class="table table-hover">
            <thead>
              <tr>
                <th>ID</th>
                <th>Client</th>
                <th>Total</th>
                <th>Statut</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              <% @recent_orders.each do |order| %>
                <tr>
                  <td>#<%= order.id %></td>
                  <td><%= order.user.email %></td>
                  <td><%= number_to_currency(order.total_cents / 100.0, unit: '€') %></td>
                  <td><span class="badge bg-secondary"><%= order.status %></span></td>
                  <td><%= order.created_at.strftime('%d/%m/%Y %H:%M') %></td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% else %>
        <p class="text-muted text-center py-4">Aucune commande récente</p>
      <% end %>
    </div>
  </div>
</div>
```

**Classes utilisées** : Bootstrap de base uniquement (`card`, `table`, `badge`, etc.)

---

## 6️⃣ Modification Navbar

### Fichier : `app/views/layouts/_navbar.html.erb`

**Remplacer les lignes 121-132** par :

```erb
<% if current_user.role&.code.in?(%w[ADMIN SUPERADMIN]) %>
  <li><hr class="dropdown-divider"></li>
  
  <!-- NOUVEAU PANEL ADMIN -->
  <li>
    <%= link_to admin_panel_root_path, class: "dropdown-item" do %>
      <i class="bi bi-shield-check me-2"></i>Administration
    <% end %>
  </li>
  
  <!-- ACTIVE ADMIN (Legacy) -->
  <li>
    <%= link_to Rails.application.routes.url_helpers.activeadmin_root_path, class: "dropdown-item" do %>
      <i class="bi bi-gear me-2"></i>Active Admin
    <% end %>
  </li>
<% end %>
```

---

## 7️⃣ Sidebar (Adapter l'existante)

### Fichier : `app/views/admin/shared/_sidebar.html.erb`

**Utiliser la sidebar existante** mais adapter :

1. **Changer les routes** : `admin_root_path` → `admin_panel_root_path`
2. **Simplifier** : Utiliser classes Bootstrap de base
3. **Responsive** : `d-none d-lg-flex` pour desktop, offcanvas pour mobile

**Structure responsive Bootstrap** :
- Desktop (≥992px) : Sidebar fixe visible
- Mobile (<992px) : Sidebar cachée, affichée via offcanvas

**Classes Bootstrap utilisées** :
- `d-none d-lg-flex` : Masquer sur mobile, afficher sur desktop
- `offcanvas offcanvas-start` : Offcanvas pour mobile
- `nav nav-pills flex-column` : Menu navigation
- `collapse` : Submenus collapsibles

---

## 8️⃣ Stimulus Controller Sidebar (Simple)

### Fichier : `app/javascript/controllers/admin_sidebar_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar"]
  
  connect() {
    // Restaurer l'état sauvegardé
    const saved = localStorage.getItem('admin:sidebar:collapsed')
    if (saved === 'true' && window.innerWidth >= 992) {
      this.collapse()
    }
  }
  
  toggle() {
    if (this.sidebarTarget.classList.contains('collapsed')) {
      this.expand()
    } else {
      this.collapse()
    }
  }
  
  collapse() {
    this.sidebarTarget.classList.add('collapsed')
    this.sidebarTarget.style.width = '64px'
    localStorage.setItem('admin:sidebar:collapsed', 'true')
  }
  
  expand() {
    this.sidebarTarget.classList.remove('collapsed')
    this.sidebarTarget.style.width = '280px'
    localStorage.setItem('admin:sidebar:collapsed', 'false')
  }
}
```

**Fonctionnalités** :
- Toggle collapse/expand
- Persistence localStorage
- Desktop uniquement (mobile géré par offcanvas Bootstrap)

---

## 📋 Checklist Implémentation

### Étape 1 : Routes & Controllers
- [ ] Ajouter namespace `admin_panel` dans `routes.rb`
- [ ] Créer `AdminPanel::BaseController`
- [ ] Créer `AdminPanel::DashboardController`
- [ ] Tester route `/admin-panel`

### Étape 2 : Layout
- [ ] Créer `layouts/admin.html.erb`
- [ ] Tester que layout s'affiche correctement

### Étape 3 : Dashboard
- [ ] Créer `views/admin_panel/dashboard/index.html.erb`
- [ ] Tester affichage des statistiques

### Étape 4 : Sidebar
- [ ] Adapter `views/admin/shared/_sidebar.html.erb` (routes)
- [ ] Vérifier responsive (desktop/mobile)

### Étape 5 : Stimulus
- [ ] Créer `admin_sidebar_controller.js`
- [ ] Tester collapse/expand

### Étape 6 : Navbar
- [ ] Modifier lien "Administration" dans navbar
- [ ] Tester accès depuis dropdown utilisateur

### Étape 7 : Tests
- [ ] Tester authentification (admin only)
- [ ] Tester dark mode (héritage)
- [ ] Tester responsive (mobile/desktop)

---

## 🎨 Classes Bootstrap Utilisées (Base)

### Layout
- `d-flex`, `flex-column`, `flex-grow-1`
- `container-fluid`, `row`, `col-*`

### Cards
- `card`, `card-body`, `card-header`
- `h-100` pour hauteur 100%

### Tables
- `table`, `table-hover`, `table-responsive`

### Navigation
- `nav`, `nav-link`, `nav-pills`
- `collapse` pour submenus
- `offcanvas`, `offcanvas-start` pour mobile

### Badges & Alerts
- `badge`, `bg-secondary`, `bg-success`, etc.
- `alert`, `alert-success`, `alert-danger`

---

## 📝 Notes Importantes

### Pour l'Instant (Base)
- ✅ Utiliser uniquement classes Bootstrap de base
- ✅ Structure simple et fonctionnelle
- ✅ Responsive avec Bootstrap grid et offcanvas

### Plus Tard (Améliorations)
- Adapter classes Liquid (`card-liquid`, `btn-liquid-primary`, etc.)
- Optimisations performance (cache, eager loading)
- Personnalisations CSS avancées

---

## 🔗 Références

- **Sidebar guide** : [sidebar_guide_bootstrap5.md](sidebar_guide_bootstrap5.md)
- **Dashboard** : [DASHBOARD.md](DASHBOARD.md)
- **Classes CSS** : [../references/reference-css-classes.md](../references/reference-css-classes.md)

---

**Version** : 1.0  
**Date** : 2025-01-27  
**Approche** : Base Bootstrap d'abord, améliorations ensuite
