# 🚀 Panel Admin - Guide de Démarrage

**Bienvenue !** Ce fichier est votre point d'entrée pour développer le nouveau panel admin.

---

## 📋 Vue d'Ensemble

**Objectif** : Remplacer Active Admin par un panel moderne et maintenable  
**Durée** : 6 sprints (12 semaines)  
**Approche** : MVP progressif avec feedback utilisateur continu

---

## 🎯 Par Où Commencer ?

### 1️⃣ Comprendre le Contexte (30 min)

Lisez ces documents dans l'ordre :

1. **[README.md](README.md)** - Vue d'ensemble de la documentation
2. **[plan-implementation.md](plan-implementation.md)** - Plan complet avec toutes les décisions techniques
3. **[analyse-stack-reelle.md](analyse-stack-reelle.md)** - Stack réelle vs plan (Bootstrap, Stimulus, etc.)

**Points clés** :
- ✅ Stack : **Bootstrap 5.3.2** (pas Tailwind), **Stimulus**, **Partials Rails**
- ✅ Réutiliser au maximum ce qui existe déjà (dark mode, classes CSS Liquid, etc.)
- ✅ Toutes les décisions techniques sont documentées dans `descisions/`

---

### 2️⃣ Consulter les Décisions Techniques (1h)

Les réponses de Perplexity sont dans `descisions/` avec des guides complets :

