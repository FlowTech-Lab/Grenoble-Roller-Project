# 🛣️ ROUTES - Dashboard

**Priorité** : 🔴 HAUTE | **Phase** : 0-1 | **Semaine** : 1

---

## 📋 Description

Routes pour le dashboard et la maintenance.

---

## ✅ Routes à Ajouter/Modifier

**Fichier** : `config/routes.rb`

**Code à implémenter** :
```ruby
namespace :admin_panel, path: 'admin-panel' do
  root 'dashboard#index'
  get 'dashboard', to: 'dashboard#index'
  
  # Maintenance
  get 'maintenance', to: 'maintenance#show'
  patch 'maintenance/toggle', to: 'maintenance#toggle'
end
```

---

## ✅ Checklist Globale

### **Phase 0-1 (Semaine 1)**
- [ ] Vérifier routes dashboard
- [ ] Ajouter routes maintenance
- [ ] Tester toutes les routes

---

**Retour** : [README Dashboard](./README.md) | [INDEX principal](../INDEX.md)
