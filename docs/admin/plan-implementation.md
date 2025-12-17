# Plan d'Implémentation - Migration Panel Admin

**Objectif** : Remplacer Active Admin par un panel moderne et maintenable  
**Durée** : 6 sprints (12 semaines)  
**Approche** : MVP progressif avec feedback utilisateur continu

---

## 🎯 Vision & Principes

### Objectifs
- ✅ Panel moderne avec UX 2025
- ✅ Navigation intuitive (sidebar + recherche)
- ✅ Personnalisation (colonnes, dashboard)
- ✅ Responsive complet
- ✅ Performance optimale

### Principes Agile
- **MVP d'abord** : Fonctionnalités essentielles en premier
- **Feedback continu** : Tests utilisateurs à chaque sprint
- **Itération** : Amélioration progressive
- **Simplicité** : Pas de sur-ingénierie

---

## 📊 Vue d'ensemble

**Objectif** : Migrer **24 ressources Active Admin + 2 pages personnalisées** vers le nouveau panel

```
Sprint 1-2: Infrastructure & Navigation + Dashboard (4 semaines) - 32 points
  → 2 pages personnalisées (Dashboard, Maintenance)
  
Sprint 3-4: Affichage données & Actions + Ressources Simples (4 semaines) - 32 points
  → 9 ressources simples (CRUD basique)
  
Sprint 5-6: Formulaires & Features avancées + Ressources Moyennes (4 semaines) - 32 points
  → 8 ressources moyennes (avec relations)
  
Sprint 7-8: Ressources Complexes + Polish (4 semaines) - 32 points
  → 4 ressources complexes (avec actions personnalisées)
  
───────────────────────────────────────────────────────────────
TOTAL: 128 points (64 jours)

Avec 1 dev full-time:  16 semaines (4 mois)
Avec 2 devs:            8-10 semaines
```

**📋 Liste complète des ressources** : Voir [MIGRATION_RESSOURCES.md](MIGRATION_RESSOURCES.md)

---

## 🚀 SPRINT 1-2 : Infrastructure & Navigation

**Durée** : 4 semaines | **Objectif** : Sidebar + Menu + Recherche fonctionnels

### Sprint 1 (Semaines 1-2) - 16 points

#### User Stories

**US-001** : Sidebar collapsible
- Expanded (280px) / Collapsed (64px)
- Toggle avec animation 300ms
- Persistence localStorage
- **Décision technique** : Offcanvas Hybrid (Bootstrap 5) ⭐
- **Guide complet** : [sidebar_guide_bootstrap5.md](descisions/sidebar_guide_bootstrap5.md)
- **Faisabilité** : ✅ TRÈS FAISABLE (2-3j)
- **Critères** : Desktop fonctionnel, responsive tablet
- **Classes CSS** : `offcanvas`, `collapse`, Bootstrap Icons (voir [reference-css-classes.md](reference-css-classes.md))

**US-002** : Menu hiérarchique
- Catégories (Utilisateurs, Boutique, Événements, etc.)
- Expand/collapse par section
- Icons Bootstrap Icons + labels
- **Décision technique** : Bootstrap collapse pour submenus
- **Guide complet** : [sidebar_guide_bootstrap5.md](descisions/sidebar_guide_bootstrap5.md) (inclus dans sidebar)
- **Faisabilité** : ✅ TRÈS FAISABLE (2j) - Intégré dans US-001
- **Critères** : Toutes ressources accessibles, max 3 niveaux
- **Classes CSS** : `collapse`, `nav`, `nav-pills`, Bootstrap Icons (voir [reference-css-classes.md](reference-css-classes.md))

**US-003** : Responsive sidebar
- Desktop : expandable
- Tablet : collapsed par défaut
- Mobile : drawer avec hamburger (Bootstrap offcanvas)
- **Faisabilité** : ✅ FAISABLE (4-5j sur durée totale)
- **Critères** : Testé sur 3 breakpoints

#### Livrables
- Sidebar component fonctionnel
- Menu hiérarchique avec collapse
- Responsive desktop/tablet/mobile
- Tests unitaires sidebar

