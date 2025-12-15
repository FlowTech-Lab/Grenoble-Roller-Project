# Erreur #168-169 : Models Product (2 erreurs)

**Date d'analyse** : 2025-12-15  
**Priorité** : 🟡 Priorité 7  
**Catégorie** : Tests de Modèles  
**Statut** : ✅ **RÉSOLU** (4 tests passent)

---

## 📋 Informations Générales

- **Fichier test** : `spec/models/product_spec.rb`
- **Lignes** : 24, 41
- **Tests** :
  1. Ligne 24 : `Product requires presence of key attributes (except currency default)`
  2. Ligne 41 : `Product destroys variants when product is destroyed`
- **Nombre de tests** : 4 (tous passent maintenant)

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/models/product_spec.rb
  ```

---

## 🔴 Erreurs Initiales

### Erreur 1 : Ligne 24 - `requires presence of key attributes (except currency default)`
```
Failure/Error: expect(p.errors[:image_url]).to be_present
  expected `[].present?` to be truthy, got false
```

### Erreur 2 : Ligne 41 - `destroys variants when product is destroyed`
```
Failure/Error: variant = ProductVariant.create!(product: product, sku: 'SKU-001', price_cents: 2500, currency: 'EUR', stock_qty: 5, is_active: true)

ActiveRecord::RecordInvalid:
  L'enregistrement est invalide
```

---

## 🔍 Analyse

### Constats

1. **Erreur 1** : Le test attend une erreur de validation sur `image_url`, mais le modèle `Product` utilise une validation personnalisée `image_or_image_url_present` qui ajoute l'erreur sur `:base` au lieu de `:image_url`. Le message d'erreur est : `"Une image (upload ou URL) est requise"`.

2. **Erreur 2** : La création d'un `ProductVariant` échoue car il manque soit `image` (ActiveStorage) soit `image_url`. Le modèle `ProductVariant` a la même validation personnalisée `image_or_image_url_present` que `Product`.

### Code du modèle

Le modèle `Product` :
- Validations : `name`, `slug`, `price_cents`, `currency` (présence), `image_or_image_url_present` (validation personnalisée)
- La validation `image_or_image_url_present` ajoute l'erreur sur `:base`, pas sur `:image_url`

Le modèle `ProductVariant` :
- Validation : `image_or_image_url_present` (même logique que `Product`)

---

## 💡 Solutions Appliquées

### Solution 1 : Correction de l'assertion de validation (Erreur 1)

**Problème** : Le test attend une erreur sur `image_url`, mais la validation personnalisée ajoute l'erreur sur `:base`.

**Solution** : Changer l'assertion pour vérifier l'erreur sur `:base` au lieu de `:image_url`.

**Code appliqué** :
```ruby
# Avant (ligne 30)
expect(p.errors[:image_url]).to be_present

# Après
expect(p.errors[:base]).to be_present # image_or_image_url_present ajoute l'erreur sur :base
```

**Fichier modifié** : `spec/models/product_spec.rb`
- Ligne 30 : `expect(p.errors[:base]).to be_present`

### Solution 2 : Ajout de `image_url` pour `ProductVariant` (Erreur 2)

**Problème** : La création d'un `ProductVariant` échoue car il manque `image` ou `image_url`.

**Solution** : Ajouter `image_url` lors de la création du `ProductVariant` dans le test.

**Code appliqué** :
```ruby
# Avant (ligne 44)
variant = ProductVariant.create!(product: product, sku: 'SKU-001', price_cents: 2500, currency: 'EUR', stock_qty: 5, is_active: true)

# Après
variant = ProductVariant.create!(product: product, sku: 'SKU-001', price_cents: 2500, currency: 'EUR', stock_qty: 5, is_active: true, image_url: 'https://example.org/variant.jpg')
```

**Fichier modifié** : `spec/models/product_spec.rb`
- Ligne 44 : Ajout de `image_url: 'https://example.org/variant.jpg'`

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** :
- Assertion de validation incorrecte (attente d'erreur sur `:image_url` au lieu de `:base`)
- Données de test incomplètes (manque `image_url` pour `ProductVariant`)

---

## 📊 Résultat

✅ **TOUS LES TESTS PASSENT** (4/4)

```
Product
  is valid with valid attributes
  requires presence of key attributes (except currency default)
  enforces slug uniqueness
  destroys variants when product is destroyed

Finished in 0.40229 seconds (files took 1.9 seconds to load)
4 examples, 0 failures
```

---

## ✅ Actions Effectuées

1. [x] Exécuter les tests pour voir les erreurs exactes
2. [x] Analyser chaque erreur et documenter
3. [x] Identifier le type de problème (test ou logique)
4. [x] Proposer des solutions
5. [x] Appliquer les corrections
6. [x] Vérifier que tous les tests passent
7. [x] Mettre à jour le statut dans [README.md](../README.md)

---

## 📝 Notes

- Les validations `image_or_image_url_present` dans `Product` et `ProductVariant` ajoutent les erreurs sur `:base`, pas sur `:image_url`
- C'est le même pattern que pour les autres tests corrigés précédemment (`OptionValue`, `OrderItem`, `Order`) qui nécessitaient aussi `image_url` pour `ProductVariant`
- Aucune modification du modèle `Product` n'était nécessaire, seulement des ajustements dans les tests
