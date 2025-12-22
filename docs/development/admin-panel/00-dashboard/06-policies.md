# 🔐 POLICIES - Dashboard

**Priorité** : 🔴 HAUTE | **Phase** : 0-1 | **Semaine** : 1

---

## 📋 Description

Policies Pundit pour le dashboard et la maintenance.

---

## ✅ Policy 1 : DashboardPolicy (EXISTANT - Vérifier)

**Fichier** : `app/policies/admin_panel/dashboard_policy.rb`

**Code à vérifier** :
```ruby
module AdminPanel
  class DashboardPolicy < BasePolicy
    # À vérifier
  end
end
```

---

## ✅ Policy 2 : MaintenancePolicy (NOUVEAU)

**Fichier** : `app/policies/admin_panel/maintenance_policy.rb`

**Code à implémenter** :
```ruby
module AdminPanel
  class MaintenancePolicy < BasePolicy
    # À créer
  end
end
```

---

## ✅ Checklist Globale

### **Phase 0-1 (Semaine 1)**
- [ ] Vérifier DashboardPolicy
- [ ] Créer MaintenancePolicy
- [ ] Tester autorisations

---

**Retour** : [README Dashboard](./README.md) | [INDEX principal](../INDEX.md)
