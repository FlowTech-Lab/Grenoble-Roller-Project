# Tests RSpec - AdminPanel

## 📋 Structure des Tests

### **Policies** (`spec/policies/admin_panel/`)
- `base_policy_spec.rb` - Tests de la policy de base (level >= 60)
- `event/initiation_policy_spec.rb` - Tests des permissions initiations (lecture level >= 30, écriture level >= 60)
- `order_policy_spec.rb` - Tests des permissions commandes (level >= 60)
- `product_policy_spec.rb` - Tests des permissions produits (level >= 60)
- `roller_stock_policy_spec.rb` - Tests des permissions stock rollers (level >= 60)

### **Requests** (`spec/requests/admin_panel/`)
- `base_controller_spec.rb` - Tests d'authentification et autorisation BaseController
- `initiations_spec.rb` - Tests du controller InitiationsController
- `dashboard_spec.rb` - Tests du controller DashboardController
- `orders_spec.rb` - Tests du controller OrdersController

## 🎯 Permissions Testées

### **Grade 30 (INITIATION)**
- ✅ Peut accéder à `/admin-panel/initiations` (index, show)
- ❌ Ne peut pas créer/modifier/supprimer
- ❌ Ne peut pas accéder au dashboard
- ❌ Ne peut pas accéder aux commandes

### **Grade 40 (ORGANIZER)**
- ✅ Peut accéder à `/admin-panel/initiations` (index, show)
- ❌ Ne peut pas créer/modifier/supprimer
- ❌ Ne peut pas accéder au dashboard
- ❌ Ne peut pas accéder aux commandes
- ❌ Ne peut accéder à AUCUNE autre ressource

### **Grade 60 (ADMIN)**
- ✅ Accès complet à toutes les ressources
- ✅ Peut créer/modifier/supprimer des initiations
- ✅ Peut gérer les présences
- ✅ Peut accéder au dashboard
- ✅ Peut accéder aux commandes

### **Grade 70 (SUPERADMIN)**
- ✅ Accès complet (identique à ADMIN)

## 🚀 Exécution des Tests

```bash
# Tous les tests AdminPanel
bundle exec rspec spec/policies/admin_panel spec/requests/admin_panel

# Tests des policies uniquement
bundle exec rspec spec/policies/admin_panel

# Tests des controllers uniquement
bundle exec rspec spec/requests/admin_panel

# Test spécifique
bundle exec rspec spec/policies/admin_panel/event/initiation_policy_spec.rb
```

## 📝 Notes

- Les factories utilisent les traits `:initiation`, `:organizer`, `:admin`, `:superadmin`
- Les tests vérifient à la fois les policies (Pundit) et les controllers (authentification)
- Les redirections et messages d'erreur sont testés
