# 📋 Résumé des Décisions Techniques - Panel Admin

**Ce document résume toutes les décisions techniques prises pour le panel admin, avec références aux guides complets.**

---

## 🎯 Décisions par User Story

### Sprint 1-2 : Infrastructure & Navigation

| US | Fonctionnalité | Décision | Guide | Temps |
|----|----------------|----------|-------|-------|
| **US-001** | Sidebar collapsible | **Offcanvas Hybrid (Bootstrap 5)** | [sidebar_guide_bootstrap5.md](descisions/sidebar_guide_bootstrap5.md) | 2-3j |
| **US-002** | Menu hiérarchique | Bootstrap collapse | [sidebar_guide_bootstrap5.md](descisions/sidebar_guide_bootstrap5.md) | 2j (inclus US-001) |
| **US-003** | Responsive sidebar | Inclus dans US-001 | [sidebar_guide_bootstrap5.md](descisions/sidebar_guide_bootstrap5.md) | Intégré |
| **US-004** | Recherche globale (Cmd+K) | **Hybride (client + serveur)** | [palette-cmdk-rails.md](descisions/palette-cmdk-rails.md) | 3-4j |
| **US-005** | Breadcrumb | Bootstrap breadcrumb | Standard Bootstrap | 1j |
| **US-006** | Raccourcis clavier | Stimulus controller global | Standard | 2j |

### Sprint 3-4 : Affichage Données & Actions

| US | Fonctionnalité | Décision | Guide | Temps |
|----|----------------|----------|-------|-------|
| **US-007** | Drag-drop colonnes | **SortableJS + Stimulus** ⭐ | [column_reordering_solution.md](descisions/column_reordering_solution.md) | 4h |
| **US-008** | Batch actions | Bootstrap form-check + Stimulus | Standard | 3j |
| **US-009** | Tri et filtres | Bootstrap tables + Stimulus | Standard | 4-5j |
| **US-010** | Boutons dynamiques | Hardcodé d'abord, DB ensuite | Standard | 5-6j |
| **US-011** | Dashboard widgets | **SortableJS + JSONB (MVP progressif)** | [dashboard-widgets.md](descisions/dashboard-widgets.md) | 5-7j (MVP 2-3j) |
| **US-012** | Statistiques dashboard | Bootstrap cards | Standard | 2-3j |

### Sprint 5-6 : Formulaires & Features Avancées

| US | Fonctionnalité | Décision | Guide | Temps |
|----|----------------|----------|-------|-------|
| **US-013** | Formulaires avec tabs | Bootstrap nav-tabs | Standard | 2-3j |
| **US-014** | Panels associés | Bootstrap cards | Standard | 2j |
| **US-015** | Validation inline | **Validation hybride (Stimulus + Rails)** ⭐ | [form-validation-guide.md](descisions/form-validation-guide.md) | 3j |
| **US-016** | Présences initiations | Réutiliser existant, améliorer UX | Standard | 4-5j |
| **US-017** | Dark mode | ✅ **DÉJÀ IMPLÉMENTÉ** | [reutilisation-dark-mode.md](reutilisation-dark-mode.md) | 0j |
| **US-018** | Accessibilité | Itératif (continu) | Standard | Continu |

---

## 🛠️ Technologies & Dépendances

### Stack Confirmée

| Technologie | Version | Usage |
|------------|---------|-------|
| **Rails** | 8.1.1 | Framework backend |
| **Bootstrap** | 5.3.2 | CSS framework (✅ PAS Tailwind) |
| **Bootstrap Icons** | 1.11.1 | Icônes |
| **Stimulus** | Latest | JavaScript framework |
| **Turbo** | Latest | Hotwire |
| **Pundit** | Latest | Autorisations |
| **PostgreSQL** | 16 | Base de données (JSONB support) |

### Nouvelles Dépendances à Ajouter

| Package | Usage | Installation |
|---------|-------|--------------|
| **@stimulus-components/sortable** | Drag-drop colonnes (US-007) et widgets (US-011) | `yarn add @stimulus-components/sortable` |

**Note** : Minimiser les dépendances, réutiliser au maximum ce qui existe.

---

## 📦 Réutilisation Maximale

### Déjà Implémenté (Réutiliser)

| Fonctionnalité | Fichier | Usage |
|----------------|---------|-------|
| **Dark mode** | `app/views/layouts/application.html.erb` | Layout admin hérite automatiquement |
| **Classes Liquid** | `app/assets/stylesheets/_style.scss` | `card-liquid`, `btn-liquid-primary`, etc. |
| **Bootstrap** | `app/assets/stylesheets/application.bootstrap.scss` | Toutes classes standards |
| **Stimulus** | `app/javascript/controllers/` | Structure existante |

