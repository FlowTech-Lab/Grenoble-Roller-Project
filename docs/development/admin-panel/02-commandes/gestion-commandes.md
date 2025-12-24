# 📦 COMMANDES - Gestion Commandes

**Priorité** : 🔴 HAUTE | **Phase** : 1-2 | **Semaines** : 1-2

---

## 📋 Description

Workflow complet de gestion des commandes avec intégration du système Inventories pour la réservation/libération du stock.

**Fichier actuel** : `app/models/order.rb` (existe déjà)

---

## 🔧 Modifications Order

### **Modèle Order**

**Fichier** : `app/models/order.rb`

**Modifications** :
1. Ajouter callback `after_create :reserve_stock`
2. Remplacer `restore_stock_if_canceled` par `handle_stock_on_status_change`

**Code complet** :
```ruby
class Order < ApplicationRecord
  include Hashid::Rails

  belongs_to :user
  belongs_to :payment, optional: true
  has_many :order_items, dependent: :destroy

  # Callbacks pour gérer le stock et les notifications
  after_create :reserve_stock  # NOUVEAU
  after_update :handle_stock_on_status_change, if: :saved_change_to_status?
  after_update :notify_status_change, if: :saved_change_to_status?

  private

  # NOUVEAU : Réserver le stock à la création
  def reserve_stock
    return unless status == 'pending'
    
    order_items.includes(:variant).each do |item|
      variant = item.variant
      next unless variant&.inventory
      variant.inventory.reserve_stock(item.quantity, self.id)
    end
  end

  # AMÉLIORÉ : Gérer stock selon changement de statut
  def handle_stock_on_status_change
    previous_status = attribute_was(:status) || status_before_last_save
    current_status = status
    
    return unless previous_status.present? && previous_status != current_status

    case current_status
    when 'paid', 'preparation'
      # Stock déjà réservé, rien à faire
      
    when 'shipped'
      # Déduire définitivement du stock
      order_items.includes(:variant).each do |item|
        variant = item.variant
        next unless variant&.inventory
        
        variant.inventory.move_stock(-item.quantity, 'order_fulfilled', id, Current.user)
        variant.inventory.release_stock(item.quantity, id)
      end
      
    when 'cancelled', 'refunded'
      # Libérer le stock réservé
      order_items.includes(:variant).each do |item|
        variant = item.variant
        next unless variant&.inventory
        
        variant.inventory.release_stock(item.quantity, id)
      end
    end
  end

  # Existant : Notification email
  def notify_status_change
    # ... code existant ...
  end
end
```

---

## 🎮 Controller Orders

**Fichier** : `app/controllers/admin_panel/orders_controller.rb`

**Status** : ✅ Existe déjà (basique)

**À vérifier** :
- Export CSV fonctionne-t-il ?
- Workflow change_status fonctionne-t-il avec nouveau système Inventories ?

---

## 🛣️ Routes

**Fichier** : `config/routes.rb`

```ruby
resources :orders do
  member { patch :change_status }
  collection { get :export }
end
```

**Status** : ✅ Existe déjà

---

## 🔐 Policy

**Fichier** : `app/policies/admin_panel/order_policy.rb`

**Status** : ✅ Existe déjà

---

## 🎨 Vues

**Fichiers** :
- `app/views/admin_panel/orders/index.html.erb` - ✅ Existe
- `app/views/admin_panel/orders/show.html.erb` - ✅ Existe

**À adapter** :
- Afficher stock réservé vs disponible
- Afficher historique mouvements stock liés à la commande

---

## ✅ Checklist

### **Phase 1 (Semaine 1)**
- [ ] Modifier Order (ajouter `after_create :reserve_stock`)
- [ ] Remplacer `restore_stock_if_canceled` par `handle_stock_on_status_change`
- [ ] Tester réservation stock à la création
- [ ] Tester libération stock si annulé
- [ ] Tester déduction stock si expédié

### **Phase 2 (Semaine 2)**
- [ ] Vérifier Controller Orders fonctionne
- [ ] Adapter vues pour afficher stock réservé
- [ ] Tester workflow complet end-to-end

---

## 🔗 Dépendances

- **Inventories** : Nécessite [`01-boutique/inventaire.md`](../01-boutique/inventaire.md) terminé
- **ProductVariant** : Nécessite relation `has_one :inventory`

---

## ⚠️ Points d'attention

1. **Création commande** : Stock réservé immédiatement (status: 'pending')
2. **Annulation** : Stock libéré (reserved_qty décrémenté)
3. **Expédition** : Stock déduit définitivement (stock_qty décrémenté, reserved_qty libéré)
4. **Remboursement** : Même traitement que annulation

---

**Retour** : [README Commandes](./README.md) | [INDEX principal](../INDEX.md)
