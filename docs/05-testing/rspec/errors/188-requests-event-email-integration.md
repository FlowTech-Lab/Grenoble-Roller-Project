# Erreur #188-190 : Requests Event Email Integration (3 erreurs)

**Date d'analyse** : 2025-12-15  
**Priorité** : 🟡 Priorité 9  
**Catégorie** : Tests de Request  
**Statut** : ✅ **RÉSOLU** (3 tests passent)

---

## 📋 Informations Générales

- **Fichier test** : `spec/requests/event_email_integration_spec.rb`
- **Lignes** : 16, 24, 44
- **Tests** : Intégration emails pour les attendances
- **Nombre de tests** : 3 (tous passent maintenant)

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/requests/event_email_integration_spec.rb
  ```

---

## 🔴 Erreurs Initiales

### Erreurs principales :
1. `create_event(:published, :upcoming, ...)` syntaxe incorrecte
2. Emails non envoyés car ActiveJob n'est pas configuré
3. `create_user` utilisé mais besoin d'inclure `TestDataHelper`

---

## 🔍 Analyse

### Constats

1. **Syntaxe incorrecte** : `create_event(:published, :upcoming, ...)` n'est pas la bonne syntaxe pour `create_event`.

2. **ActiveJob** : Les tests d'emails nécessitent que `ActiveJob::Base.queue_adapter = :test` soit configuré et que `perform_enqueued_jobs` soit utilisé.

3. **Helper manquant** : `create_user` nécessite `include TestDataHelper`.

---

## 💡 Solutions Appliquées

### Solution 1 : Correction de la syntaxe `create_event`

**Problème** : `create_event(:published, :upcoming, ...)` n'est pas la bonne syntaxe.

**Solution** : Utiliser `build_event(...)` suivi de `save!` ou `FactoryBot.create(:event, ...)`.

**Code appliqué** :
```ruby
# Avant
let!(:event) { create_event(:published, :upcoming, title: 'Sortie Roller', creator_user: create_user) }

# Après
let!(:event) do
  e = build_event(status: 'published', start_at: 1.week.from_now, title: 'Sortie Roller', creator_user: create_user)
  e.save!
  e
end
```

**Fichier modifié** : `spec/requests/event_email_integration_spec.rb`
- Lignes 17-21 : Correction de la syntaxe

### Solution 2 : Configuration ActiveJob et utilisation de `perform_enqueued_jobs`

**Problème** : Les emails ne sont pas envoyés car ActiveJob n'est pas configuré.

**Solution** : Configurer ActiveJob dans un bloc `around` et utiliser `perform_enqueued_jobs` pour exécuter les jobs.

**Code appliqué** :
```ruby
# Configurer ActiveJob pour les tests
around do |example|
  ActiveJob::Base.queue_adapter = :test
  example.run
  ActiveJob::Base.queue_adapter = :inline
end

# Dans les tests
it 'sends confirmation email when user attends event' do
  perform_enqueued_jobs do
    expect {
      post event_attendances_path(event), params: { wants_reminder: '1' }
    }.to change { Attendance.count }.by(1)
      .and change { ActionMailer::Base.deliveries.count }.by(1)
  end
  # ... vérifications de l'email
end
```

**Fichier modifié** : `spec/requests/event_email_integration_spec.rb`
- Lignes 8-13 : Configuration ActiveJob
- Lignes 28-34, 36-46, 56-64 : Utilisation de `perform_enqueued_jobs`

### Solution 3 : Ajout de `include TestDataHelper`

**Problème** : `create_user` nécessite `include TestDataHelper`.

**Solution** : Ajouter `include TestDataHelper` dans le fichier de test.

**Code appliqué** :
```ruby
require 'rails_helper'
require 'active_job/test_helper'

RSpec.describe 'Event Email Integration', type: :request do
  include ActiveJob::TestHelper
  include TestDataHelper
  # ...
end
```

**Fichier modifié** : `spec/requests/event_email_integration_spec.rb`
- Ligne 6 : Ajout de `include TestDataHelper`

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** :
- Configuration ActiveJob manquante
- Syntaxe incorrecte pour `create_event`
- Helper manquant

---

## 📊 Résultat

✅ **TOUS LES TESTS PASSENT** (3/3)

```
Event Email Integration
  POST /events/:event_id/attendances
    sends confirmation email when user attends event
    creates attendance and sends email
  DELETE /events/:event_id/attendances
    sends cancellation email when user cancels attendance

Finished in 6.12 seconds (files took 1.68 seconds to load)
3 examples, 0 failures
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

- La configuration ActiveJob est nécessaire pour tester les emails en file d'attente
- `perform_enqueued_jobs` doit être utilisé pour exécuter les jobs et envoyer les emails
- Les corrections suivent le même pattern que pour les autres tests corrigés précédemment
