# 📋 Admin Panel - Documentation

**Date** : 2025-12-21 | **Version** : 1.0 | **État** : 55% complété

> 📖 **Point d'entrée principal** : Ce README sert d'index pour toute la documentation du plan d'implémentation de l'Admin Panel.

---

## 🎯 Organisation par Thème Métier

Cette documentation est organisée par **thème métier** (boutique, commandes, initiations, etc.) plutôt que par type technique.

Chaque thème contient **tous les éléments nécessaires** (migrations, modèles, controllers, vues, etc.) pour être **indépendant** et **implémentable séparément**.

---

## 📂 Structure par Thème

### 📊 [00 - TABLEAU DE BORD](./00-dashboard/README.md)

**Priorité** : 🔴 HAUTE | **Phase** : 0-1 | **Semaine** : 1

Dashboard principal avec KPIs, statistiques et vue d'ensemble.

**Fichiers** :
- [`README.md`](./00-dashboard/README.md) - Vue d'ensemble
- [`dashboard.md`](./00-dashboard/dashboard.md) - Implémentation complète

---

### 🛒 [01 - BOUTIQUE](./01-boutique/README.md)

**Priorité** : 🔴 HAUTE | **Phase** : 1-3 | **Semaines** : 1-4

Gestion des produits, variantes, inventaire et catégories.

**Fichiers** :
- [`README.md`](./01-boutique/README.md) - Vue d'ensemble
- [`produits.md`](./01-boutique/produits.md) - Gestion produits
- [`variantes.md`](./01-boutique/variantes.md) - GRID éditeur variantes
- [`inventaire.md`](./01-boutique/inventaire.md) - Tracking stock
- [`categories.md`](./01-boutique/categories.md) - Catégories (optionnel)

---

### 📦 [02 - COMMANDES](./02-commandes/README.md)

**Priorité** : 🔴 HAUTE | **Phase** : 1-2 | **Semaines** : 1-2

Gestion des commandes et workflow stock (reserve/release).

**Fichiers** :
- [`README.md`](./02-commandes/README.md) - Vue d'ensemble
- [`gestion-commandes.md`](./02-commandes/gestion-commandes.md) - Workflow complet

---

### 🎓 [03 - INITIATIONS](./03-initiations/README.md)

**Priorité** : 🟡 MOYENNE | **Phase** : 5 | **Semaine** : 5

**Status** : ✅ **IMPLÉMENTÉ** - Module complet avec permissions par grade

Gestion des initiations, participants, bénévoles, liste d'attente.

**Fichiers** :
- [`README.md`](./03-initiations/README.md) - Vue d'ensemble
- [`gestion-initiations.md`](./03-initiations/gestion-initiations.md) - Workflow complet

**Fonctionnalités** :
- ✅ Séparation initiations à venir/passées
- ✅ Panel matériel demandé (groupé par taille)
- ✅ Permissions par grade (lecture level >= 30, écriture level >= 60)
- ✅ Tests RSpec complets (109 exemples)

---

### 📅 [04 - ÉVÉNEMENTS](./04-evenements/README.md)

**Priorité** : 🟢 BASSE | **Phase** : Future | **Semaine** : 6+

Gestion des événements (randonnées, sorties).

**Fichiers** :
- [`README.md`](./04-evenements/README.md) - Vue d'ensemble (à définir)

---

### 📧 [05 - MAILING](./05-mailing/README.md)

**Priorité** : 🟢 BASSE | **Phase** : Future | **Semaine** : 6+

Gestion des emails et notifications.

**Fichiers** :
- [`README.md`](./05-mailing/README.md) - Vue d'ensemble (à définir)

---

## 📊 Vue d'Ensemble Globale

