# Erreur #170-173 : Models ProductVariant (4 erreurs)

**Date d'analyse** : 2025-12-15  
**Priorité** : 🟡 Priorité 7  
**Catégorie** : Tests de Modèles  
**Statut** : ✅ **RÉSOLU** (5 tests passent)

---

## 📋 Informations Générales

- **Fichier test** : `spec/models/product_variant_spec.rb`
- **Lignes** : 19, 31, 38, 48
- **Tests** : Validations, associations
- **Nombre de tests** : 5 (tous passent maintenant)

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/models/product_variant_spec.rb
  ```

---

## 🔴 Erreurs Initiales

### Erreur 1 : Ligne 19 - `is valid with valid attributes`
```
Failure/Error: expect(build_variant).to be_valid
  expected #<ProductVariant ...> to be valid, but got errors: Une image (upload ou URL) est requise
```

### Erreur 2 : Ligne 31 - `enforces sku uniqueness`
```
Failure/Error: build_variant.save!

ActiveRecord::RecordInvalid:
  L'enregistrement est invalide
```

### Erreur 3 : Ligne 38 - `has many variant_option_values and option_values through join table`
```
Failure/Error: v.save!

ActiveRecord::RecordInvalid:
  L'enregistrement est invalide
```

### Erreur 4 : Ligne 48 - `destroys join rows when variant is destroyed`
```
Failure/Error: v.save!

ActiveRecord::RecordInvalid:
  L'enregistrement est invalide
```

---

## 🔍 Analyse

### Constats

Toutes les erreurs sont liées au fait que le helper `build_variant` ne fournit pas `image_url`, mais le modèle `ProductVariant` nécessite soit `image` (ActiveStorage) soit `image_url` via la validation personnalisée `image_or_image_url_present`.

Le modèle `ProductVariant` :
- Validation : `image_or_image_url_present` (validation personnalisée qui ajoute l'erreur sur `:base` si ni `image` ni `image_url` ne sont présents)

### Code du test

Le helper `build_variant` ne fournissait pas `image_url` dans ses valeurs par défaut :
```ruby
def build_variant(attrs = {})
  defaults = {
    product: product,
    sku: 'SKU-001',
    price_cents: 1900,
    currency: 'EUR',
    stock_qty: 5,
    is_active: true
    # image_url manquant !
  }
  ProductVariant.new(defaults.merge(attrs))
end
```

---

## 💡 Solutions Appliquées

### Solution : Ajout de `image_url` dans `build_variant`

**Problème** : Le helper `build_variant` ne fournit pas `image_url`, mais `ProductVariant` nécessite soit `image` soit `image_url`.

**Solution** : Ajouter `image_url` aux valeurs par défaut dans `build_variant`.

**Code appliqué** :
```ruby
# Avant
def build_variant(attrs = {})
  defaults = {
    product: product,
    sku: 'SKU-001',
    price_cents: 1900,
    currency: 'EUR',
    stock_qty: 5,
    is_active: true
  }
  ProductVariant.new(defaults.merge(attrs))
end

# Après
def build_variant(attrs = {})
  defaults = {
    product: product,
    sku: 'SKU-001',
    price_cents: 1900,
    currency: 'EUR',
    stock_qty: 5,
    is_active: true,
    image_url: 'https://example.org/variant.jpg'
  }
  ProductVariant.new(defaults.merge(attrs))
end
```

**Fichier modifié** : `spec/models/product_variant_spec.rb`
- Ligne 14 : Ajout de `image_url: 'https://example.org/variant.jpg'` dans les valeurs par défaut

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** :
- Données de test incomplètes (manque `image_url` dans le helper `build_variant`)

---

## 📊 Résultat

✅ **TOUS LES TESTS PASSENT** (5/5)

```
ProductVariant
  is valid with valid attributes
  requires sku and price_cents (currency defaults to EUR)
  enforces sku uniqueness
  has many variant_option_values and option_values through join table
  destroys join rows when variant is destroyed

Finished in 0.72156 seconds (files took 1.84 seconds to load)
5 examples, 0 failures
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

- C'est le même pattern que pour les autres tests corrigés précédemment (`OptionValue`, `OrderItem`, `Order`, `Product`) qui nécessitaient aussi `image_url` pour `ProductVariant`
- La correction a été appliquée directement dans le helper `build_variant`, ce qui résout toutes les erreurs d'un coup
- Aucune modification du modèle `ProductVariant` n'était nécessaire, seulement un ajustement dans le helper de test
