# Guide Sidebar Collapsible - Bootstrap 5.3.2 + Stimulus + Rails

## Comparatif des 3 Approches

| Approche | Avantages | Inconvénients | Cas d'usage |
|----------|-----------|---------------|-----------|
| **Offcanvas (Mobile-first)** | Native Bootstrap, idéal mobile, overlay, backdrop inclus | Overlay par défaut, moins flexible desktop | Mobile/tablet primary, desktop optional |
| **Collapse Horizontal (Hybrid)** | Contrôle fin, "push" layout, sidebar fixe, animations smooth | CSS custom minimum, plus de JS | Préféré: desktop/tablet fixe + mobile offcanvas |
| **Custom CSS + Stimulus** | Totale flexibilité, animations précises, UX optimisée | Maintenance personnalisée | Admin panels sophistiqués, branding custom |

---

## APPROCHE 1: Offcanvas + Collapse Hybrid (⭐ RECOMMANDÉE)

**Meilleur compromise: Desktop/Tablet sidebar fixe collapsible + Mobile offcanvas**

### Architecture

```
Desktop (≥1200px):   Sidebar fixe 280px (expanded) / 64px (collapsed) + toggle
Tablet (768-1200px): Sidebar fixe collapsed (64px) par défaut, expandable
Mobile (<768px):     Offcanvas hidden + hamburger, layout 100% content
```

### 1. Structure HTML (app/views/layouts/admin.html.erb)

```erb
<div class="d-flex min-vh-100" id="admin-wrapper">
  <!-- SIDEBAR: Desktop/Tablet (hidden on mobile) -->
  <aside class="d-none d-lg-flex flex-column bg-light border-end" 
         id="sidebar" 
         data-sidebar-toggle-target="sidebar"
         style="width: 280px; transition: width 300ms ease;">
    
    <div class="p-3 border-bottom d-flex align-items-center justify-content-between">
      <span class="d-inline" id="sidebar-logo-text">Admin Panel</span>
      <!-- Toggle visible au-dessus de lg seulement -->
      <button class="btn btn-sm btn-ghost d-lg-none" 
              data-bs-toggle="offcanvas" 
              data-bs-target="#offcanvasSidebar"
              aria-label="Toggle menu">
        <i class="bi bi-list"></i>
      </button>
    </div>

    <!-- Navigation menu -->
    <nav class="flex-grow-1 overflow-y-auto px-2 py-3">
      <ul class="nav nav-pills flex-column gap-2">
        <!-- Menu item simple -->
        <li class="nav-item">
          <a href="/admin/dashboard" class="nav-link d-flex align-items-center gap-2" 
             data-tooltip-placement="right" 
             title="Dashboard">
            <i class="bi bi-speedometer2 fs-5"></i>
            <span class="sidebar-label">Dashboard</span>
          </a>
        </li>

        <!-- Menu item avec submenu collapsible -->
        <li class="nav-item">
          <button class="nav-link w-100 d-flex align-items-center gap-2 text-start"
                  data-bs-toggle="collapse"
                  data-bs-target="#submenu-users"
                  aria-expanded="false"
                  title="Users"
                  data-tooltip-placement="right">
            <i class="bi bi-people fs-5"></i>
            <span class="sidebar-label">Users</span>
            <i class="bi bi-chevron-down ms-auto sidebar-label"></i>
          </button>
          <div class="collapse" id="submenu-users">
            <ul class="nav nav-pills flex-column ms-3 gap-1 mt-2">
              <li class="nav-item">
                <a href="/admin/users" class="nav-link small">
                  <span class="sidebar-label">List Users</span>
                </a>
              </li>
              <li class="nav-item">
                <a href="/admin/users/new" class="nav-link small">
                  <span class="sidebar-label">New User</span>
                </a>
              </li>
            </ul>
          </div>
        </li>

        <li class="nav-item">
          <a href="/admin/settings" class="nav-link d-flex align-items-center gap-2"
             data-tooltip-placement="right"
             title="Settings">
            <i class="bi bi-gear fs-5"></i>
            <span class="sidebar-label">Settings</span>
          </a>
        </li>
      </ul>
    </nav>

    <!-- Footer (collapse info when collapsed) -->
    <div class="p-3 border-top small text-muted">
      <span class="sidebar-label">v1.0.0</span>
    </div>
  </aside>

  <!-- OFFCANVAS: Mobile only -->
  <div class="offcanvas offcanvas-start" tabindex="-1" id="offcanvasSidebar" 
       aria-labelledby="offcanvasSidebarLabel"
       data-bs-backdrop="true"
       data-bs-scroll="false">
    <div class="offcanvas-header border-bottom">
      <h5 class="offcanvas-title" id="offcanvasSidebarLabel">Menu</h5>
      <button type="button" class="btn-close" data-bs-dismiss="offcanvas" 
              aria-label="Close"></button>
    </div>
    <div class="offcanvas-body p-0">
      <!-- Cloner le même menu navigation -->
      <nav class="py-3">
        <ul class="nav nav-pills flex-column gap-2 px-2">
          <li class="nav-item">
            <a href="/admin/dashboard" class="nav-link" data-bs-dismiss="offcanvas">
              <i class="bi bi-speedometer2"></i> Dashboard
            </a>
          </li>
          <li class="nav-item">
            <button class="nav-link w-100 text-start d-flex align-items-center gap-2"
                    data-bs-toggle="collapse"
                    data-bs-target="#offcanvas-submenu-users">
              <i class="bi bi-people"></i> Users
              <i class="bi bi-chevron-down ms-auto"></i>
            </button>
            <div class="collapse" id="offcanvas-submenu-users">
              <ul class="nav flex-column ms-3 gap-1 mt-2">
                <li class="nav-item">
                  <a href="/admin/users" class="nav-link small" data-bs-dismiss="offcanvas">
                    List Users
                  </a>
                </li>
              </ul>
            </div>
          </li>
          <li class="nav-item">
            <a href="/admin/settings" class="nav-link" data-bs-dismiss="offcanvas">
              <i class="bi bi-gear"></i> Settings
            </a>
          </li>
        </ul>
      </nav>
    </div>
  </div>

  <!-- MAIN CONTENT -->
  <main class="flex-grow-1 overflow-auto">
    <div class="container-fluid p-4">
      <%= yield %>
    </div>
  </main>
</div>

<!-- Toggle button (fixed desktop top-left) -->
<button class="btn btn-outline-secondary position-fixed bottom-0 start-0 m-3 d-none d-lg-block"
        id="sidebar-toggle"
        data-sidebar-toggle-target="toggle"
        title="Toggle sidebar"
        style="z-index: 1020;">
  <i class="bi bi-layout-sidebar-inset"></i>
</button>

<!-- Hamburger button (fixed mobile top) -->
<div class="d-lg-none position-fixed top-0 start-0 p-3" style="z-index: 1030;">
  <button class="btn btn-outline-secondary"
          data-bs-toggle="offcanvas"
          data-bs-target="#offcanvasSidebar"
          aria-label="Toggle menu">
    <i class="bi bi-list"></i>
  </button>
</div>
```

