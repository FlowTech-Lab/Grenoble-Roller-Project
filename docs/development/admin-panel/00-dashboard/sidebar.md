# 🎨 SIDEBAR ADMIN PANEL - Documentation Technique

**Date** : 2025-01-XX | **Version** : 1.0 | **Status** : ✅ **IMPLÉMENTÉ**

---

## 📋 Vue d'Ensemble

Sidebar responsive avec collapse/expand, sous-menus, permissions par grade, et optimisations performance.

**Fichiers principaux** :
- `app/views/admin/shared/_sidebar.html.erb` - Template principal
- `app/views/admin/shared/_menu_items.html.erb` - Partial réutilisable (desktop + mobile)
- `app/javascript/controllers/admin/admin_sidebar_controller.js` - Controller Stimulus optimisé
- `app/assets/stylesheets/admin_panel.scss` - Styles dédiés
- `app/javascript/admin_panel_navbar.js` - Calcul hauteur navbar
- `app/helpers/admin_panel_helper.rb` - Helpers permissions

---

## 🏗️ Architecture

### **Structure des Fichiers**

```
app/
├── views/admin/shared/
│   ├── _sidebar.html.erb          # Template principal (desktop + mobile)
│   └── _menu_items.html.erb       # Partial menu réutilisable
├── javascript/
│   ├── controllers/admin/
│   │   └── admin_sidebar_controller.js  # Controller Stimulus
│   └── admin_panel_navbar.js      # Calcul hauteur navbar
├── assets/stylesheets/
│   └── admin_panel.scss           # Styles sidebar
└── helpers/
    └── admin_panel_helper.rb      # Helpers permissions
```

---

## 🎯 Fonctionnalités

### ✅ **1. Partial Réutilisable**

**Fichier** : `app/views/admin/shared/_menu_items.html.erb`

- ✅ **DRY** : Un seul partial pour desktop ET mobile
- ✅ **Paramètre `mobile`** : Adapte le comportement (offcanvas dismiss)
- ✅ **Permissions intégrées** : Utilise les helpers `can_access_admin_panel?()`

**Utilisation** :
```erb
<!-- Desktop -->
<%= render 'admin/shared/menu_items', mobile: false %>

<!-- Mobile -->
<%= render 'admin/shared/menu_items', mobile: true %>
```

---

### ✅ **2. Sous-menus avec Collapse/Expand**

**Section Boutique** avec sous-menus Bootstrap :
- **Produits** → `admin_panel_products_path`
- **Inventaire** → TODO (route à ajouter)
- **Catégories** → `admin_panel_product_categories_path`

**Fonctionnalités** :
- ✅ Collapse/expand avec Bootstrap
- ✅ Icône chevron qui change (right ↔ down)
- ✅ État actif détecté automatiquement (parent + enfants)
- ✅ ID unique par instance (desktop/mobile)

**Code** :
```erb
<a class="nav-link" 
   href="#collapse-boutique" 
   data-bs-toggle="collapse">
  <i class="bi bi-shop"></i>
  <span class="sidebar-label">Boutique</span>
  <i class="bi bi-chevron-right ms-auto"></i>
</a>
<div class="collapse" id="collapse-boutique">
  <ul class="nav nav-pills flex-column ms-3">
    <!-- Sous-menus -->
  </ul>
</div>
```

---

### ✅ **3. Helpers Permissions**

**Fichier** : `app/helpers/admin_panel_helper.rb`

**Helpers créés** :
```ruby
# Vérification par niveau
can_access_admin_panel?(min_level = 60)

# Helpers spécifiques
can_view_initiations?  # level >= 30
can_view_boutique?     # level >= 60

# Détection état actif
admin_panel_active?(controller_name, action_name = nil)
```

**Avantages** :
- ✅ **Maintenabilité** : Plus de `current_user&.role&.level.to_i >= X` répétés
- ✅ **Lisibilité** : Code plus clair dans les vues
- ✅ **Cohérence** : Un seul endroit pour les règles

---

### ✅ **4. Controller Stimulus Optimisé**

**Fichier** : `app/javascript/controllers/admin/admin_sidebar_controller.js`

**7 Problèmes Critiques Corrigés** :

| # | Problème | Solution |
|---|----------|----------|
| 1 | Pas debounce resize | ✅ `debounce(250ms)` |
| 2 | Magic strings hardcodés | ✅ `static values` (constantes) |
| 3 | Pas responsive breakpoint sync | ✅ Media query observer |
| 4 | DOM queries inefficaces | ✅ Cache refs (`cacheRefs()`) |
| 5 | Style inline vs CSS | ✅ Bootstrap `.d-none` |
| 6 | Pas guard clauses | ✅ Early returns |
| 7 | Pas cleanup listener | ✅ `disconnect()` complet |

**Constantes Configurables** :
```javascript
static values = {
  collapsedWidth: { type: String, default: "64px" },
  expandedWidth: { type: String, default: "280px" },
  breakpoint: { type: Number, default: 992 },
  debounceMs: { type: Number, default: 250 }
}
```

**Méthodes Principales** :
- `connect()` - Initialisation + cache refs + restore state
- `disconnect()` - Cleanup complet (listeners + refs)
- `toggle()` - Collapse/expand avec sauvegarde
- `collapse()` / `expand()` - Actions avec transitions
- `setupMediaQueryObserver()` - Responsive sync
- `setupResizeHandler()` - Debounce resize

