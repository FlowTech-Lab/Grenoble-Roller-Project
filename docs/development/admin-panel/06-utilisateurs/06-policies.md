# 🔐 POLICIES - Utilisateurs

**Priorité** : 🟡 MOYENNE | **Phase** : 6 | **Semaine** : 6+

---

## 📋 Description

Policies pour utilisateurs, rôles et adhésions.

---

## ✅ Policy 1 : UserPolicy (NOUVEAU)

**Fichier** : `app/policies/admin_panel/user_policy.rb`

**Code à implémenter** :
```ruby
module AdminPanel
  class UserPolicy < BasePolicy
    # À créer
  end
end
```

---

## ✅ Policy 2 : RolePolicy (NOUVEAU)

**Fichier** : `app/policies/admin_panel/role_policy.rb`

**Code à implémenter** :
```ruby
module AdminPanel
  class RolePolicy < BasePolicy
    # À créer
  end
end
```

---

## ✅ Policy 3 : MembershipPolicy (NOUVEAU)

**Fichier** : `app/policies/admin_panel/membership_policy.rb`

**Code à implémenter** :
```ruby
module AdminPanel
  class MembershipPolicy < BasePolicy
    # À créer
  end
end
```

---

## ✅ Checklist Globale

### **Phase 6 (Semaine 6+)**
- [ ] Créer UserPolicy
- [ ] Créer RolePolicy
- [ ] Créer MembershipPolicy
- [ ] Tester autorisations

---

**Retour** : [README Utilisateurs](./README.md) | [INDEX principal](../INDEX.md)