### 2. Stylesheet (app/assets/stylesheets/admin_sidebar.css)

```css
/* ===== ROOT VARIABLES ===== */
:root {
  --sidebar-expanded-width: 280px;
  --sidebar-collapsed-width: 64px;
  --sidebar-transition: 300ms cubic-bezier(0.4, 0, 0.2, 1);
  --sidebar-bg: #f8f9fa;
  --sidebar-border: #dee2e6;
  --sidebar-text: #495057;
  --sidebar-hover: #e9ecef;
  --sidebar-active: #0d6efd;
}

/* ===== SIDEBAR BASE STYLES ===== */
#sidebar {
  width: var(--sidebar-expanded-width);
  transition: width var(--sidebar-transition);
  background-color: var(--sidebar-bg);
  border-color: var(--sidebar-border);
  position: relative;
  z-index: 1000;
}

#sidebar.collapsed {
  width: var(--sidebar-collapsed-width);
}

/* Logo/Header */
#sidebar .p-3 {
  min-height: 60px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

/* Logo text - hide when collapsed */
#sidebar-logo-text {
  transition: opacity var(--sidebar-transition);
  font-weight: 600;
  color: var(--sidebar-text);
}

#sidebar.collapsed #sidebar-logo-text {
  opacity: 0;
  width: 0;
  overflow: hidden;
}

/* ===== NAVIGATION MENU ===== */
#sidebar .nav-link {
  color: var(--sidebar-text);
  border-radius: 6px;
  transition: all 200ms ease;
  padding: 0.5rem 0.75rem;
  position: relative;
}

#sidebar .nav-link:hover {
  background-color: var(--sidebar-hover);
  color: var(--sidebar-active);
}

#sidebar .nav-link.active {
  background-color: var(--sidebar-active);
  color: white;
}

#sidebar .nav-link .bi {
  font-size: 1.25rem;
  flex-shrink: 0;
}

/* Labels visibility based on sidebar state */
.sidebar-label {
  transition: opacity var(--sidebar-transition), width var(--sidebar-transition);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

#sidebar.collapsed .sidebar-label {
  opacity: 0;
  width: 0;
  margin: 0;
}

/* Chevron rotation for collapsed state */
#sidebar.collapsed .bi-chevron-down {
  display: none;
}

/* ===== SUBMENU STYLING ===== */
#sidebar .collapse {
  transition: max-height var(--sidebar-transition);
}

#sidebar .nav.flex-column.ms-3 {
  border-left: 2px solid var(--sidebar-border);
  padding-left: 0.5rem;
}

#sidebar.collapsed .nav.flex-column.ms-3 {
  display: none;
}

/* ===== TOOLTIP STYLING ===== */
#sidebar.collapsed .nav-link[data-tooltip-placement="right"] {
  position: relative;
}

#sidebar.collapsed .nav-link[data-tooltip-placement="right"]::after {
  content: attr(title);
  position: absolute;
  left: 100%;
  top: 50%;
  transform: translateY(-50%);
  margin-left: 8px;
  background-color: #212529;
  color: white;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 0.875rem;
  white-space: nowrap;
  opacity: 0;
  pointer-events: none;
  transition: opacity 200ms ease;
  z-index: 1040;
}

#sidebar.collapsed .nav-link[data-tooltip-placement="right"]:hover::after {
  opacity: 1;
}

/* ===== MAIN CONTENT ADJUSTMENT ===== */
#admin-wrapper main {
  transition: margin-left var(--sidebar-transition);
}

/* Desktop: adjust main when sidebar changes */
@media (min-width: 1200px) {
  #admin-wrapper.sidebar-expanded main {
    margin-left: 0;
  }
  
  #admin-wrapper.sidebar-collapsed main {
    margin-left: 0;
  }
}

/* ===== OFFCANVAS MOBILE CUSTOMIZATION ===== */
.offcanvas {
  width: 75vw !important;
}

@media (min-width: 480px) {
  .offcanvas {
    width: 350px !important;
  }
}

.offcanvas .nav-link {
  padding: 0.75rem 1rem;
  border-radius: 6px;
  margin: 0 0.5rem;
  transition: all 200ms ease;
}

.offcanvas .nav-link:hover {
  background-color: var(--sidebar-hover);
  color: var(--sidebar-active);
}

.offcanvas .nav-link i {
  margin-right: 0.5rem;
}

/* ===== RESPONSIVE ADJUSTMENTS ===== */
/* Tablet: sidebar always visible but compact */
@media (max-width: 1199px) {
  #sidebar {
    width: var(--sidebar-collapsed-width);
  }
  
  #sidebar.expanded {
    width: var(--sidebar-expanded-width);
  }
}

/* Mobile: hide sidebar, show offcanvas */
@media (max-width: 991px) {
  #sidebar {
    display: none !important;
  }
}

/* ===== DARK MODE SUPPORT ===== */
@media (prefers-color-scheme: dark) {
  :root {
    --sidebar-bg: #1a1a1a;
    --sidebar-border: #333;
    --sidebar-text: #b0b0b0;
    --sidebar-hover: #2a2a2a;
  }
  
  #sidebar {
    background-color: var(--sidebar-bg);
    border-color: var(--sidebar-border);
  }
  
  #sidebar .nav-link {
    color: var(--sidebar-text);
  }
  
  #sidebar .nav-link:hover {
    background-color: var(--sidebar-hover);
  }
}

/* ===== SCROLLBAR STYLING ===== */
#sidebar nav::-webkit-scrollbar {
  width: 6px;
}

#sidebar nav::-webkit-scrollbar-track {
  background: transparent;
}

#sidebar nav::-webkit-scrollbar-thumb {
  background: rgba(0, 0, 0, 0.1);
  border-radius: 3px;
}

#sidebar nav::-webkit-scrollbar-thumb:hover {
  background: rgba(0, 0, 0, 0.2);
}

/* Dark mode scrollbar */
@media (prefers-color-scheme: dark) {
  #sidebar nav::-webkit-scrollbar-thumb {
    background: rgba(255, 255, 255, 0.1);
  }
  
  #sidebar nav::-webkit-scrollbar-thumb:hover {
    background: rgba(255, 255, 255, 0.2);
  }
}
```

