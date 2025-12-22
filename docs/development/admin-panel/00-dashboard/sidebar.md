# 🎨 SIDEBAR ADMIN PANEL - Documentation Technique

**Date** : 2025-12-22 | **Version** : 2.0 | **Status** : ✅ **IMPLÉMENTÉ**

---

## 📋 Vue d'Ensemble

Sidebar responsive avec collapse/expand, permissions par grade, et optimisations performance.

**Menu Actuel (2025-12-22)** :
- ✅ Initiations (level >= 30)
- ✅ Commandes (level >= 60)
- ✅ ActiveAdmin (lien externe)
- ❌ Tableau de bord (retiré - non conforme)
- ❌ Boutique (retiré - non conforme)

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

### **⚠️ Important : Footer et Déconnexion**

**Footer de l'application** :
- Le layout admin (`app/views/layouts/admin.html.erb`) utilise maintenant le footer standard de l'application (`_footer-simple.html.erb`)
- Cohérence visuelle avec le reste du site

**Déconnexion et informations utilisateur** :
- ❌ **Supprimé de la sidebar** : Le footer avec email et déconnexion a été retiré
- ✅ **Disponible dans la navbar** : Ces éléments sont accessibles via le menu déroulant utilisateur dans la navbar principale
- **Raison** : Éviter la redondance et améliorer la cohérence UX

---

## 🎯 Fonctionnalités

### ✅ **1. Menu Actuel (2025-12-22)**

**Structure du menu sidebar** :
1. **Initiations** (level >= 30)
   - Icône : `bi-people`
   - Route : `admin_panel_initiations_path`
   - Permissions : Lecture (level >= 30), Écriture (level >= 60)

2. **Commandes** (level >= 60)
   - Icône : `bi-box-seam`
   - Route : `admin_panel_orders_path`
   - Permissions : Accès complet (level >= 60)

3. **Séparateur** (`<hr>`)

4. **ActiveAdmin** (lien externe)
   - Icône : `bi-gear`
   - Route : `/activeadmin`
   - Accessible à tous (ouvre dans un nouvel onglet)

**Modules retirés** (non conformes) :
- ❌ **Tableau de bord** - Retiré le 2025-12-22 (non conforme)
- ❌ **Boutique** - Retiré le 2025-12-22 avec ses sous-menus (non conforme)

**Code actuel** :
```erb
<!-- Initiations -->
<% if can_view_initiations? %>
  <li class="nav-item">
    <%= link_to admin_panel_initiations_path, class: "nav-link..." %>
  </li>
<% end %>

<!-- Commandes -->
<% if can_access_admin_panel?(60) %>
  <li class="nav-item">
    <%= link_to admin_panel_orders_path, class: "nav-link..." %>
  </li>
<% end %>

<!-- ActiveAdmin -->
<li class="nav-item">
  <%= link_to "/activeadmin", target: "_blank", class: "nav-link..." %>
</li>
```

---

### ✅ **2. Partial Réutilisable**

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

### ✅ **2. Menu Actuel (2025-12-22)**

**Structure du menu** :
- ✅ **Initiations** (level >= 30) → `admin_panel_initiations_path`
- ✅ **Commandes** (level >= 60) → `admin_panel_orders_path`
- ✅ **Séparateur**
- ✅ **ActiveAdmin** (lien externe) → `/activeadmin`

**Modules retirés** (non conformes) :
- ❌ **Tableau de bord** - Retiré (non conforme)
- ❌ **Boutique** - Retiré avec ses sous-menus (non conforme)

**Raison** : Focus sur les modules réellement implémentés et fonctionnels.

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

### ✅ **5. Controller Stimulus Optimisé**

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

### ✅ **7. JavaScript Séparé**

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

### **Tableau des Accès (État Actuel - 2025-12-22)**

| Grade | Level | Initiations | Commandes | ActiveAdmin |
|-------|-------|-------------|-----------|------------|
| INITIATION | 30 | ✅ Lecture | ❌ | ✅ (lien externe) |
| ORGANIZER | 40 | ✅ Lecture | ❌ | ✅ (lien externe) |
| MODERATOR | 50 | ✅ Lecture | ❌ | ✅ (lien externe) |
| ADMIN | 60 | ✅ Complet | ✅ Complet | ✅ (lien externe) |
| SUPERADMIN | 70 | ✅ Complet | ✅ Complet | ✅ (lien externe) |

### **Implémentation dans la Sidebar**

```erb
<!-- Initiations : level >= 30 -->
<% if can_view_initiations? %>
  <li class="nav-item">...</li>
<% end %>

<!-- Commandes : level >= 60 -->
<% if can_access_admin_panel?(60) %>
  <li class="nav-item">...</li>
<% end %>

<!-- ActiveAdmin : Accessible à tous (lien externe) -->
<li class="nav-item">...</li>
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
- ✅ Icônes visibles
- ✅ Contenu principal : `margin-left: 280px`
- ✅ Transitions fluides (300ms cubic-bezier)

### **Sidebar Collapsed (64px)**
- ✅ Labels masqués (`.d-none`)
- ✅ Icônes visibles (centrées)
- ✅ Contenu principal : `margin-left: 64px`
- ✅ Transitions fluides (300ms cubic-bezier)

---

## 💾 Persistance

**LocalStorage** : État collapsed/expanded sauvegardé
- Clé : `admin:sidebar:collapsed`
- Valeurs : `'true'` ou `'false'`
- Restauration automatique au chargement

---

## ✅ Checklist Implémentation

- [x] Partial réutilisable `_menu_items.html.erb`
- [x] Helpers permissions (`can_access_admin_panel?`, etc.)
- [x] Controller Stimulus optimisé (7 problèmes corrigés)
- [x] CSS organisé dans `_style.scss` (liquid glass)
- [x] JavaScript séparé (`admin_panel_navbar.js`)
- [x] Suppression styles inline
- [x] Transitions fluides
- [x] Responsive desktop/mobile
- [x] Persistance LocalStorage
- [x] Footer sidebar supprimé (redondant avec navbar)
- [x] Menu épuré (Tableau de bord et Boutique retirés)

---

## 🚀 Prochaines Améliorations (Optionnel)

- [ ] Tooltips au rétrécissement (sidebar collapsed)
- [ ] Animation plus sophistiquée (slide)
- [ ] Thème dark/light adaptatif
- [ ] Ajout de nouveaux modules conformes dans la sidebar

---

**Retour** : [Dashboard README](./README.md) | [INDEX principal](../INDEX.md)