---

### ✅ **5. CSS Organisé**

**Fichier** : `app/assets/stylesheets/admin_panel.scss`

**Classes CSS Sémantiques** :
```scss
.admin-sidebar              // Sidebar principale
.admin-sidebar-toggle       // Bouton toggle
.admin-main-content         // Contenu principal
.admin-container            // Conteneur admin
.admin-mobile-menu-toggle   // Bouton hamburger mobile
```

**Variables CSS** :
```scss
:root {
  --navbar-height: 76px; // Calculé dynamiquement
}
```

**Transitions Fluides** :
- Sidebar width : `300ms cubic-bezier(0.4, 0, 0.2, 1)`
- Main content margin : `300ms cubic-bezier(0.4, 0, 0.2, 1)`
- Labels/chevrons : `200ms ease` (opacity + visibility)

**Import** : Ajouté dans `application.bootstrap.scss` :
```scss
@use "admin_panel" as *;
```

---

### ✅ **6. JavaScript Séparé**

**Fichier** : `app/javascript/admin_panel_navbar.js`

**Fonctionnalité** : Calcul dynamique de la hauteur de la navbar

**Code** :
```javascript
document.addEventListener('DOMContentLoaded', function() {
  const navbar = document.querySelector('.navbar');
  if (navbar) {
    const navbarHeight = navbar.offsetHeight;
    document.documentElement.style.setProperty('--navbar-height', navbarHeight + 'px');
    
    // Mettre à jour la sidebar
    const sidebar = document.getElementById('sidebar');
    if (sidebar) {
      sidebar.style.top = navbarHeight + 'px';
      sidebar.style.height = `calc(100vh - ${navbarHeight}px)`;
    }
  }
});
```

**Import** : Ajouté dans `config/importmap.rb` et chargé dans le layout :
```ruby
pin "admin_panel_navbar", to: "admin_panel_navbar.js"
```

```erb
<script type="module">
  import "admin_panel_navbar";
</script>
```

---

## 🔐 Permissions par Grade

### **Tableau des Accès**

| Grade | Level | Dashboard | Boutique | Initiations | Commandes |
|-------|-------|-----------|----------|-------------|-----------|
| INITIATION | 30 | ❌ | ❌ | ✅ Lecture | ❌ |
| ORGANIZER | 40 | ❌ | ❌ | ✅ Lecture | ❌ |
| MODERATOR | 50 | ❌ | ❌ | ✅ Lecture | ❌ |
| ADMIN | 60 | ✅ | ✅ | ✅ Complet | ✅ |
| SUPERADMIN | 70 | ✅ | ✅ | ✅ Complet | ✅ |

### **Implémentation dans la Sidebar**

```erb
<!-- Dashboard : level >= 60 -->
<% if can_access_admin_panel?(60) %>
  <li class="nav-item">...</li>
<% end %>

<!-- Boutique : level >= 60 -->
<% if can_view_boutique? %>
  <li class="nav-item">...</li>
<% end %>

<!-- Initiations : level >= 30 -->
<% if can_view_initiations? %>
  <li class="nav-item">...</li>
<% end %>
```

**Voir** : [`../PERMISSIONS.md`](../PERMISSIONS.md) pour la documentation complète.

---

## 📱 Responsive

### **Desktop (≥ 992px)**
- ✅ Sidebar fixe à gauche
- ✅ Collapse/expand fonctionnel
- ✅ Sous-menus avec collapse
- ✅ Bouton toggle visible

### **Mobile (< 992px)**
- ✅ Sidebar masquée (offcanvas)
- ✅ Bouton hamburger visible
- ✅ Menu dans offcanvas
- ✅ Même partial `_menu_items.html.erb`

---

## 🎨 États Visuels

### **Sidebar Expanded (280px)**
- ✅ Labels visibles
- ✅ Chevrons visibles
- ✅ Sous-menus accessibles
- ✅ Contenu principal : `margin-left: 280px`

### **Sidebar Collapsed (64px)**
- ✅ Labels masqués (`.d-none`)
- ✅ Chevrons masqués (`.d-none`)
- ✅ Sous-menus masqués
- ✅ Contenu principal : `margin-left: 64px`
- ✅ Transitions fluides

---

## 💾 Persistance

**LocalStorage** : État collapsed/expanded sauvegardé
- Clé : `admin:sidebar:collapsed`
- Valeurs : `'true'` ou `'false'`
- Restauration automatique au chargement

---

## ✅ Checklist Implémentation

- [x] Partial réutilisable `_menu_items.html.erb`
- [x] Sous-menus Boutique avec collapse/expand
- [x] Helpers permissions (`can_access_admin_panel?`, etc.)
- [x] Controller Stimulus optimisé (7 problèmes corrigés)
- [x] CSS organisé dans `admin_panel.scss`
- [x] JavaScript séparé (`admin_panel_navbar.js`)
- [x] Suppression styles inline
- [x] Transitions fluides
- [x] Responsive desktop/mobile
- [x] Persistance LocalStorage

---

## 🚀 Prochaines Améliorations (Optionnel)

- [ ] Tooltips au rétrécissement (sidebar collapsed)
- [ ] LocalStorage pour état des sous-menus (collapsed/expanded)
- [ ] Animation plus sophistiquée (slide)
- [ ] Thème dark/light adaptatif

---

**Retour** : [Dashboard README](./README.md) | [INDEX principal](../INDEX.md)
