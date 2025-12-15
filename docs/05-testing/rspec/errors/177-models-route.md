# Erreur #177-180 : Models Route (4 erreurs)

**Date d'analyse** : 2025-12-15  
**Priorité** : 🟡 Priorité 7  
**Catégorie** : Tests de Modèles  
**Statut** : ✅ **RÉSOLU** (5 tests passent)

---

## 📋 Informations Générales

- **Fichier test** : `spec/models/route_spec.rb`
- **Lignes** : 10, 16, 22, 31
- **Tests** : Validations, associations
- **Nombre de tests** : 5 (tous passent maintenant)

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/models/route_spec.rb
  ```

---

## 🔴 Erreur Initiale

### Erreur : Ligne 31 - `nullifies route on associated events when destroyed`
```
Failure/Error: FactoryBot.create(:event, attrs)

ActiveRecord::RecordInvalid:
  L'enregistrement est invalide
```

**Note** : Les autres tests (lignes 10, 16, 22) passaient déjà sans modification.

---

## 🔍 Analyse

### Constats

Le test `nullifies route on associated events when destroyed` utilise `create_event(route: route)` qui appelle `FactoryBot.create(:event, attrs)`. La factory `:event` essaie de créer automatiquement une route via `association :route`, mais cela peut causer des problèmes ou des conflits.

Le problème vient du fait que `create_event` utilise `FactoryBot.create(:event, attrs)`, qui peut avoir des problèmes avec les associations ou les validations complexes.

### Solution alternative

Utiliser `build_event` et `save!` au lieu de `create_event` pour éviter les problèmes potentiels avec la factory.

---

## 💡 Solutions Appliquées

### Solution : Utilisation de `build_event` au lieu de `create_event`

**Problème** : `create_event` utilise `FactoryBot.create(:event, attrs)` qui peut avoir des problèmes avec les associations ou les validations.

**Solution** : Utiliser `build_event` et `save!` au lieu de `create_event` pour créer l'événement manuellement.

**Code appliqué** :
```ruby
# Avant
require 'rails_helper'

RSpec.describe Route, type: :model do
  # ...
  describe 'associations' do
    it 'nullifies route on associated events when destroyed' do
      route = create_route
      event = create_event(route: route)

      expect { route.destroy }.to change { event.reload.route }.from(route).to(nil)
    end
  end
end

# Après
require 'rails_helper'

RSpec.describe Route, type: :model do
  include TestDataHelper
  # ...
  describe 'associations' do
    it 'nullifies route on associated events when destroyed' do
      route = create_route
      event = build_event(route: route)
      event.save!

      expect { route.destroy }.to change { event.reload.route }.from(route).to(nil)
    end
  end
end
```

**Fichier modifié** : `spec/models/route_spec.rb`
- Ligne 4 : Ajout de `include TestDataHelper`
- Ligne 35 : Remplacement de `create_event(route: route)` par `build_event(route: route)`
- Ligne 36 : Ajout de `event.save!`

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** :
- Utilisation de `create_event` qui peut avoir des problèmes avec les associations complexes de FactoryBot

---

## 📊 Résultat

✅ **TOUS LES TESTS PASSENT** (5/5)

```
Route
  validations
    is valid with minimal attributes
    requires a name
    limits difficulty to the allowed list
    rejects negative distance or elevation
  associations
    nullifies route on associated events when destroyed

Finished in 1.53 seconds (files took 2.03 seconds to load)
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

- Les autres tests (validations) passaient déjà sans modification
- La solution utilise `build_event` et `save!` au lieu de `create_event` pour éviter les problèmes potentiels avec FactoryBot
- Aucune modification du modèle `Route` n'était nécessaire, seulement un ajustement dans le test