### 3. Stimulus Controller (app/javascript/controllers/sidebar_toggle_controller.js)

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "toggle"]
  static values = { 
    persistKey: String 
  }

  connect() {
    // Initialize from localStorage
    const isCollapsed = this.getStoredState()
    this.setCollapsedState(isCollapsed)
    
    // Setup event listeners for Bootstrap Collapse
    this.setupCollapseListeners()
  }

  // Toggle sidebar state
  toggle(event) {
    event?.preventDefault()
    const isCurrentlyCollapsed = this.isCollapsed()
    this.setCollapsedState(!isCurrentlyCollapsed)
  }

  // Set collapsed/expanded state
  setCollapsedState(shouldCollapse) {
    if (shouldCollapse) {
      this.sidebarTarget.classList.add("collapsed")
    } else {
      this.sidebarTarget.classList.remove("collapsed")
    }
    
    // Close any open submenus when collapsing
    if (shouldCollapse) {
      this.closeAllSubmenus()
    }
    
    // Save to localStorage
    this.storeState(shouldCollapse)
    
    // Dispatch event for other listeners
    this.dispatch("sidebar:toggled", { detail: { collapsed: shouldCollapse } })
  }

  // Check if sidebar is collapsed
  isCollapsed() {
    return this.sidebarTarget.classList.contains("collapsed")
  }

  // Close all expanded submenus
  closeAllSubmenus() {
    const collapses = this.sidebarTarget.querySelectorAll(".collapse.show")
    collapses.forEach(collapse => {
      const bsCollapse = bootstrap.Collapse.getInstance(collapse)
      if (bsCollapse) {
        bsCollapse.hide()
      }
    })
  }

  // LocalStorage management
  getStoredState() {
    const stored = localStorage.getItem(this.persistKeyValue || "sidebar-collapsed")
    return stored === "true"
  }

  storeState(isCollapsed) {
    localStorage.setItem(this.persistKeyValue || "sidebar-collapsed", isCollapsed.toString())
  }

  // Bootstrap Collapse integration
  setupCollapseListeners() {
    const collapses = this.sidebarTarget.querySelectorAll("[data-bs-toggle='collapse']")
    
    collapses.forEach(button => {
      button.addEventListener("show.bs.collapse", (e) => {
        // Only one submenu open at a time (optional)
        this.closeOtherSubmenus(e.target.id)
      })
    })
  }

  closeOtherSubmenus(currentId) {
    const collapses = this.sidebarTarget.querySelectorAll(".collapse.show")
    collapses.forEach(collapse => {
      if (collapse.id !== currentId) {
        const bsCollapse = bootstrap.Collapse.getInstance(collapse)
        if (bsCollapse) {
          bsCollapse.hide()
        }
      }
    })
  }

  // Accessibility: keyboard navigation
  handleKeydown(event) {
    if (event.key === "Escape") {
      this.setCollapsedState(true)
    }
    
    if (event.ctrlKey && event.key === "/") {
      event.preventDefault()
      this.toggle()
    }
  }
}
```

### 4. Intégration Rails (app/views/layouts/application.html.erb)

```erb
<!DOCTYPE html>
<html lang="<%= I18n.locale %>">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="<%= csrf_meta_tag %>">
    
    <title>Admin Panel</title>
    
    <!-- Bootstrap 5.3.2 -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!-- Bootstrap Icons -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= importmap_tags %>
  </head>

  <body data-controller="sidebar-toggle" data-sidebar-toggle-persist-key-value="admin-sidebar-state">
    <%= render "shared/admin_sidebar" %>
    <main class="container-fluid">
      <%= yield %>
    </main>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
  </body>
