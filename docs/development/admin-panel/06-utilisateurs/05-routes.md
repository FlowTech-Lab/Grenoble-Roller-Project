# 🛣️ ROUTES - Utilisateurs

**Priorité** : 🟡 MOYENNE | **Phase** : 6 | **Semaine** : 6+

---

## 📋 Description

Routes pour utilisateurs, rôles et adhésions.

---

## ✅ Routes

**Fichier** : `config/routes.rb`

**Code à implémenter** :
```ruby
namespace :admin_panel, path: 'admin-panel' do
  resources :users
  resources :roles
  resources :memberships do
    member do
      patch :activate
    end
  end
end
```

---

## ✅ Checklist Globale

### **Phase 6 (Semaine 6+)**
- [ ] Ajouter routes users
- [ ] Ajouter routes roles
- [ ] Ajouter routes memberships
- [ ] Tester toutes les routes

---

**Retour** : [README Utilisateurs](./README.md) | [INDEX principal](../INDEX.md)
