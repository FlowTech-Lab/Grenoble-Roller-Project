# 📋 Todolist - Implémentation Base UX-UI Panel Admin

**Guide complet** : [ressources/decisions/BASE_UX_UI_PANEL.md](ressources/decisions/BASE_UX_UI_PANEL.md)

---

## ✅ Phase 1 : Routes & Controllers

### 1. Routes
- [ ] **Fichier** : `config/routes.rb`
- [ ] **Action** : Ajouter namespace `admin_panel` après `ActiveAdmin.routes(self)`
- [ ] **Code** :
  ```ruby
  namespace :admin_panel, path: 'admin-panel' do
    root 'dashboard#index'
  end
  ```
- [ ] **Vérifier** : `rails routes | grep admin_panel` doit afficher la route

### 2. BaseController
- [ ] **Fichier** : `app/controllers/admin_panel/base_controller.rb` (CRÉER)
- [ ] **Contenu** :
  - Hérite de `ApplicationController`
  - Include `Pundit::Authorization`
  - `before_action :authenticate_admin_user!`
  - `layout 'admin'`
  - Méthode `authenticate_admin_user!` (vérifie `current_user.role.code` dans `%w[ADMIN SUPERADMIN]`)
  - `rescue_from Pundit::NotAuthorizedError`
- [ ] **Vérifier** : Controller existe et classe charge correctement

### 3. DashboardController
- [ ] **Fichier** : `app/controllers/admin_panel/dashboard_controller.rb` (CRÉER)
- [ ] **Contenu** :
  - Hérite de `AdminPanel::BaseController`
  - Action `index` avec :
    - `@stats = { total_users, total_products, total_orders, pending_orders }`
    - `@recent_orders = Order.includes(:user).order(created_at: :desc).limit(5)`
- [ ] **Vérifier** : Controller existe et action `index` définit les variables

---

## ✅ Phase 2 : Layout Admin

### 4. Layout Admin
- [ ] **Fichier** : `app/views/layouts/admin.html.erb` (CRÉER)
- [ ] **Structure** :
  - DOCTYPE HTML
  - `<head>` avec meta, title, csrf, csp, stylesheet (`application.bootstrap`), javascript
  - `<body>` avec :
    - Render navbar (`layouts/navbar`)
    - Conteneur flex avec sidebar + contenu
    - Sidebar : `render 'admin/shared/sidebar'`
    - Main : conteneur avec flash messages + yield
    - Footer optionnel
- [ ] **Note** : Utiliser `stylesheet_link_tag "application.bootstrap"` comme dans `application.html.erb`
- [ ] **Vérifier** : Layout charge sans erreur

---

## ✅ Phase 3 : Vues Dashboard

### 5. Dossier vues
- [ ] **Créer** : `app/views/admin_panel/` (dossier)
- [ ] **Créer** : `app/views/admin_panel/dashboard/` (sous-dossier)

### 6. Vue Dashboard
- [ ] **Fichier** : `app/views/admin_panel/dashboard/index.html.erb` (CRÉER)
- [ ] **Contenu** :
  - Header avec titre "Dashboard Admin" et message bienvenue
  - 4 cartes statistiques (row avec col-md-6 col-lg-3) :
    - Utilisateurs (card avec `@stats[:total_users]`)
    - Produits (card avec `@stats[:total_products]`)
    - Commandes (card avec `@stats[:total_orders]`)
    - En attente (card avec `@stats[:pending_orders]`)
  - Table commandes récentes :
    - Card avec card-header
    - Table responsive avec colonnes : ID, Client, Total, Statut, Date
    - Badge Bootstrap pour statut
    - Message "Aucune commande récente" si vide
- [ ] **Classes** : Bootstrap de base uniquement (`card`, `table`, `badge`, `row`, `col-*`)
- [ ] **Vérifier** : Vue s'affiche correctement avec données

---

## ✅ Phase 4 : Adaptation Sidebar

### 7. Sidebar - Routes
- [ ] **Fichier** : `app/views/admin/shared/_sidebar.html.erb` (MODIFIER)
- [ ] **Action** : Remplacer `admin_root_path` par `admin_panel_root_path`
  - Ligne 29 : Dashboard link
  - Ligne 360 : Dashboard link (mobile offcanvas)
- [ ] **Vérifier** : Liens pointent vers `/admin-panel`

### 8. Sidebar - Stimulus Controller
- [ ] **Vérifier** : Le controller `admin-sidebar` est référencé dans la sidebar (ligne 10)
- [ ] **Fichier** : `app/javascript/controllers/admin/admin_sidebar_controller.js` (CRÉER si manquant)
- [ ] **Dossier** : Créer `app/javascript/controllers/admin/` si nécessaire
- [ ] **Contenu** (si création) :
  ```javascript
  import { Controller } from "@hotwired/stimulus"
  
  export default class extends Controller {
    static targets = ["sidebar"]
    
    connect() {
      const saved = localStorage.getItem('admin:sidebar:collapsed')
      if (saved === 'true' && window.innerWidth >= 992) {
        this.collapse()
      }
    }
    
    toggle() { /* ... */ }
    collapse() { /* ... */ }
    expand() { /* ... */ }
  }
  ```
