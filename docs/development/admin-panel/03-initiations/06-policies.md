# 🔐 POLICIES - Initiations

**Priorité** : 🟡 MOYENNE | **Phase** : 5 | **Semaine** : 5

---

## 📋 Description

Policies Pundit pour initiations et stock rollers.

---

## ✅ Policy 1 : InitiationPolicy

**Fichier** : `app/policies/admin_panel/initiation_policy.rb`

```ruby
# frozen_string_literal: true

module AdminPanel
  class InitiationPolicy < BasePolicy
    # Les méthodes index?, show?, create?, update?, destroy? héritent de BasePolicy
    # qui vérifie admin_user? (ADMIN ou SUPERADMIN)

    def presences?
      admin_user?
    end

    def update_presences?
      admin_user?
    end

    def convert_waitlist?
      admin_user?
    end

    def notify_waitlist?
      admin_user?
    end

    def toggle_volunteer?
      admin_user?
    end

    private

    def admin_user?
      user.present? && user.role&.code.in?(%w[ADMIN SUPERADMIN])
    end
  end
end
```

---

## ✅ Policy 2 : RollerStockPolicy

**Fichier** : `app/policies/admin_panel/roller_stock_policy.rb`

```ruby
# frozen_string_literal: true

module AdminPanel
  class RollerStockPolicy < BasePolicy
    # Les méthodes index?, show?, create?, update?, destroy? héritent de BasePolicy
    # qui vérifie admin_user? (ADMIN ou SUPERADMIN)

    # Pas de méthodes supplémentaires nécessaires pour l'instant
  end
end
```

---

## 📋 Autorisations

### **InitiationPolicy**

| Action | Autorisation | Rôle requis |
|--------|--------------|-------------|
| `index?` | ✅ Hérite de BasePolicy | ADMIN, SUPERADMIN |
| `show?` | ✅ Hérite de BasePolicy | ADMIN, SUPERADMIN |
| `create?` | ✅ Hérite de BasePolicy | ADMIN, SUPERADMIN |
| `update?` | ✅ Hérite de BasePolicy | ADMIN, SUPERADMIN |
| `destroy?` | ✅ Hérite de BasePolicy | ADMIN, SUPERADMIN |
| `presences?` | ✅ admin_user? | ADMIN, SUPERADMIN |
| `update_presences?` | ✅ admin_user? | ADMIN, SUPERADMIN |
| `convert_waitlist?` | ✅ admin_user? | ADMIN, SUPERADMIN |
| `notify_waitlist?` | ✅ admin_user? | ADMIN, SUPERADMIN |
| `toggle_volunteer?` | ✅ admin_user? | ADMIN, SUPERADMIN |

### **RollerStockPolicy**

| Action | Autorisation | Rôle requis |
|--------|--------------|-------------|
| `index?` | ✅ Hérite de BasePolicy | ADMIN, SUPERADMIN |
| `show?` | ✅ Hérite de BasePolicy | ADMIN, SUPERADMIN |
| `create?` | ✅ Hérite de BasePolicy | ADMIN, SUPERADMIN |
| `update?` | ✅ Hérite de BasePolicy | ADMIN, SUPERADMIN |
| `destroy?` | ✅ Hérite de BasePolicy | ADMIN, SUPERADMIN |

---

## ✅ Checklist Globale

### **Phase 5 (Semaine 5)**
- [ ] Créer InitiationPolicy
- [ ] Créer RollerStockPolicy
- [ ] Tester autorisations avec différents rôles
- [ ] Vérifier redirections si non autorisé

---

**Retour** : [README Initiations](./README.md) | [INDEX principal](../INDEX.md)
