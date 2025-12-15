# Erreur #039 : Mailers EventMailer (7 erreurs)

**Date d'analyse** : 2025-12-15  
**Priorité** : 🟢 Priorité 6  
**Catégorie** : Tests de Mailers

---

## 📋 Informations Générales

- **Fichier test** : `spec/mailers/event_mailer_spec.rb`
- **Lignes** : 86, 90, 95, 103, 107, 114, 128
- **Tests** : `attendance_cancelled` (6 erreurs) et `event_reminder` (1 erreur)
- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/mailers/event_mailer_spec.rb
  ```

---

## 🔴 Erreurs

### Toutes les erreurs (7) :
```
Failure/Error: let(:event) { create(:event, :published, :upcoming, title: 'Sortie Roller', location_text: 'Parc Paul Mistral', creator_user: organizer) }

NameError:
  undefined local variable or method 'organizer' for #<RSpec::ExampleGroups::EventMailer::AttendanceCancelled:0x...>
```

---

## 🔍 Analyse

### Constats
- ❌ La variable `organizer` n'est pas définie dans le contexte `describe '#attendance_cancelled'` et `describe '#event_reminder'`
- ✅ La variable `organizer` est définie dans le contexte parent `describe 'EventMailer'` mais pas accessible dans les sous-contextes
- ✅ Les tests utilisent `create(:event, ...)` qui peut aussi échouer (même problème que 084)
- ✅ Les templates semblent corrects d'après le code lu

### Cause Probable

La variable `organizer` est définie avec `let!(:organizer)` dans le contexte parent mais n'est pas accessible dans les sous-contextes `describe '#attendance_cancelled'` et `describe '#event_reminder'`. Il faut soit définir `organizer` dans chaque sous-contexte, soit utiliser `let!` au niveau du contexte parent pour qu'il soit accessible partout.

### Code Actuel

```ruby
# spec/mailers/event_mailer_spec.rb
RSpec.describe EventMailer, type: :mailer do
  let!(:user_role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let!(:organizer_role) { ensure_role(code: 'ORGANIZER', name: 'Organisateur', level: 40) }
  
  describe '#attendance_confirmed' do
    let(:user) { create(:user, first_name: 'John', email: 'john@example.com', role: user_role) }
    let(:organizer) { create(:user, role: organizer_role) }
    let(:event) { create(:event, :published, :upcoming, title: 'Sortie Roller', location_text: 'Parc Paul Mistral', creator_user: organizer) }
    # ... tests passent
  end

  describe '#attendance_cancelled' do
    let(:user) { create(:user, first_name: 'Jane', email: 'jane@example.com', role: user_role) }
    let(:event) { create(:event, :published, :upcoming, title: 'Sortie Roller', location_text: 'Parc Paul Mistral', creator_user: organizer) }
    # ❌ organizer n'est pas défini ici
  end

  describe '#event_reminder' do
    let(:user) { create(:user, first_name: 'Bob', email: 'bob@example.com', role: user_role) }
    let(:event) { create(:event, :published, :upcoming, title: 'Sortie Roller', location_text: 'Parc Paul Mistral', creator_user: organizer) }
    # ❌ organizer n'est pas défini ici
  end
end
```

---

## 💡 Solutions Proposées

### Solution 1 : Définir `organizer` dans chaque sous-contexte

**Problème** : `organizer` n'est pas défini dans `#attendance_cancelled` et `#event_reminder`.

**Solution** : Ajouter `let(:organizer)` dans chaque sous-contexte.

```ruby
describe '#attendance_cancelled' do
  let(:user) { create(:user, first_name: 'Jane', email: 'jane@example.com', role: user_role) }
  let(:organizer) { create(:user, role: organizer_role) }
  let(:event) { create(:event, :published, :upcoming, title: 'Sortie Roller', location_text: 'Parc Paul Mistral', creator_user: organizer) }
  # ...
end

describe '#event_reminder' do
  let(:user) { create(:user, first_name: 'Bob', email: 'bob@example.com', role: user_role) }
  let(:organizer) { create(:user, role: organizer_role) }
  let(:event) { create(:event, :published, :upcoming, title: 'Sortie Roller', location_text: 'Parc Paul Mistral', creator_user: organizer) }
  # ...
end
```

### Solution 2 : Définir `organizer` au niveau du contexte parent

**Problème** : `organizer` n'est pas accessible dans les sous-contextes.

**Solution** : Définir `organizer` avec `let!` au niveau du contexte parent pour qu'il soit accessible partout.

```ruby
RSpec.describe EventMailer, type: :mailer do
  let!(:user_role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let!(:organizer_role) { ensure_role(code: 'ORGANIZER', name: 'Organisateur', level: 40) }
  let!(:organizer) { create(:user, role: organizer_role) }
  
  # Maintenant organizer est accessible dans tous les sous-contextes
end
```

### Solution 3 : Utiliser les helpers au lieu des factories

**Problème** : `create(:event, ...)` peut échouer (même problème que 084).

**Solution** : Utiliser `build_event` et `create_user` des helpers.

```ruby
let(:organizer) { create_user(role: organizer_role) }
let(:event) do
  e = build_event(status: 'published', title: 'Sortie Roller', location_text: 'Parc Paul Mistral', creator_user: organizer, start_at: 3.days.from_now)
  e.save!
  e
end
```

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** :
- Variable `organizer` non définie dans les sous-contextes
- Factories qui peuvent échouer (même problème que 084)

---

## 📊 Statut

✅ **RÉSOLU** - Tous les tests passent (19 examples, 0 failures)

---

## 🔗 Erreurs Similaires

Cette erreur est similaire aux erreurs suivantes :
- [084-models-attendance.md](084-models-attendance.md) - Même problème avec `create(:event, ...)`
- [191-jobs-event-reminder-job.md](191-jobs-event-reminder-job.md) - Même problème avec `create(:event, ...)`

---

## 📝 Notes

- Le contexte `#attendance_confirmed` définit déjà `organizer` et fonctionne correctement
- Il faut simplement ajouter la même définition dans les autres contextes
- Les templates semblent corrects d'après le code lu

---

## ✅ Actions à Effectuer

1. [x] Ajouter `let(:organizer)` dans `describe '#attendance_cancelled'`
2. [x] Ajouter `let(:organizer)` dans `describe '#event_reminder'`
3. [x] Remplacer `create(:event, ...)` par `create_event(...)`
4. [x] Remplacer `create(:user, ...)` par `create_user(...)`
5. [x] Remplacer `create(:attendance, ...)` par `create_attendance(...)`
6. [x] Exécuter les tests pour vérifier qu'ils passent
7. [x] Mettre à jour le statut dans [README.md](../README.md)

## ✅ Solution Appliquée

**Modifications dans `spec/mailers/event_mailer_spec.rb`** :
1. Ajout de `let(:organizer)` dans `describe '#attendance_cancelled'`
2. Ajout de `let(:organizer)` dans `describe '#event_reminder'`
3. Remplacement de `create(:event, ...)` par `create_event(...)`
4. Remplacement de `create(:user, ...)` par `create_user(...)`
5. Remplacement de `create(:attendance, ...)` par `create_attendance(...)`
