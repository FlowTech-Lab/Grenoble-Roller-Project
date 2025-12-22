# 🎓 INITIATIONS - Plan d'Implémentation

**Priorité** : 🟡 MOYENNE | **Phase** : 5 | **Semaine** : 5

---

## 📋 Vue d'ensemble

Gestion des initiations : participants, bénévoles, liste d'attente, présences.

**Objectif** : Migrer la gestion des initiations depuis ActiveAdmin vers AdminPanel pour une interface unifiée.

**Status actuel** : ✅ **IMPLÉMENTÉ** - Module complet fonctionnel dans AdminPanel

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
- [`gestion-initiations.md`](./gestion-initiations.md) - Workflow complet initiations
- [`stock-rollers.md`](./stock-rollers.md) - Gestion stock rollers

---

## 🎯 Fonctionnalités Incluses

### ✅ Controller Initiations
- CRUD initiations
- Gestion participants/bénévoles
- Liste d'attente (convertir, notifier)
- Dashboard présences
- **Séparation initiations à venir / passées** (triées par date)
- **Récapitulatif matériel demandé** (groupé par taille)

### ✅ Policy Initiation
- Autorisations admin (ADMIN et SUPERADMIN uniquement)

### ✅ Routes Initiations
- Routes REST + actions personnalisées

### ✅ Vues Initiations
- **Index** : Liste séparée (à venir / passées), bouton "Créer une initiation" (admin uniquement)
- **Show** : Détails + panels, bouton "Éditer" (admin uniquement, ouvre dans nouvel onglet)
- **Presences** : Dashboard présences avec statuts traduits en français

### ✅ RollerStock (Stock Rollers)
- Liste avec filtres (taille, quantité, actif)
- CRUD complet
- Panel "Demandes en attente" (attendances avec besoin matériel)
- Gestion tailles (EU)
- Activation/désactivation tailles

---

## ✅ Checklist Globale

### **Phase 5 (Semaine 5)**
- [ ] Controller InitiationsController
- [ ] Controller RollerStock
- [ ] Policy InitiationPolicy
- [ ] Policy RollerStock
- [ ] Routes initiations + roller_stock
- [ ] Vue index
- [ ] Vue show
- [ ] Vue presences
- [ ] Vues RollerStock (index, show, edit, new)
- [ ] Partials (bénévoles, participants, waitlist)

---

## 📊 Estimation

- **Temps** : 1-2 semaines
- **Complexité** : ⭐⭐⭐
- **Dépendances** : Aucune (utilise le modèle `Attendance` existant pour demandes matériel)

---

**Retour** : [INDEX principal](../INDEX.md)