| Document | User Story | Décision | Temps estimé |
|----------|-----------|----------|--------------|
| **[sidebar_guide_bootstrap5.md](descisions/sidebar_guide_bootstrap5.md)** | US-001, US-002, US-003 | Offcanvas Hybrid (Bootstrap 5) | 2-3j |
| **[palette-cmdk-rails.md](descisions/palette-cmdk-rails.md)** | US-004 | Recherche hybride (client + serveur) | 3-4j |
| **[column_reordering_solution.md](descisions/column_reordering_solution.md)** | US-007 | SortableJS + Stimulus | 4h |
| **[dashboard-widgets.md](descisions/dashboard-widgets.md)** | US-011 | SortableJS + JSONB (ordre fixe d'abord) | 3-4j |
| **[form-validation-guide.md](descisions/form-validation-guide.md)** | US-015 | Validation hybride (Stimulus + Rails) | 3j |
| **[darkmode-rails.md](descisions/darkmode-rails.md)** | US-017 | ✅ **DÉJÀ IMPLÉMENTÉ** - Réutiliser | 0j |

---

### 3️⃣ Références de Développement

#### Classes CSS Disponibles
👉 **[reference-css-classes.md](reference-css-classes.md)**
- Toutes les classes Bootstrap 5.3.2
- Classes Liquid custom du projet (`card-liquid`, `btn-liquid-primary`, etc.)
- Variables CSS custom
- Exemples d'utilisation

#### Réutilisation Dark Mode
👉 **[reutilisation-dark-mode.md](reutilisation-dark-mode.md)**
- Dark mode déjà implémenté
- Guide de réutilisation
- Aucune implémentation nécessaire

---

## 🎯 Sprint 1 : Infrastructure & Navigation (Semaines 1-2)

### User Stories à Implémenter

#### US-001 : Sidebar Collapsible
**Décision** : Offcanvas Hybrid (Bootstrap 5)  
**Guide** : [sidebar_guide_bootstrap5.md](descisions/sidebar_guide_bootstrap5.md)  
**Estimation** : 2-3 jours

**Points clés** :
- Desktop : Sidebar fixe 280px (expanded) / 64px (collapsed)
- Mobile : Bootstrap offcanvas
- Stimulus controller pour persistence localStorage
- Réutiliser classes Bootstrap (`offcanvas`, `collapse`)

#### US-002 : Menu Hiérarchique
**Décision** : Bootstrap collapse pour submenus  
**Guide** : [sidebar_guide_bootstrap5.md](descisions/sidebar_guide_bootstrap5.md)  
**Estimation** : 2 jours

**Points clés** :
- Bootstrap Icons pour les icônes
- `collapse` Bootstrap pour expand/collapse
- Max 3 niveaux de profondeur

#### US-003 : Responsive Sidebar
**Décision** : Inclus dans US-001 (Offcanvas Hybrid)  
**Estimation** : Intégré dans US-001

---

## 🎯 Sprint 2 : Navigation Avancée (Semaines 3-4)

#### US-004 : Recherche Globale (Cmd+K)
**Décision** : Approche hybride (client + serveur)  
**Guide** : [palette-cmdk-rails.md](descisions/palette-cmdk-rails.md)  
**Estimation** : 3-4 jours

**Points clés** :
- Stimulus controller `search_palette_controller.js`
- Rails controller `Admin::SearchController`
- Cache client pour performance (< 50ms)
- Fallback serveur (AJAX)

#### US-005 : Breadcrumb
**Décision** : Bootstrap breadcrumb standard  
**Estimation** : 1 jour

**Points clés** :
- Classes Bootstrap : `breadcrumb`, `breadcrumb-item`
- Dynamique selon page courante

#### US-006 : Raccourcis Clavier
**Décision** : Stimulus controller global  
**Estimation** : 2 jours

**Points clés** :
- Cmd+K → Recherche (géré dans US-004)
- Escape → Fermer modals
- Cmd+S → Sauvegarder formulaire
- Cmd+? → Aide

---

## 🎯 Sprint 3-4 : Affichage Données & Actions

#### US-007 : Drag-Drop Colonnes
**Décision** : SortableJS + Stimulus ⭐  
**Guide** : [column_reordering_solution.md](descisions/column_reordering_solution.md)  
**Estimation** : 4 heures

**Points clés** :
- `yarn add @stimulus-components/sortable`
- Accessibilité clavier intégrée
- Persistence localStorage ou DB

#### US-008 : Batch Actions
**Décision** : Bootstrap form-check + Stimulus  
**Estimation** : 3 jours

**Points clés** :
- Classes Bootstrap : `form-check`, `form-check-input`
- Toolbar apparaît sur sélection

#### US-009 : Tri et Filtres
**Décision** : Bootstrap tables + Stimulus  
**Estimation** : 4-5 jours

**Points clés** :
- Bootstrap table sorting
- Filtres combinables

#### US-010 : Boutons Dynamiques
**Décision** : Hardcodé d'abord (partials), DB ensuite  
**Estimation** : 5-6 jours

#### US-011 : Dashboard Personnalisable
**Décision** : SortableJS + JSONB (ordre fixe d'abord) ⭐  
**Guide** : [dashboard-widgets.md](descisions/dashboard-widgets.md)  
**Estimation** : 3-4 jours (MVP avec ordre fixe), puis drag-drop

**Points clés** :
- Phase 1 : Ordre fixe (2-3j)
- Phase 2 : Drag-drop avec SortableJS (3-4j)
- Sauvegarde dans `users.widget_positions` (JSONB)

#### US-012 : Statistiques Dashboard
**Décision** : Bootstrap cards  
**Estimation** : 2-3 jours

**Points clés** :
- Réutiliser classes `card`, `card-liquid`
- 8 widgets minimum

---

## 🎯 Sprint 5-6 : Formulaires & Features Avancées

#### US-013 : Formulaires avec Tabs
**Décision** : Bootstrap nav-tabs  
**Estimation** : 2-3 jours

**Points clés** :
- Classes Bootstrap : `nav`, `nav-tabs`, `nav-item`, `nav-link`

#### US-014 : Panels Associés
**Décision** : Bootstrap cards  
**Estimation** : 2 jours

**Points clés** :
- Réutiliser `card`, `card-liquid`

#### US-015 : Validation Inline
**Décision** : Validation hybride (Stimulus + Rails) ⭐  
**Guide** : [form-validation-guide.md](descisions/form-validation-guide.md)  
**Estimation** : 3 jours

**Points clés** :
- 1 Stimulus controller par formulaire
- Validation sur `blur` + `input`
- Classes Bootstrap : `is-invalid`, `invalid-feedback`
- Submit désactivé si erreurs

#### US-016 : Présences Initiations
**Décision** : Réutiliser vue existante, améliorer UX  
**Estimation** : 4-5 jours

**Points clés** :
- Bootstrap `form-check` pour radio buttons
- Sauvegarde batch

#### US-017 : Dark Mode
**Décision** : ✅ **DÉJÀ IMPLÉMENTÉ** - Réutiliser  
**Guide** : [reutilisation-dark-mode.md](reutilisation-dark-mode.md)  
**Estimation** : 0 jour (juste vérifier)

#### US-018 : Accessibilité
**Décision** : Itératif (continu)  
**Estimation** : Continu

---

## 📋 Migration des Ressources Active Admin

**Important** : Ce panel admin remplace Active Admin, donc **TOUTES les ressources doivent être migrées**.

👉 **[MIGRATION_RESSOURCES.md](MIGRATION_RESSOURCES.md)** - Checklist complète des 24 ressources + 2 pages à migrer

**Répartition** :
- **Sprint 1-2** : Dashboard + Maintenance (2 pages)
- **Sprint 3-4** : 9 ressources simples (CRUD basique)
- **Sprint 5-6** : 8 ressources moyennes (avec relations)
- **Sprint 7-8** : 4 ressources complexes (avec actions personnalisées)

---

## 📚 Références Rapides

### Fichiers de Décision (Perplexity)
- **[sidebar_guide_bootstrap5.md](descisions/sidebar_guide_bootstrap5.md)** - Sidebar collapsible
- **[palette-cmdk-rails.md](descisions/palette-cmdk-rails.md)** - Recherche globale Cmd+K
- **[column_reordering_solution.md](descisions/column_reordering_solution.md)** - Drag-drop colonnes
- **[dashboard-widgets.md](descisions/dashboard-widgets.md)** - Dashboard widgets
- **[form-validation-guide.md](descisions/form-validation-guide.md)** - Validation formulaires
- **[darkmode-rails.md](descisions/darkmode-rails.md)** - Dark mode (déjà fait)

### Documentation de Référence
- **[reference-css-classes.md](reference-css-classes.md)** - Classes CSS disponibles
- **[reutilisation-dark-mode.md](reutilisation-dark-mode.md)** - Dark mode existant
- **[inventaire-active-admin.md](inventaire-active-admin.md)** - Fonctionnalités à migrer
- **[guide-ux-ui.md](guide-ux-ui.md)** - Guide UX/UI
- **[methode-realisation.md](methode-realisation.md)** - Méthode de travail

---

## 🛠️ Stack Technique Confirmée

| Technologie | Version | Usage |
|------------|---------|-------|
| **Rails** | 8.1.1 | Framework backend |
| **Bootstrap** | 5.3.2 | CSS framework (✅ PAS Tailwind) |
| **Bootstrap Icons** | 1.11.1 | Icônes |
| **Stimulus** | Latest | JavaScript framework |
| **Turbo** | Latest | Hotwire |
| **Pundit** | Latest | Autorisations |
| **PostgreSQL** | 16 | Base de données (JSONB support) |

---

## ⚠️ Points d'Attention

### Ne Pas Utiliser
- ❌ **Tailwind CSS** → Utiliser Bootstrap 5.3.2
- ❌ **View Components** → Utiliser Partials Rails
- ❌ **React / @dnd-kit** → Utiliser Stimulus + SortableJS
- ❌ **Nouvelles dépendances** → Réutiliser au maximum

### Réutiliser au Maximum
- ✅ **Dark mode** → Déjà implémenté, juste réutiliser
- ✅ **Classes Liquid** → `card-liquid`, `btn-liquid-primary`, etc.
- ✅ **Bootstrap** → Toutes les classes standards
- ✅ **Stimulus controllers** → Structure existante

---

## 🚀 Checklist Démarrage Sprint 1

Avant de commencer :

- [ ] Lire [plan-implementation.md](plan-implementation.md)
- [ ] Lire [sidebar_guide_bootstrap5.md](descisions/sidebar_guide_bootstrap5.md)
- [ ] Consulter [reference-css-classes.md](reference-css-classes.md)
- [ ] Vérifier que Bootstrap 5.3.2 est installé
- [ ] Vérifier que Stimulus est configuré
- [ ] Créer branche `feature/admin-panel-2025`
- [ ] Setup layout admin de base

---

## 📝 Workflow Recommandé

1. **Lire la décision technique** dans `descisions/`
2. **Consulter les classes CSS** dans `reference-css-classes.md`
3. **Vérifier ce qui existe déjà** (dark mode, classes, etc.)
4. **Implémenter** avec Bootstrap + Stimulus
5. **Tester** et valider

---

## 🔗 Liens Utils

- [Bootstrap 5.3 Documentation](https://getbootstrap.com/docs/5.3/)
- [Bootstrap Icons](https://icons.getbootstrap.com/)
- [Stimulus Handbook](https://stimulus.hotwired.dev/)
- [SortableJS Documentation](https://sortablejs.github.io/Sortable/)

---

## 📚 Navigation Documentation

- **[INDEX.md](INDEX.md)** - Index complet de toute la documentation
- **[RESUME_DECISIONS.md](RESUME_DECISIONS.md)** - Résumé rapide des décisions
- **[README.md](README.md)** - Vue d'ensemble de la documentation

---

**Dernière mise à jour** : 2025-01-27  
**Version** : 1.0

**Bon développement ! 🚀**