</html>
```

---

## APPROCHE 2: Pure Bootstrap Collapse (Flexible)

**Pour ceux qui veulent un contrôle maximal sans offcanvas**

### Structure simplifiée

```erb
<div class="d-flex" id="admin-layout">
  <div class="col-auto px-0">
    <div id="sidebar" class="collapse collapse-horizontal show" 
         style="width: 280px;"
         data-sidebar-toggle-target="sidebar">
      <!-- Navigation list group -->
    </div>
  </div>
  
  <main class="col ps-3 pt-2">
    <button data-bs-target="#sidebar" 
            data-bs-toggle="collapse" 
            class="btn btn-sm btn-outline-secondary">
      <i class="bi bi-list"></i>
    </button>
    <%= yield %>
  </main>
</div>
```

**Avantages:**
- Layout "push" (content pousse le sidebar)
- Contrôle CSS natif via `.collapse-horizontal`
- Width manageable via inline styles

**Inconvénients:**
- Animation moins smooth
- Moins d'intégration Bootstrap Icons tooltips
- Mobile nécessite séparation

---

## APPROCHE 3: Custom CSS + Stimulus (Maximum Control)

**Pour UI ultra-spécifique avec animations avancées**

```css
/* Sidebar avec transition width smooth */
#sidebar {
  width: 280px;
  transform: translateX(0);
  transition: all 300ms cubic-bezier(0.4, 0, 0.2, 1);
}

