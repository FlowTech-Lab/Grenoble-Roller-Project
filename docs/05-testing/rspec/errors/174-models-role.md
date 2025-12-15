# Erreur #174-176 : Models Role (3 erreurs)

**Date d'analyse** : 2025-12-15  
**Priorité** : 🟡 Priorité 7  
**Catégorie** : Tests de Modèles  
**Statut** : ✅ **RÉSOLU** (5 tests passent)

---

## 📋 Informations Générales

- **Fichier test** : `spec/models/role_spec.rb`
- **Lignes** : 6, 19, 33
- **Tests** : Validations, associations
- **Nombre de tests** : 5 (tous passent maintenant)

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/models/role_spec.rb
  ```

---

## 🔴 Erreurs Initiales

### Erreur 1 : Ligne 6 - `is valid with valid attributes`
```
Failure/Error: expect(role).to be_valid
  expected #<Role ...> to be valid, but got errors: Name Translation missing. Options considered were:
  - fr.activerecord.errors.models.role.attributes.name.taken
  ...
```

### Erreur 2 : Ligne 19 - `enforces uniqueness on code and name`
```
Failure/Error: Role.create!(valid_attributes)

ActiveRecord::RecordInvalid:
  L'enregistrement est invalide
```

### Erreur 3 : Ligne 33 - `has many users`
```
Failure/Error: User.create!(email: 'a@example.com', password: 'password123', first_name: 'A', role: role)

ActiveRecord::RecordInvalid:
  L'enregistrement est invalide
```

---

## 🔍 Analyse

### Constats

1. **Erreurs 1-2** : Les tests utilisent des valeurs fixes (`name: 'Utilisateur'`, `code: 'ROLE_SPEC'`) qui peuvent déjà exister dans la base de données (probablement des données de seed). Le modèle `Role` a des validations d'unicité sur `name` et `code`, donc ces valeurs fixes causent des conflits.

2. **Erreur 3** : La création d'un `User` échoue car il manque des attributs requis (`skill_level`, `last_name`, etc.). Le modèle `User` nécessite plusieurs attributs obligatoires.

### Code du modèle

Le modèle `Role` :
- Validations : `name` (présence, unicité), `code` (présence, unicité), `level` (présence, entier positif)

Le modèle `User` :
- Validations : `skill_level` (présence, inclusion dans SKILL_LEVELS), `first_name` (présence, longueur max 50), `password` (longueur minimale 12 caractères), etc.

---

## 💡 Solutions Appliquées

### Solution 1 : Utilisation de valeurs uniques pour `Role` (Erreurs 1-2)

**Problème** : Les tests utilisent des valeurs fixes qui peuvent déjà exister dans la base de données.

**Solution** : Utiliser `SecureRandom.hex(3)` pour générer des valeurs uniques pour `name` et `code` dans chaque test.

**Code appliqué** :
```ruby
# Avant
let(:valid_attributes) { { name: 'Utilisateur', code: 'ROLE_SPEC', level: 1 } }

# Après
let(:valid_attributes) { { name: "Utilisateur-#{SecureRandom.hex(3)}", code: "ROLE_SPEC-#{SecureRandom.hex(3)}", level: 1 } }
```

**Fichier modifié** : `spec/models/role_spec.rb`
- Ligne 4 : Ajout de `SecureRandom.hex(3)` pour rendre `name` et `code` uniques
- Lignes 22, 23, 29 : Utilisation de valeurs uniques dans les autres tests également

### Solution 2 : Utilisation du helper `create_user` (Erreur 3)

**Problème** : La création d'un `User` échoue car il manque des attributs requis.

**Solution** : Utiliser le helper `create_user` de `TestDataHelper` qui fournit tous les attributs requis.

**Code appliqué** :
```ruby
# Avant
require 'rails_helper'

RSpec.describe Role, type: :model do
  # ...
  it 'has many users' do
    role = Role.create!(valid_attributes)
    User.create!(email: 'a@example.com', password: 'password123', first_name: 'A', role: role)
    User.create!(email: 'b@example.com', password: 'password123', first_name: 'B', role: role)
    expect(role.users.count).to eq(2)
  end
end

# Après
require 'rails_helper'

RSpec.describe Role, type: :model do
  include TestDataHelper
  # ...
  it 'has many users' do
    role = Role.create!(valid_attributes)
    create_user(role: role, email: 'a@example.com', first_name: 'A')
    create_user(role: role, email: 'b@example.com', first_name: 'B')
    expect(role.users.count).to eq(2)
  end
end
```

**Fichier modifié** : `spec/models/role_spec.rb`
- Ligne 4 : Ajout de `include TestDataHelper`
- Lignes 36-37 : Utilisation de `create_user` au lieu de `User.create!`

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** :
- Valeurs fixes causant des conflits d'unicité avec les données de seed
- Données de test incomplètes (manque d'attributs requis pour `User`)

---

## 📊 Résultat

✅ **TOUS LES TESTS PASSENT** (5/5)

```
Role
  is valid with valid attributes
  requires name, code and level
  enforces uniqueness on code and name
  requires level to be a positive integer
  has many users

Finished in 2.04 seconds (files took 1.72 seconds to load)
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

- Les valeurs uniques avec `SecureRandom.hex(3)` garantissent qu'il n'y a pas de conflits avec les données de seed
- L'utilisation du helper `create_user` garantit que tous les attributs requis pour `User` sont fournis
- Aucune modification du modèle `Role` n'était nécessaire, seulement des ajustements dans les tests