---

### Sprint 2 (Semaines 3-4) - 16 points

#### User Stories

**US-004** : Recherche globale (Cmd+K)
- Déclenchée par Cmd+K (Stimulus controller)
- Recherche ressources + pages + utilisateurs
- Navigation clavier (flèches + Enter)
- **Décision technique** : Approche hybride (client cache + serveur fallback) ⭐
- **Guide complet** : [palette-cmdk-rails.md](descisions/palette-cmdk-rails.md)
- **Faisabilité** : ✅ FAISABLE (3-4j)
- **Performance** : < 50ms avec cache client, < 200ms avec serveur
- **Critères** : Résultats en <200ms, max 10 résultats, accessibilité ARIA
- **Implémentation** : `Admin::SearchController` + `search_palette_controller.js` (Stimulus)

**US-005** : Breadcrumb
- Dynamique selon la page
- Liens cliquables (Bootstrap breadcrumb)
- **Faisabilité** : ✅ TRÈS FAISABLE (1j)
- **Critères** : Visible sur toutes les pages

**US-006** : Raccourcis clavier
- Cmd+K → Recherche
- Escape → Fermer modals
- Cmd+S → Sauvegarder formulaire
- Cmd+? → Aide
- **Faisabilité** : ✅ FAISABLE (2j) - Stimulus controller
- **Critères** : 5+ raccourcis fonctionnels

#### Livrables
- Recherche globale opérationnelle
- Breadcrumb system
- Raccourcis clavier + Help modal

---

## 📋 SPRINT 3-4 : Affichage Données & Actions

**Durée** : 4 semaines | **Objectif** : Tables + Drag-drop + Batch actions

### Sprint 3 (Semaines 5-6) - 16 points

#### User Stories

**US-007** : Drag-drop colonnes
- Réordonnage colonnes par drag-drop
- Sauvegarde préférences utilisateur
- **Décision technique** : SortableJS + Stimulus ⭐ (recommandée par Perplexity)
- **Guide complet** : [column_reordering_solution.md](descisions/column_reordering_solution.md)
- **Faisabilité** : ✅ FAISABLE (4 heures seulement !)
- **Installation** : `yarn add @stimulus-components/sortable`
- **Avantages** : Production-ready, accessibilité WCAG 2.1 AA, code minimal
- **Critères** : Ordre persisté (localStorage ou DB), accessibilité clavier, animation smooth

**US-008** : Batch actions
- Checkboxes par ligne
- Toolbar actions apparaît sur sélection
- Actions : Supprimer, Exporter, Assigner
- **Faisabilité** : ✅ FAISABLE (3j)
- **Critères** : Sélection multiple, confirmation destructive

**US-009** : Tri et filtres
- Tri par colonne (asc/desc)
- Filtres combinables
- **Faisabilité** : ✅ FAISABLE (4-5j)
- **Risques** : Performance si >1000 lignes (virtualisation)
- **Critères** : Tri instantané, filtres combinables

#### Livrables
- Table component avec drag-drop colonnes
- Sélection multiple + batch actions
- Tri et filtres fonctionnels
- Tests E2E table

---

### Sprint 4 (Semaines 7-8) - 16 points

#### User Stories

**US-010** : Boutons dynamiques
- Affichés selon statut ressource
- Configuration en base de données (optionnel)
- Permissions Pundit respectées
- **Faisabilité** : ⚠️ FAISABLE MAIS COMPLEXE (5-6j)
- **Risques** : Logique métier complexe, tests exhaustifs
- **Recommandation** : Commencer simple (hardcodé dans partials Rails), puis DB si besoin
- **Critères** : Boutons contextuels, permissions OK

**US-011** : Dashboard personnalisable
- Widgets réordonnables (drag-drop)
- Sauvegarde positions en DB
- **Décision technique** : SortableJS + JSONB (MVP progressif) ⭐
- **Guide complet** : [dashboard-widgets.md](descisions/dashboard-widgets.md)
- **Approche MVP** : 
  - Phase 1 : Ordre fixe (2-3j) - Dashboard utilisable immédiatement
  - Phase 2 : Drag-drop avec SortableJS (3-4j) - Ajout du drag-drop
