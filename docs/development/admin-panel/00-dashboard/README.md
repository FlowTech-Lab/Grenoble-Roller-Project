# 📊 TABLEAU DE BORD - Plan d'Implémentation

**Priorité** : 🔴 HAUTE | **Phase** : 0-1 | **Semaine** : 1

---

## 📋 Vue d'ensemble

Tableau de bord principal de l'Admin Panel : KPIs, statistiques, vue d'ensemble de l'activité.

**Objectif** : Fournir une vue globale de l'activité (commandes, produits, stock, initiations) avec KPIs et actions rapides.

**Status actuel** : ✅ Existe déjà (basique) - À améliorer

---

## 📄 Documentation

### **📁 Fichiers détaillés par type (CODE EXACT)**
- [`01-migrations.md`](./01-migrations.md) - Migrations (code exact)
- [`02-modeles.md`](./02-modeles.md) - Modèles (code exact)
- [`03-services.md`](./03-services.md) - Services (code exact)
- [`04-controllers.md`](./04-controllers.md) - Controllers (code exact)
- [`05-routes.md`](./05-routes.md) - Routes (code exact)
- [`06-policies.md`](./06-policies.md) - Policies (code exact)
- [`07-vues.md`](./07-vues.md) - Vues ERB (code exact)
- [`08-javascript.md`](./08-javascript.md) - JavaScript (code exact)

### **📁 Fichiers par fonctionnalité**
- [`dashboard.md`](./dashboard.md) - Implémentation complète du dashboard
- [`maintenance.md`](./maintenance.md) - Mode maintenance
- [`sidebar.md`](./sidebar.md) - 🎨 **Sidebar Admin Panel** (structure, partials, optimisations)

---

## 🎯 Fonctionnalités Incluses

### ✅ Controller Dashboard
- Existe déjà (`app/controllers/admin_panel/dashboard_controller.rb`)
- Statistiques basiques (users, products, orders)

### ✅ Vue Dashboard
- Existe déjà (`app/views/admin_panel/dashboard/index.html.erb`)
- 4 cartes statistiques
- Liste commandes récentes

### ✅ Mode Maintenance
- Page dédiée pour activer/désactiver maintenance
- Toggle via controller personnalisé
- Affichage statut actuel
- Informations techniques

### ✅ Sidebar Admin Panel
- **Partial réutilisable** : Desktop + Mobile (DRY)
- **Sous-menus** : Boutique avec collapse/expand Bootstrap
- **Helpers permissions** : `can_access_admin_panel?()`, `can_view_initiations?()`, etc.
- **Controller Stimulus optimisé** : 7 problèmes critiques corrigés (debounce, cache, cleanup, etc.)
- **CSS organisé** : Fichier `admin_panel.scss` dédié (0 style inline)
- **JavaScript séparé** : `admin_panel_navbar.js` pour calcul hauteur navbar
- **Responsive** : Desktop (sidebar fixe) + Mobile (offcanvas)
- **Persistance** : LocalStorage pour état collapsed/expanded

**Voir** : [`sidebar.md`](./sidebar.md) pour la documentation complète.

### 🔧 Améliorations à Apporter
- KPIs avancés (CA, stock faible, initiations à venir)
- Graphiques (ventes, tendances)
- Actions rapides
- Widgets personnalisables

---

## ✅ Checklist Globale

### **Phase 0-1 (Semaine 1)**
- [ ] Améliorer DashboardController (KPIs avancés)
- [ ] Améliorer vue Dashboard (widgets, graphiques)
- [ ] Ajouter service AdminDashboardService
- [ ] Intégrer avec Inventories (stock faible)
- [ ] Intégrer avec Orders (CA, tendances)
- [ ] Intégrer avec Initiations (à venir)
- [ ] Migrer Mode Maintenance (controller + vue)

---

## 🔗 Dépendances

- **Inventories** : Pour afficher stock faible (nécessite [`01-boutique/inventaire.md`](../01-boutique/inventaire.md))
- **Orders** : Pour afficher CA et tendances (nécessite [`02-commandes/gestion-commandes.md`](../02-commandes/gestion-commandes.md))
- **Initiations** : Pour afficher initiations à venir (nécessite [`03-initiations/gestion-initiations.md`](../03-initiations/gestion-initiations.md))

---

## 📊 Estimation

- **Temps** : 1 semaine
- **Complexité** : ⭐⭐⭐
- **Dépendances** : Boutique, Commandes, Initiations (partiellement)

---

**Retour** : [INDEX principal](../INDEX.md)