- [ ] **Vérifier** : Controller Stimulus fonctionne (collapse/expand sidebar)

---

## ✅ Phase 5 : Navbar Integration

### 9. Navbar - Dropdown Admin
- [ ] **Fichier** : `app/views/layouts/_navbar.html.erb` (MODIFIER)
- [ ] **Action** : Remplacer lignes 121-132 (section admin)
- [ ] **Nouveau code** :
  ```erb
  <% if current_user.role&.code.in?(%w[ADMIN SUPERADMIN]) %>
    <li><hr class="dropdown-divider"></li>
    
    <!-- NOUVEAU PANEL ADMIN -->
    <li>
      <%= link_to admin_panel_root_path, class: "dropdown-item" do %>
        <i class="bi bi-shield-check me-2" aria-hidden="true"></i>Administration
      <% end %>
    </li>
    
    <!-- ACTIVE ADMIN (Legacy) -->
    <li>
      <%= link_to Rails.application.routes.url_helpers.activeadmin_root_path, class: "dropdown-item" do %>
        <i class="bi bi-gear me-2" aria-hidden="true"></i>Active Admin
      <% end %>
    </li>
  <% end %>
  ```
- [ ] **Vérifier** : Dropdown affiche "Administration" et "Active Admin" pour les admins

---

## ✅ Phase 6 : Tests & Validation

### 10. Test Route & Authentification
- [ ] **Action** : Tester route `/admin-panel`
- [ ] **Vérifier** :
  - Si utilisateur non connecté → redirige vers login
  - Si utilisateur connecté mais pas admin → redirige avec message "Accès administrateur requis"
  - Si utilisateur admin → affiche dashboard
- [ ] **Note** : Tester avec différents rôles (USER, ADMIN, SUPERADMIN)

### 11. Test Layout & Sidebar
- [ ] **Vérifier** :
  - Layout admin s'affiche correctement
  - Navbar principale visible en haut
  - Sidebar visible à gauche (desktop)
  - Contenu dashboard dans le main
  - Footer visible en bas

### 12. Test Dark Mode
- [ ] **Action** : Toggle dark mode depuis navbar
- [ ] **Vérifier** :
  - Sidebar suit le thème (background/text)
  - Dashboard suit le thème (cartes, table)
  - Cohérence visuelle avec le reste de l'app

### 13. Test Responsive
- [ ] **Desktop (≥992px)** :
  - Sidebar visible à gauche
  - Hamburger toggle fonctionne (collapse/expand)
  - Largeur sidebar : 280px (expanded) / 64px (collapsed)
- [ ] **Mobile (<992px)** :
  - Sidebar cachée par défaut
  - Hamburger button visible (top-left)
  - Offcanvas s'ouvre au clic
  - Backdrop ferme l'offcanvas

### 14. Test Données Dashboard
- [ ] **Vérifier** :
  - Statistiques affichent les bonnes valeurs (User.count, Product.count, etc.)
  - Table commandes affiche les 5 dernières commandes
  - Client affiche email (via `order.user.email`)
  - Total formaté en euros (`number_to_currency`)
  - Statut affiché avec badge

### 15. Test Stimulus Sidebar
- [ ] **Vérifier** :
  - Bouton toggle fonctionne (collapse/expand)
  - État sauvegardé dans localStorage
  - État restauré au rechargement page
  - Fonctionne uniquement sur desktop (≥992px)

---

## 📝 Notes Importantes

### Points d'Attention
1. **Stylesheet** : Utiliser `application.bootstrap` (pas `application`)
2. **Routes** : Namespace `/admin-panel` (pas `/admin` pour éviter conflit)
3. **Authentification** : Vérifier `role.code` dans `%w[ADMIN SUPERADMIN]`
4. **Classes Bootstrap** : Utiliser uniquement classes de base pour l'instant
5. **Sidebar** : Déjà existe, juste adapter les routes

### Fichiers Créés
- `app/controllers/admin_panel/base_controller.rb`
- `app/controllers/admin_panel/dashboard_controller.rb`
- `app/views/layouts/admin.html.erb`
- `app/views/admin_panel/dashboard/index.html.erb`
- `app/javascript/controllers/admin/admin_sidebar_controller.js` (si création nécessaire)

### Fichiers Modifiés
- `config/routes.rb`
- `app/views/layouts/_navbar.html.erb`
- `app/views/admin/shared/_sidebar.html.erb`

---

**Référence** : [BASE_UX_UI_PANEL.md](ressources/decisions/BASE_UX_UI_PANEL.md)