- **Faisabilité** : ✅ FAISABLE (5-7j total, mais MVP en 2-3j)
- **Structure DB** : `users.widget_positions` (JSONB column)
- **Critères** : 8 widgets minimum, positions persistées, responsive (4 cols desktop, 2 tablet, 1 mobile)

**US-012** : Statistiques dashboard
- Cartes statistiques avec liens
- Données temps réel
- **Faisabilité** : ✅ FAISABLE (2-3j)
- **Critères** : 8 cartes minimum, données à jour

#### Livrables
- Système boutons dynamiques (DB-driven)
- Dashboard personnalisable
- Widgets drag-drop
- Tests permissions

---

## 📝 SPRINT 5-6 : Formulaires & Features Avancées

**Durée** : 4 semaines | **Objectif** : Forms optimisés + Features complexes

### Sprint 5 (Semaines 9-10) - 16 points

#### User Stories

**US-013** : Formulaires avec tabs
- Tabs : Infos | Adresse | Commentaires (Bootstrap nav-tabs)
- Lazy loading contenu
- **Faisabilité** : ✅ FAISABLE (2-3j)
- **Critères** : 3+ ressources avec tabs, navigation fluide

**US-014** : Panels associés
- Panels inline (ex: Inscriptions dans User) - Bootstrap cards
- Tables dans panels (Bootstrap tables)
- **Faisabilité** : ✅ FAISABLE (2j)
- **Critères** : Panels collapsibles, données à jour

**US-015** : Validation inline
- Validation en temps réel (Stimulus controller)
- Messages d'erreur clairs (Bootstrap validation)
- **Décision technique** : Validation hybride (Stimulus + Rails) ⭐
- **Guide complet** : [form-validation-guide.md](descisions/form-validation-guide.md)
- **Faisabilité** : ✅ FAISABLE (3j)
- **Architecture** : 1 Stimulus controller par formulaire
- **Validation** : Client sur `blur` + `input`, serveur Rails comme source de vérité
- **Classes CSS** : `is-invalid`, `invalid-feedback` (Bootstrap) - voir [reference-css-classes.md](reference-css-classes.md)
- **Critères** : Validation avant submit, submit désactivé si erreurs, messages utiles

#### Livrables
- Tab system pour formulaires
- Panels associés fonctionnels
- Validation inline
- Refactoring 3+ ressources

---

### Sprint 6 (Semaines 11-12) - 16 points

#### User Stories

**US-016** : Présences initiations
- Dashboard présences avec pointage
- Radio buttons : Présent / Absent / Non pointé (Bootstrap form-check)
- Sauvegarde batch
- **Faisabilité** : ⚠️ FAISABLE (4-5j)
- **Risques** : Logique métier spécifique, gestion état
- **Recommandation** : Réutiliser vue existante, améliorer UX
- **Critères** : Pointage rapide, sauvegarde fiable

**US-017** : Dark mode
- ✅ **DÉJÀ IMPLÉMENTÉ** - Réutiliser le système existant
- Toggle dans navbar globale (déjà présent)
- Fonction `toggleTheme()` avec persistence localStorage (déjà présent)
- Bootstrap `data-bs-theme="dark"` (déjà présent)
- CSS custom avec `[data-bs-theme=dark]` (déjà présent)
- **Action** : S'assurer que le layout admin hérite du thème
- **Faisabilité** : ✅ DÉJÀ FAIT (0j - juste réutiliser)
- **Critères** : Vérifier que toutes classes admin supportent dark mode

**US-018** : Accessibilité
- ARIA labels
- Navigation clavier complète
- Contraste couleurs
- **Faisabilité** : 🔄 ITÉRATIF (continu)
- **Critères** : Score a11y ≥90, tests screen reader

