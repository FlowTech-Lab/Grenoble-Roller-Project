# Erreur #183-184 : Models EventPolicy (2 erreurs)

**Date d'analyse** : 2025-12-15  
**Priorité** : 🟡 Priorité 8  
**Catégorie** : Tests de Policies  
**Statut** : ✅ **RÉSOLU** (25 tests passent)

---

## 📋 Informations Générales

- **Fichier test** : `spec/policies/event_policy_spec.rb`
- **Lignes** : 7, 153
- **Tests** : Permissions et scopes
- **Nombre de tests** : 25 (tous passent maintenant)

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/policies/event_policy_spec.rb
  ```

---

## 🔴 Erreurs Initiales

### Erreur 1 : Ligne 7 - `allows a guest`
```
Failure/Error: let(:owner) { create(:user, :organizer) }

ActiveRecord::RecordInvalid:
  L'enregistrement est invalide
```

### Erreur 2 : Ligne 153 - `returns only published events for guests`
```
Failure/Error: expect(scope).to contain_exactly(published_event)

expected collection contained:  [#<Event id: 6262, ...>]
actual collection contained:    [#<Event id: 5, ...>, #<Event id: 6262, ...>]
the extra elements were:        [#<Event id: 5, ...>]
```

---

## 🔍 Analyse

### Constats

1. **Erreur 1** : La factory `:user` avec le trait `:organizer` échoue car il y a un conflit entre `association :role` (par défaut) et `after(:build)` qui définit le rôle dans le trait. La factory essaie de créer un rôle par défaut, puis le trait essaie de le remplacer, ce qui cause une erreur.

2. **Erreur 2** : Pollution de données dans le scope - il y a des événements supplémentaires dans la base de données provenant de données de seed ou de tests précédents.

### Solutions

- Utiliser le helper `create_user` avec le rôle approprié au lieu de `create(:user, :organizer)`
- Nettoyer les données avant les tests de scope avec `Attendance.delete_all` et `Event.delete_all`
- Utiliser `build_event` et `save!` au lieu de `create(:event)` pour éviter les problèmes avec FactoryBot

---

## 💡 Solutions Appliquées

### Solution 1 : Utilisation du helper `create_user` avec les rôles appropriés

**Problème** : `create(:user, :organizer)` échoue à cause d'un conflit dans la factory.

**Solution** : Utiliser `create_user(role: organizer_role)` avec des rôles créés explicitement.

**Code appliqué** :
```ruby
# Avant
let(:owner) { create(:user, :organizer) }

# Après
include TestDataHelper

let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }
let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
let(:owner) { create_user(role: organizer_role) }
```

**Fichier modifié** : `spec/policies/event_policy_spec.rb`
- Ligne 3 : Ajout de `include TestDataHelper`
- Lignes 7-9 : Création explicite des rôles et utilisation de `create_user`
- Toutes les occurrences de `create(:user, :organizer)` et `create(:user, :admin)` remplacées par `create_user(role: organizer_role)` et `create_user(role: admin_role)`
- Toutes les occurrences de `create(:user)` remplacées par `create_user`

### Solution 2 : Nettoyage des données pour les scopes

**Problème** : Pollution de données dans les tests de scope.

**Solution** : Ajouter un `before` block pour nettoyer les données avant les tests de scope.

**Code appliqué** :
```ruby
describe 'Scope' do
  before do
    Attendance.delete_all
    Event.delete_all
  end

  let!(:published_event) { ... }
  # ...
end
```

**Fichier modifié** : `spec/policies/event_policy_spec.rb`
- Lignes 149-152 : Ajout d'un `before` block avec nettoyage des données

### Solution 3 : Utilisation de `build_event` au lieu de `create(:event)`

**Problème** : `create(:event)` peut avoir des problèmes avec FactoryBot.

**Solution** : Utiliser `build_event` et `save!` au lieu de `create(:event)`.

**Code appliqué** :
```ruby
# Avant
event = create(:event, :published, max_participants: 10)

# Après
event = build_event(status: 'published', max_participants: 10)
event.save!
```

**Fichier modifié** : `spec/policies/event_policy_spec.rb`
- Toutes les occurrences de `create(:event, ...)` remplacées par `build_event(...)` suivi de `save!`

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** :
- Conflit dans la factory `:user` avec le trait `:organizer`
- Pollution de données dans les tests de scope
- Problèmes avec FactoryBot pour créer des événements

---

## 📊 Résultat

✅ **TOUS LES TESTS PASSENT** (25/25)

```
EventPolicy
  #show?
    when event is published
      allows a guest
    when event is draft
      denies a guest
      allows the organizer-owner
  #create?
    allows an organizer
    denies a regular member
  #update?
    allows the organizer-owner
    denies an organizer who is not the owner
    allows an admin
  #destroy?
    allows the owner
    allows an admin
    denies a regular member
  #attend?
    allows any signed-in user when event has available spots
    allows any signed-in user when event is unlimited
    denies when event is full
    denies guests
  #can_attend?
    returns true when user can attend and is not already registered
    returns false when user is already registered
    returns false when event is full
  #user_has_attendance?
    returns true when user has an attendance
    returns false when user does not have an attendance
    returns false when user is nil
  Scope
    returns only published events for guests
    returns published + own events for a member
    returns published + own events for organizer
    returns all events for admin

Finished in 24.84 seconds (files took 1.61 seconds to load)
25 examples, 0 failures
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

- Les corrections suivent le même pattern que pour les autres tests corrigés précédemment
- L'utilisation du helper `create_user` garantit que tous les attributs requis pour `User` sont fournis
- Le nettoyage des données avant les tests de scope garantit l'isolation des tests
- L'utilisation de `build_event` et `save!` évite les problèmes potentiels avec FactoryBot
