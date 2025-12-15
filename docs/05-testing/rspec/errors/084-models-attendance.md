# Erreur #084 : Models Attendance - Scope `active`

**Date d'analyse** : 2025-12-15  
**Priorité** : 🟡 Priorité 7  
**Catégorie** : Tests de Modèles

---

## 📋 Informations Générales

- **Fichier test** : `spec/models/attendance_spec.rb`
- **Ligne** : 111
- **Test** : `returns non-canceled attendances for active scope`
- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/models/attendance_spec.rb:111
  ```

---

## 🔴 Erreur

```
Failure/Error: FactoryBot.create(:event, attrs)

ActiveRecord::RecordInvalid:
  L'enregistrement est invalide
# ./spec/support/test_data_helper.rb:72:in 'TestDataHelper#create_event'
# ./spec/support/test_data_helper.rb:77:in 'TestDataHelper#build_attendance'
# ./spec/support/test_data_helper.rb:88:in 'TestDataHelper#create_attendance'
# ./spec/models/attendance_spec.rb:112:in 'block (3 levels) in <top (required)>'
```

---

## 🔍 Analyse

### Constats
- ❌ Le helper `create_attendance` utilise `create_event` qui appelle `FactoryBot.create(:event, attrs)`
- ❌ La factory `:event` échoue avec `ActiveRecord::RecordInvalid: L'enregistrement est invalide`
- ✅ Le test utilise `Attendance.delete_all` dans le `before` pour nettoyer les données
- ✅ Le scope `active` est défini correctement : `scope :active, -> { where.not(status: "canceled") }`

### Cause Probable

Le problème vient de la factory `:event` qui échoue lors de la création. Le helper `create_event` dans `TestDataHelper` appelle `FactoryBot.create(:event, attrs)` qui échoue probablement à cause de validations manquantes (comme `cover_image`).

### Code Actuel

```ruby
# spec/support/test_data_helper.rb ligne 70-73
def create_event(attrs = {})
  # Utiliser la factory :event qui gère déjà l'image de couverture
  FactoryBot.create(:event, attrs)
end

# spec/models/attendance_spec.rb ligne 111-115
it 'returns non-canceled attendances for active scope' do
  active = create_attendance(status: 'registered')
  create_attendance(status: 'canceled')
  
  expect(Attendance.active).to contain_exactly(active)
end
```

---

## 💡 Solutions Proposées

### Solution 1 : Utiliser `build_event` au lieu de `create_event` dans le helper

**Problème** : `FactoryBot.create(:event, attrs)` échoue à cause de validations.

**Solution** : Utiliser `build_event` qui existe déjà dans `TestDataHelper` et gérer la sauvegarde manuellement.

```ruby
# spec/support/test_data_helper.rb
def create_event(attrs = {})
  event = build_event(attrs)
  event.save!
  event
end
```

### Solution 2 : Utiliser directement `build_event` dans le test

**Problème** : Le helper `create_event` échoue.

**Solution** : Utiliser directement `build_event` et `save!` dans le test, ou créer l'événement manuellement.

```ruby
it 'returns non-canceled attendances for active scope' do
  event = build_event
  event.save!
  active = create_attendance(event: event, status: 'registered')
  canceled = create_attendance(event: event, status: 'canceled')
  
  expect(Attendance.active).to contain_exactly(active)
end
```

### Solution 3 : Corriger la factory `:event` pour gérer les validations

**Problème** : La factory `:event` ne gère pas correctement toutes les validations.

**Solution** : Vérifier que la factory `:event` gère bien `cover_image` et autres validations requises.

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** :
- Le helper `create_event` utilise une factory qui échoue
- La factory `:event` ne gère pas correctement toutes les validations requises

---

## 📊 Statut

✅ **RÉSOLU** - Le test passe maintenant (corrigé via la correction de `create_event` dans TestDataHelper)

---

## 🔗 Erreurs Similaires

Cette erreur est similaire aux erreurs suivantes :
- [191-jobs-event-reminder-job.md](191-jobs-event-reminder-job.md) - Même problème avec `create(:event, ...)`
- [039-mailers-event-mailer.md](039-mailers-event-mailer.md) - Même problème avec `create(:event, ...)`

---

## 📝 Notes

- Le helper `build_event` existe déjà et gère correctement les attributs par défaut
- Le problème vient de `create_event` qui utilise `FactoryBot.create(:event, attrs)` au lieu de `build_event`
- Le scope `active` lui-même semble correct, c'est la création de l'événement qui pose problème

---

## ✅ Actions à Effectuer

1. [x] Modifier `create_event` dans `TestDataHelper` pour utiliser `build_event` + `save!`
2. [x] Exécuter le test pour vérifier qu'il passe
3. [x] Vérifier que les autres tests utilisant `create_event` fonctionnent toujours
4. [x] Mettre à jour le statut dans [README.md](../README.md)

## ✅ Solution Appliquée

**Modification dans `spec/support/test_data_helper.rb`** :
```ruby
def create_event(attrs = {})
  # Utiliser build_event qui gère correctement les attributs par défaut
  event = build_event(attrs)
  event.save!
  event
end
```

Cette correction a été appliquée lors de la correction de la Priorité 5 (Jobs), ce qui a également résolu cette erreur.