#sidebar.collapsed {
  width: 64px;
}

/* Icon scaling */
#sidebar .nav-link i {
  transition: transform 300ms ease;
}

#sidebar.collapsed .nav-link i {
  transform: scale(1.1);
}
```

---

## IMPLÉMENTATION COMPLÈTE: Checklist

### Installation

```bash
# Bootstrap Icons (optionnel si CDN utilisé)
yarn add bootstrap bootstrap-icons

# Stimulus (déjà en Rails 7+)
# Vérifier: app/javascript/controllers
```

### Fichiers à créer/modifier

- [ ] `app/views/layouts/admin.html.erb` - Layout principal
- [ ] `app/assets/stylesheets/admin_sidebar.css` - Styles
- [ ] `app/javascript/controllers/sidebar_toggle_controller.js` - Logique
- [ ] `app/views/shared/_admin_sidebar.html.erb` - Sidebar partielle

### Accessibilité (WCAG 2.1)

```html
<!-- ARIA labels -->
<nav role="navigation" aria-label="Admin navigation">
  <ul class="nav">
    <li class="nav-item">
      <a href="#" aria-label="Dashboard - Go to dashboard" class="nav-link">
        <i class="bi bi-speedometer2" aria-hidden="true"></i>
        <span class="sidebar-label">Dashboard</span>
      </a>
    </li>
  </ul>
</nav>

<!-- Toggle button accessibility -->
<button id="sidebar-toggle"
        aria-label="Toggle sidebar navigation"
        aria-expanded="false"
        aria-controls="sidebar">
  <i class="bi bi-layout-sidebar-inset" aria-hidden="true"></i>
</button>
```

**Mis à jour du Stimulus:**

```javascript
toggle(event) {
  event?.preventDefault()
  const isCurrentlyCollapsed = this.isCollapsed()
  this.setCollapsedState(!isCurrentlyCollapsed)
  
  // Update ARIA
  const toggle = this.toggleTarget
  if (toggle) {
    toggle.setAttribute("aria-expanded", !isCurrentlyCollapsed)
  }
}
```

### Keyboard Navigation

```javascript
connect() {
  document.addEventListener("keydown", (e) => this.handleKeydown(e))
}

handleKeydown(event) {
  // Ctrl+/ pour toggle
  if (event.ctrlKey && event.key === "/") {
    event.preventDefault()
    this.toggle()
  }
  
  // Escape pour collapse (mobile)
  if (event.key === "Escape" && window.innerWidth < 992) {
    const offcanvas = document.getElementById("offcanvasSidebar")
    if (offcanvas) {
      const bsOffcanvas = bootstrap.Offcanvas.getInstance(offcanvas)
      if (bsOffcanvas) bsOffcanvas.hide()
    }
  }
}
```

---

## RECOMMANDATION FINALE ⭐

**Approche 1 (Offcanvas Hybrid) car:**

1. ✅ **Native Bootstrap** - Zéro CSS custom pour base
2. ✅ **Responsive naturel** - Breakpoints clairs
3. ✅ **Mobile-first UX** - Offcanvas avec backdrop
4. ✅ **Animations smooth** - Transitions CSS natives
5. ✅ **Accessibilité WCAG** - ARIA/keyboard built-in
6. ✅ **Stimulus clean** - localStorage + state management simple
7. ✅ **Rails friendly** - Partials faciles, turbo compatible

**Performance optimizations:**

```javascript
// Debounce resize listeners
const resizeObserver = new ResizeObserver(() => {
  // Adjust sidebar after layout shift
})
```

**Persévérance responsive:**
- LocalStorage persiste l'état d'expand/collapse
- SessionStorage pour session seulement
- Considérer "user preference" media query (dark mode)

---

## Ressources Utiles

- [Bootstrap 5.3 Offcanvas](https://getbootstrap.com/docs/5.3/components/offcanvas/)
- [Bootstrap Icons](https://icons.getbootstrap.com/)
- [Stimulus Handbook](https://stimulus.hotwired.dev/)
- [WAI-ARIA Sidebar Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/navigation/)