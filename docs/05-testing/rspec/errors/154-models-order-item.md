# Erreur #154 : Models OrderItem

**Date d'analyse initiale** : 2025-01-13  
**Dernière mise à jour** : 2025-12-15  
**Priorité** : 🟡 Priorité 7  
**Catégorie** : Tests de Modèles

---

## 📋 Informations Générales

- **Fichier test** : `spec/models/order_item_spec.rb`  
- **Ligne** : 11  
- **Test** : `OrderItem belongs to order and variant`

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/models/order_item_spec.rb
  ```

---

## 🔴 Erreur observée (avant correction)

### Test : `belongs to order and variant`

- **Contexte du test** :
  ```ruby
  let!(:variant) { ProductVariant.create!(product: product, sku: "SKU-...", price_cents: 1000, currency: 'EUR', stock_qty: 5, is_active: true) }

  it 'belongs to order and variant' do
    item = OrderItem.new(order: order, variant_id: variant.id, quantity: 2, unit_price_cents: 1000)
    expect(item).to be_valid
    # ...
  end
  ```

- **Erreur levée** :
  - `ActiveRecord::RecordInvalid` lors de la création de `ProductVariant`.
  - Message de validation (lu via un runner séparé) : `"Une image (upload ou URL) est requise"`.

- **Cause** :
  - Le modèle `ProductVariant` possède une validation :
    ```ruby
    validate :image_or_image_url_present
    ```
  - Le test créait la variante **sans image et sans `image_url`**, ce qui n’est plus valide.

---

## 🔍 Analyse

### Modèle `OrderItem`

- Associations :
  - `belongs_to :order`
  - `belongs_to :variant, class_name: 'ProductVariant', foreign_key: :variant_id`.
- Ransack : méthodes `ransackable_attributes` et `ransackable_associations` seulement.  
- Aucune validation métier complexe ici : le but du test est de vérifier que :
  - un `OrderItem` est valide avec un `order`, un `variant_id`, une `quantity` et un `unit_price_cents`;
  - les associations `order` et `variant` fonctionnent.

### Modèle `ProductVariant`

- Validation importante pour ce test :
  ```ruby
  validate :image_or_image_url_present

  def image_or_image_url_present
    return if image.attached? || image_url.present?
    errors.add(:base, "Une image (upload ou URL) est requise")
  end
  ```
- Le test ignorait cette contrainte, ce qui faisait échouer la création de la variante **avant même** de pouvoir tester `OrderItem`.

Conclusion : la logique d’`OrderItem` était correcte, c’est la **donnée de test (variant)** qui n’était plus conforme au modèle.

---

## 💡 Solution appliquée

Pour garder le test simple et indépendant d’ActiveStorage, on fournit une **URL d’image** à la variante :

```ruby
let!(:variant) do
  ProductVariant.create!(
    product: product,
    sku: "SKU-#{SecureRandom.hex(2)}",
    price_cents: 1000,
    currency: 'EUR',
    stock_qty: 5,
    is_active: true,
    image_url: 'https://example.org/variant.jpg'
  )
end
```

- Cela satisfait la validation `image_or_image_url_present` sans avoir à gérer de fichiers ou de stockage.
- Le test peut alors se concentrer sur ce qu’il veut vraiment vérifier : `OrderItem` appartient bien à une commande et à une variante existantes.

---

## 🎯 Type de problème

- ❌ **PROBLÈME DE TEST**, pas de logique modèle :
  - `OrderItem` et ses associations sont correctement définis.
  - Le test ne respectait simplement plus les validations actuelles de `ProductVariant`.

---

## 📊 Statut

- ✅ `spec/models/order_item_spec.rb` : **1 example, 0 failures**.  
- ✅ Le test `belongs to order and variant` est maintenant vert.

---

## ✅ Actions réalisées

1. ✅ Exécution du test `OrderItem belongs to order and variant` pour reproduire l’erreur.  
2. ✅ Analyse des validations de `ProductVariant` pour comprendre pourquoi la variante était invalide.  
3. ✅ Ajout de `image_url` lors de la création de `ProductVariant` dans la spec.  
4. ✅ Re-lancement des specs : **0 échec**.  
5. ✅ Mise à jour de cette fiche d’erreur et du `README` RSpec.

---

## 📝 Récap du test

| Ligne | Test | Statut |
|-------|------|--------|
| 11 | OrderItem belongs to order and variant | ✅ Corrigé (variant conforme aux validations ProductVariant) |
