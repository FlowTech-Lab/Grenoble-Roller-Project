# Erreur #153 : Models OptionValue

**Date d'analyse initiale** : 2025-01-13  
**Dernière mise à jour** : 2025-12-15  
**Priorité** : 🟡 Priorité 7  
**Catégorie** : Tests de Modèles

---

## 📋 Informations Générales

- **Fichier test** : `spec/models/option_value_spec.rb`  
- **Ligne** : 17  
- **Test principal** : `OptionValue destroys join rows when option_value is destroyed`

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/models/option_value_spec.rb
  ```

---

## 🔴 Erreur observée (avant correction)

### Test : destruction en cascade des jointures

- **Contexte du test** :
  ```ruby
  it 'destroys join rows when option_value is destroyed' do
    category = ProductCategory.create!(name: 'Cat-ov', slug: 'cat-ov')
    product  = Product.create!(...)
    variant  = ProductVariant.create!(product: product, sku: 'SKU-OV', price_cents: 1000, currency: 'EUR', stock_qty: 5, is_active: true)
    ov       = OptionValue.create!(option_type: ot, value: 'XL', presentation: 'XL')
    VariantOptionValue.create!(variant: variant, option_value: ov)

    expect { ov.destroy }.to change { VariantOptionValue.count }.by(-1)
  end
  ```

- **Erreur levée** :
  - `ActiveRecord::RecordInvalid` lors de `ProductVariant.create!`.
  - Message de validation : `"Une image (upload ou URL) est requise"`.

- **Cause** :
  - Le modèle `ProductVariant` a une validation :
    ```ruby
    validate :image_or_image_url_present
    ```
  - Le test créait un `ProductVariant` **sans** image attachée et **sans** `image_url`, ce qui n'est plus accepté.

---

## 🔍 Analyse

### Modèle `OptionValue`

- Associations :
  - `belongs_to :option_type`
  - `has_many :variant_option_values, dependent: :destroy`
  - `has_many :product_variants, through: :variant_option_values`
- Validation :
  - `validates :value, presence: true, length: { maximum: 50 }`.
- **Comportement attendu** par le test :
  - Lorsqu'un `OptionValue` est détruit, toutes les lignes de jointure `VariantOptionValue` associées doivent être supprimées (`dependent: :destroy`).
- **Conclusion** :
  - La relation et le `dependent: :destroy` sont corrects.  
  - Le problème venait **uniquement** de la façon dont on construisait les données (le `ProductVariant` invalide), pas de la logique d’`OptionValue`.

### Modèle `ProductVariant`

- Valide si :
  - `sku`, `price_cents`, `currency` sont présents,  
  - et **au moins une image** est fournie : soit via ActiveStorage (`image`), soit via `image_url`.
- Le test ne s’occupait pas de cette contrainte et essayait de créer une variante nue.

---

## 💡 Solution appliquée

Pour rester simple et ne pas dépendre d’ActiveStorage dans ce test unitaire, on fournit une **URL d’image** à la variante :

```ruby
variant = ProductVariant.create!(
  product: product,
  sku: 'SKU-OV',
  price_cents: 1000,
  currency: 'EUR',
  stock_qty: 5,
  is_active: true,
  image_url: 'https://example.org/variant.jpg'
)
```

- Cela satisfait la validation `image_or_image_url_present` sans ajouter de complexité inutile au test.
- Le reste du scénario (création d'un `OptionValue`, d'un `VariantOptionValue`, puis destruction de l'`OptionValue`) reste identique.

---

## 🎯 Type de problème

- ❌ **PROBLÈME DE TEST**, pas de logique :
  - Le modèle `OptionValue` et la relation `dependent: :destroy` sur `variant_option_values` fonctionnaient déjà correctement.
  - Le test ne respectait simplement plus les nouvelles validations du modèle `ProductVariant`.

---

## 📊 Statut

- ✅ `spec/models/option_value_spec.rb` : **3 examples, 0 failures**.
- ✅ La destruction d'un `OptionValue` supprime bien les lignes de jointure `VariantOptionValue` associées.

---

## ✅ Actions réalisées

1. ✅ Exécution ciblée du test `OptionValue destroys join rows when option_value is destroyed`.  
2. ✅ Analyse de l’erreur `ActiveRecord::RecordInvalid` et identification de la validation manquante (`image_or_image_url_present` sur `ProductVariant`).  
3. ✅ Mise à jour du test pour fournir `image_url` à la variante.  
4. ✅ Re-lancement des specs : **0 échec**.  
5. ✅ Mise à jour de cette fiche d’erreur et préparation de la mise à jour du statut dans `README.md`.

---

## 📝 Récap des tests

| Ligne | Test | Statut |
|-------|------|--------|
| 6  | OptionValue is valid with value and option_type | ✅ Corrigé |
| 11 | OptionValue requires value | ✅ Corrigé |
| 17 | OptionValue destroys join rows when option_value is destroyed | ✅ Corrigé (ajout de `image_url` sur ProductVariant) |
