# Erreur #155-156 : Models Order (2 tests)

**Date d'analyse initiale** : 2025-01-13  
**Dernière mise à jour** : 2025-12-15  
**Priorité** : 🟡 Priorité 7  
**Catégorie** : Tests de Modèles

---

## 📋 Informations Générales

- **Fichier test** : `spec/models/order_spec.rb`  
- **Lignes** : 7, 13  
- **Tests** :
  1. `Order belongs to user and optionally to payment`
  2. `Order destroys order_items when destroyed`

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/models/order_spec.rb
  ```

---

## 🔴 Erreur observée (avant correction)

### Test : `destroys order_items when destroyed`

- **Contexte du test** :
  ```ruby
  it 'destroys order_items when destroyed' do
    category = ProductCategory.create!(...)
    product  = Product.create!(..., image_url: 'https://example.org/img.jpg')
    variant  = ProductVariant.create!(product: product, sku: 'SKU-...', price_cents: 1000, currency: 'EUR', stock_qty: 5, is_active: true)
    order    = Order.create!(user: user, status: 'pending', total_cents: 1000, currency: 'EUR')
    OrderItem.create!(order: order, variant_id: variant.id, quantity: 1, unit_price_cents: 1000)

    expect { order.destroy }.to change { OrderItem.count }.by(-1)
  end
  ```

- **Erreur levée** :
  - `ActiveRecord::RecordInvalid` lors de `ProductVariant.create!`.
  - Message de validation : `"Une image (upload ou URL) est requise"` (venant de `ProductVariant`).

- **Cause** :
  - Le modèle `ProductVariant` exige désormais soit une image attachée, soit une `image_url` via :
    ```ruby
    validate :image_or_image_url_present
    ```
  - Le test créait une variante sans aucune image, ce qui bloque avant même de tester le comportement d’`Order`.

Le premier test (`belongs to user and optionally to payment`) passait déjà, seul le second posait problème.

---

## 🔍 Analyse

### Modèle `Order`

- Associations :
  - `belongs_to :user`
  - `belongs_to :payment, optional: true`
  - `has_many :order_items, dependent: :destroy`.
- Callbacks :
  - `restore_stock_if_canceled` : remet le stock des variantes si le statut passe à `cancelled`.
  - `notify_status_change` : envoie les bons emails lors d’un changement de statut.

Pour le test qui nous intéresse, la seule chose à vérifier est que :
- la relation `has_many :order_items, dependent: :destroy` fonctionne correctement,
- c’est‑à‑dire qu’un `OrderItem` est supprimé lorsque l’`Order` est détruite.

### Modèle `ProductVariant`

- Validation clé :
  ```ruby
  validate :image_or_image_url_present

  def image_or_image_url_present
    return if image.attached? || image_url.present?
    errors.add(:base, "Une image (upload ou URL) est requise")
  end
  ```
- Le test créait une variante minimale, sans `image` ni `image_url` → création invalide.

Conclusion : la logique d’`Order` est bonne, le test était juste **en retard** sur les validations de `ProductVariant`.

---

## 💡 Solution appliquée

Pour corriger le test sans complexifier inutilement, on fournit une URL d’image à la variante :

```ruby
variant = ProductVariant.create!(
  product: product,
  sku: "SKU-#{SecureRandom.hex(2)}",
  price_cents: 1000,
  currency: 'EUR',
  stock_qty: 5,
  is_active: true,
  image_url: 'https://example.org/variant.jpg'
)
```

- La validation `image_or_image_url_present` est satisfaite.
- Le test peut alors créer un `OrderItem` pointant sur cette variante et vérifier que la destruction de l’`Order` fait bien chuter le `OrderItem.count` de 1.

---

## 🎯 Type de problème

- ❌ **PROBLÈME DE TEST**, pas de logique `Order` :
  - Le `dependent: :destroy` sur `order_items` fonctionnait déjà.
  - Le scénario d’échec ne venait que de la création d’une `ProductVariant` invalide.

---

## 📊 Statut

- ✅ `spec/models/order_spec.rb` : **2 examples, 0 failures**.  
- ✅ Les deux tests (`belongs to user...` et `destroys order_items when destroyed`) sont maintenant verts.

---

## ✅ Actions réalisées

1. ✅ Exécution des specs `Order` pour reproduire l’erreur.  
2. ✅ Analyse des validations `ProductVariant` pour comprendre le `RecordInvalid`.  
3. ✅ Ajout d’un `image_url` à la création de la variante dans la spec.  
4. ✅ Re-lancement de la spec `order_spec` → **0 échec**.  
5. ✅ Mise à jour de cette fiche d’erreur et du `README` RSpec.

---

## 📝 Récap des tests

| Ligne | Test | Statut |
|-------|------|--------|
| 7  | Order belongs to user and optionally to payment | ✅ Corrigé |
| 13 | Order destroys order_items when destroyed | ✅ Corrigé (variant conforme aux validations ProductVariant) |