| Thème | Priorité | Phase | Semaines | % Complété |
|-------|----------|-------|----------|------------|
| **Dashboard** | 🔴 HAUTE | 0-1 | 1 | ~30% |
| **Boutique** | 🔴 HAUTE | 1-3 | 1-4 | ~40% |
| **Commandes** | 🔴 HAUTE | 1-2 | 1-2 | ~60% |
| **Initiations** | 🟡 MOYENNE | 5 | 5 | ✅ **100%** |
| **Événements** | 🟢 BASSE | Future | 6+ | - |
| **Mailing** | 🟢 BASSE | Future | 6+ | - |

---

## 🚀 Ordre d'Implémentation Recommandé

### **Semaine 1** : Dashboard & Fondations
1. **Dashboard** : Améliorer KPIs et widgets
2. **Boutique** : Migrations + Modèles (Inventories)
3. **Commandes** : Modifications Order (workflow stock)

### **Semaine 2-3** : Controllers & Routes
3. **Boutique** : Controllers (Inventory, ProductVariants)
4. **Commandes** : Controller Orders

### **Semaine 3-4** : Vues
5. **Boutique** : Vues (GRID, Inventory dashboard)
6. **Commandes** : Vues Orders

### **Semaine 4** : JavaScript
7. **Boutique** : Stimulus GRID controller

### **Semaine 5** : Initiations
8. **Initiations** : Controller + Vues + Routes

---

## 📋 Index Complet

- [`INDEX.md`](./INDEX.md) - Index détaillé avec tous les blocs
- [`PERMISSIONS.md`](./PERMISSIONS.md) - 🔐 Documentation complète des permissions par grade
- [`ARCHIVES/elements-manquants.md`](./ARCHIVES/elements-manquants.md) - ⚠️ ARCHIVÉ (référence historique)
- [`00-dashboard/README.md`](./00-dashboard/README.md) - Dashboard

---

## 🔐 Permissions par Grade

**Documentation complète** : [`PERMISSIONS.md`](./PERMISSIONS.md)

**Résumé** :
- **Grade 30+** (INITIATION, ORGANIZER, MODERATOR) : Lecture seule des initiations
- **Grade 60+** (ADMIN, SUPERADMIN) : Accès complet à toutes les ressources

**Implémentation** : Utilise `role&.level.to_i >= X` (niveaux numériques) pour plus de flexibilité.

---

## 🧪 Tests RSpec

**Status** : ✅ Tests complets pour AdminPanel (109 exemples, 0 échecs)

**Couverture** :
- ✅ Policies (BasePolicy, InitiationPolicy, OrderPolicy, ProductPolicy, RollerStockPolicy)
- ✅ Controllers (BaseController, InitiationsController, DashboardController, OrdersController)
- ✅ Permissions par grade (30, 40, 60, 70)

**Exécution** :
```bash
bundle exec rspec spec/policies/admin_panel spec/requests/admin_panel
```

**Documentation** : Voir [`spec/requests/admin_panel/README.md`](../../../spec/requests/admin_panel/README.md)

---

## 🎯 Points Critiques par Thème

### 🛒 Boutique
1. **ProductVariant** : `has_one_attached :image` → `has_many_attached :images`
2. **ProductVariant** : Validation upload fichiers uniquement
3. **Inventories** : Création table + migration données

### 📦 Commandes
1. **Order** : Workflow reserve/release stock
2. **Order** : Intégration avec Inventories

---

## 📊 Estimation Globale

| Phase | Estimation | Temps Réel | Écart |
|-------|-----------|-----------|-------|
| PHASE 1 | 1 sem | 1 sem | ✅ OK |
| PHASE 2 | 1 sem | 1 sem | ✅ OK |
| PHASE 3 | 1 sem | 1-2 sem | ⚠️ +1 |
| PHASE 4 | 1 sem | 1-2 sem | ⚠️ +1 |
| PHASE 5 | 1 sem | 1 sem | ✅ OK (Initiations) |
| **TOTAL** | **5 sem** | **6-8 sem** | **+1-3 sem** |

**Plan Minimal Viable** (80% valeur) : **4 semaines** (Phases 1-2 + vues basiques)

---

**Créé le** : 2025-12-21 | **Version** : 1.1 | **Dernière mise à jour** : 2025-01-XX