#### Livrables
- Dashboard présences initiations
- Dark mode complet
- Accessibilité validée
- Tests E2E complets
- Documentation utilisateur

---

## ✅ Validation Faisabilité par Priorité

### ✅ Priorité 1 - MVP (Faisable, implémenter en premier)
- Sidebar collapsible : ✅ TRÈS FAISABLE (2-3j)
- Menu hiérarchique : ✅ TRÈS FAISABLE (2j)
- Recherche globale : ✅ FAISABLE (3-4j)
- Breadcrumb : ✅ TRÈS FAISABLE (1j)
- Raccourcis clavier : ✅ FAISABLE (2j)
- Tables tri/filtres : ✅ FAISABLE (4-5j)
- Batch actions : ✅ FAISABLE (3j)
- Formulaires tabs : ✅ FAISABLE (2-3j)
- Panels associés : ✅ FAISABLE (2j)
- Validation inline : ✅ FAISABLE (3j)
- Dark mode : ✅ FAISABLE (2j)
- Responsive : ✅ FAISABLE (4-5j)

**Total Priorité 1** : ~30 jours

### ⚠️ Priorité 2 - Features Avancées (Planifier soigneusement)
- Drag-drop colonnes : ⚠️ COMPLEXE (5-6j) - Utiliser @dnd-kit
- Dashboard widgets : ⚠️ COMPLEXE (6-7j) - Gestion état
- Boutons dynamiques DB : ⚠️ COMPLEXE (5-6j) - Commencer simple
- Présences initiations : ⚠️ MOYEN (4-5j) - Réutiliser existant

**Total Priorité 2** : ~20 jours

### 🔄 Priorité 3 - Itératif (Amélioration continue)
- Accessibilité complète : 🔄 ITÉRATIF (continu)
- Optimisations performance : 🔄 ITÉRATIF (selon besoins)

---

## 🎯 Priorisation MVP

### Phase 1 : MVP (Sprints 1-3)
1. Sidebar + Menu
2. Recherche globale
3. Tables avec tri/filtres
4. Formulaires basiques

### Phase 2 : Features Avancées (Sprints 4-5)
5. Drag-drop colonnes
6. Boutons dynamiques
7. Dashboard personnalisable
8. Formulaires tabs

### Phase 3 : Polish (Sprint 6)
9. Présences initiations
10. Dark mode
11. Accessibilité
12. Documentation

---

## 📈 Critères de Succès

### Technique
- ✅ Toutes fonctionnalités Active Admin migrées
- ✅ Performance : Temps chargement <2s
- ✅ Accessibilité : Score a11y ≥90
- ✅ Tests : Couverture ≥80%

### Utilisateur
- ✅ Navigation intuitive (découverte <30s)
- ✅ Personnalisation fonctionnelle
- ✅ Responsive tous devices
- ✅ Satisfaction ≥4/5

---

## 🚦 Go/No-Go Checklist

### Avant Sprint 1
- [ ] Rails 8+ configuré ✅
- [ ] Stimulus configuré ✅
- [ ] Bootstrap 5 installé ✅
- [ ] Staging environment prêt
- [ ] Backup BD actuel
- [ ] Branche git créée
- [ ] CI/CD fonctionnel

### Avant chaque Sprint
- [ ] Review sprint précédent
- [ ] Feedback utilisateurs collecté
- [ ] Priorités ajustées si besoin
- [ ] Tests passants

---

## 📝 Notes Importantes

### Approche Progressive
- **Ne pas tout migrer d'un coup** : Ressource par ressource
- **Tester avec utilisateurs** : Feedback à chaque sprint
- **Itérer** : Améliorer selon retours

### Risques Identifiés
- **Drag-drop** : Utiliser librairie éprouvée (@dnd-kit)
- **Performance tables** : Virtualisation si >1000 lignes
- **Permissions** : Tester Pundit sur chaque feature
- **Boutons dynamiques** : Commencer simple, migrer vers DB si besoin

