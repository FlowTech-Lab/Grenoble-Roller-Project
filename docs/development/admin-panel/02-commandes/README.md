# 📦 COMMANDES - Plan d'Implémentation

**Priorité** : 🔴 HAUTE | **Phase** : 1-2 | **Semaines** : 1-2

---

## 📋 Vue d'ensemble

Gestion des commandes avec workflow stock avancé : réservation à la création, libération si annulé, déduction si expédié.

**Objectif** : Intégrer le workflow reserve/release stock avec le système Inventories.

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
- [`gestion-commandes.md`](./gestion-commandes.md) - Workflow complet commandes + stock

---

## 🎯 Fonctionnalités Incluses

### ✅ Modifications Order
- Callback `after_create :reserve_stock`
- Méthode `handle_stock_on_status_change` (remplace `restore_stock_if_canceled`)

### ✅ Controller Orders
- Workflow complet (existe déjà, à améliorer)

### ✅ Policy Order
- Existe déjà

### ✅ Vues Orders
- Index, Show (existent déjà)

---

## ✅ Checklist Globale

### **Phase 1 (Semaine 1)**
- [ ] Modifier Order (reserve/release workflow)
- [ ] Intégrer avec Inventories

### **Phase 2 (Semaine 2)**
- [ ] Vérifier Controller Orders fonctionne
- [ ] Tester workflow complet

---

## 🔴 Points Critiques

1. **Order** : Ajouter workflow reserve/release stock
2. **Order** : Intégration avec Inventories (dépend de [`01-boutique/inventaire.md`](../01-boutique/inventaire.md))

---

## 📊 Estimation

- **Temps** : 1 semaine
- **Complexité** : ⭐⭐⭐
- **Dépendances** : Inventories (boutique)

---

**Retour** : [INDEX principal](../INDEX.md)