### Classes CSS à Réutiliser

Voir [reference-css-classes.md](reference-css-classes.md) pour la liste complète :

- **Cards** : `card`, `card-liquid`, `card-body`, etc.
- **Buttons** : `btn-liquid-primary`, `btn-outline-primary`, etc.
- **Navigation** : `nav`, `nav-pills`, `nav-link`, etc.
- **Forms** : `form-control`, `form-check`, `is-invalid`, etc.
- **Tables** : `table`, `table-striped`, `table-hover`, etc.
- **Badges** : `badge`, `badge-liquid-primary`, etc.

---

## 🎯 Approches Techniques Détaillées

### 1. Sidebar (US-001, US-002, US-003)

**Décision** : Offcanvas Hybrid (Bootstrap 5)

- **Desktop** : Sidebar fixe collapsible (280px / 64px)
- **Mobile** : Bootstrap offcanvas
- **Stimulus** : Controller pour persistence localStorage
- **Guide** : [sidebar_guide_bootstrap5.md](descisions/sidebar_guide_bootstrap5.md)

### 2. Recherche Globale (US-004)

**Décision** : Approche hybride

- **Client** : Cache pour performance (< 50ms)
- **Serveur** : Fallback AJAX si cache invalide
- **Stimulus** : `search_palette_controller.js`
- **Rails** : `Admin::SearchController`
- **Guide** : [palette-cmdk-rails.md](descisions/palette-cmdk-rails.md)

### 3. Drag-Drop Colonnes (US-007)

**Décision** : SortableJS + Stimulus

- **Package** : `@stimulus-components/sortable`
- **Avantages** : Production-ready, WCAG AA, code minimal
- **Temps** : 4 heures seulement
- **Guide** : [column_reordering_solution.md](descisions/column_reordering_solution.md)

### 4. Dashboard Widgets (US-011)

**Décision** : SortableJS + JSONB (MVP progressif)

- **Phase 1** : Ordre fixe (2-3j) - Dashboard utilisable
- **Phase 2** : Drag-drop (3-4j) - Ajout interactivité
- **DB** : `users.widget_positions` (JSONB)
- **Guide** : [dashboard-widgets.md](descisions/dashboard-widgets.md)

### 5. Validation Formulaires (US-015)

**Décision** : Validation hybride

- **Client** : Stimulus sur `blur` + `input`
- **Serveur** : Rails validations (source de vérité)
- **Bootstrap** : `is-invalid`, `invalid-feedback`
- **Guide** : [form-validation-guide.md](descisions/form-validation-guide.md)

---

## ⚠️ Points d'Attention

### Ne Pas Utiliser
- ❌ **Tailwind CSS** → Bootstrap 5.3.2
- ❌ **View Components** → Partials Rails
- ❌ **React / @dnd-kit** → Stimulus + SortableJS
- ❌ **Nouvelles dépendances inutiles** → Réutiliser

### Bonnes Pratiques
- ✅ **MVP progressif** : Fonctionnalités simples d'abord
- ✅ **Réutilisation** : Dark mode, classes CSS, etc.
- ✅ **Accessibilité** : WCAG 2.1 AA minimum
- ✅ **Performance** : Optimiser dès le début

---

## 📚 Références Rapides

### Guides de Décision (Perplexity)
- [sidebar_guide_bootstrap5.md](descisions/sidebar_guide_bootstrap5.md) - Sidebar
- [palette-cmdk-rails.md](descisions/palette-cmdk-rails.md) - Recherche
- [column_reordering_solution.md](descisions/column_reordering_solution.md) - Drag-drop colonnes
- [dashboard-widgets.md](descisions/dashboard-widgets.md) - Dashboard
- [form-validation-guide.md](descisions/form-validation-guide.md) - Validation
- [darkmode-rails.md](descisions/darkmode-rails.md) - Dark mode (déjà fait)

### Documentation
- [START_HERE.md](START_HERE.md) - Guide de démarrage
- [reference-css-classes.md](reference-css-classes.md) - Classes CSS
- [reutilisation-dark-mode.md](reutilisation-dark-mode.md) - Dark mode
- [plan-implementation.md](plan-implementation.md) - Plan complet

---

## 📚 Navigation Documentation

- **[START_HERE.md](START_HERE.md)** - Guide de démarrage complet
- **[INDEX.md](INDEX.md)** - Index de toute la documentation
- **[plan-implementation.md](plan-implementation.md)** - Plan complet avec détails

---

**Dernière mise à jour** : 2025-01-27  
**Version** : 1.0
