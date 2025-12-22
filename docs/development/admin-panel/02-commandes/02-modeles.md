# 🏗️ MODÈLES - Commandes

**Priorité** : 🔴 HAUTE | **Phase** : 1-2 | **Semaine** : 1-2

---

## 📋 Description

Modifications du modèle Order pour intégrer le workflow reserve/release stock.

---

## ✅ Modèle : Order (MODIFICATIONS)

**Fichier** : `app/models/order.rb`

**Code à implémenter** :
```ruby
class Order < ApplicationRecord
  # À modifier : Ajouter callbacks et méthodes pour workflow stock
end
```

---

## ✅ Checklist Globale

### **Phase 1-2 (Semaine 1-2)**
- [ ] Modifier Order (reserve/release workflow)
- [ ] Tester callbacks
- [ ] Intégrer avec Inventories

---

**Retour** : [README Commandes](./README.md) | [INDEX principal](../INDEX.md)