### Décisions Techniques (CORRIGÉ - Stack réelle du projet)
- **Frontend** : Stimulus + Partials Rails (Bootstrap 5.3.2) ✅
- **Drag-drop** : HTML5 Drag API + Stimulus (ou alternative simple) ✅
- **Styling** : Bootstrap 5.3.2 (pas Tailwind CSS) ✅
- **Tests** : RSpec + Capybara pour E2E ✅
- **Icons** : Bootstrap Icons ✅

---

## 📚 Documentation de Référence

### 🚀 Guide de Démarrage
- **[START_HERE.md](START_HERE.md)** ⭐ **COMMENCER ICI** - Point d'entrée complet avec workflow recommandé

### 📋 Migration des Ressources
- **[MIGRATION_RESSOURCES.md](MIGRATION_RESSOURCES.md)** ⭐ **CHECKLIST COMPLÈTE** - Toutes les 24 ressources + 2 pages à migrer avec checklist détaillée

### Décisions Techniques (Réponses Perplexity)
Toutes les décisions techniques sont documentées dans `descisions/` avec guides complets :

- **[sidebar_guide_bootstrap5.md](descisions/sidebar_guide_bootstrap5.md)** - US-001, US-002, US-003
  - Décision : Offcanvas Hybrid (Bootstrap 5)
  - Code complet, Stimulus controller, exemples

- **[palette-cmdk-rails.md](descisions/palette-cmdk-rails.md)** - US-004
  - Décision : Recherche hybride (client cache + serveur)
  - Controller Rails + Stimulus, architecture complète

- **[column_reordering_solution.md](descisions/column_reordering_solution.md)** - US-007
  - Décision : SortableJS + Stimulus ⭐
  - Installation, code, accessibilité WCAG

- **[dashboard-widgets.md](descisions/dashboard-widgets.md)** - US-011
  - Décision : SortableJS + JSONB (MVP progressif)
  - Phase 1 : Ordre fixe, Phase 2 : Drag-drop

- **[form-validation-guide.md](descisions/form-validation-guide.md)** - US-015
  - Décision : Validation hybride (Stimulus + Rails)
  - Architecture, synchronisation, exemples complets

- **[darkmode-rails.md](descisions/darkmode-rails.md)** - US-017
  - ✅ Déjà implémenté - Réutiliser (voir [reutilisation-dark-mode.md](reutilisation-dark-mode.md))

### Classes CSS Disponibles
- **[reference-css-classes.md](reference-css-classes.md)** ⭐
  - Classes Bootstrap 5.3.2 standards
  - Classes Liquid custom du projet (`card-liquid`, `btn-liquid-primary`, etc.)
  - Variables CSS custom
  - Exemples d'utilisation depuis le codebase
  - Recommandations spécifiques panel admin

### Réutilisation Fonctionnalités Existantes
- **[reutilisation-dark-mode.md](reutilisation-dark-mode.md)** - Dark mode déjà implémenté
- **[analyse-stack-reelle.md](analyse-stack-reelle.md)** - Stack confirmée et incohérences corrigées

### Documentation Fonctionnelle
- **[inventaire-active-admin.md](inventaire-active-admin.md)** - Fonctionnalités à migrer depuis Active Admin
- **[guide-ux-ui.md](guide-ux-ui.md)** - Guide UX/UI et design
- **[methode-realisation.md](methode-realisation.md)** - Méthode de travail Agile

---

## 🎯 Prochaines Actions

1. **Lire** [START_HERE.md](START_HERE.md) - Guide de démarrage complet
2. **Consulter** les décisions techniques dans `descisions/` pour chaque US
3. **Référencer** [reference-css-classes.md](reference-css-classes.md) pour classes CSS
4. **Valider ce plan** avec l'équipe
5. **Créer branche** `feature/admin-panel-2025`
6. **Démarrer Sprint 1** : US-001 (Sidebar) avec guide [sidebar_guide_bootstrap5.md](descisions/sidebar_guide_bootstrap5.md)

**Prêt à démarrer ?** 🚀

👉 **Commencer par** [START_HERE.md](START_HERE.md)
