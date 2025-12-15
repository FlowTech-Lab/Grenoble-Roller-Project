# Erreur #191 : Jobs EventReminderJob (9 erreurs)

**Date d'analyse** : 2025-12-15  
**Priorité** : 🟢 Priorité 5  
**Catégorie** : Tests de Jobs

---

## 📋 Informations Générales

- **Fichier test** : `spec/jobs/event_reminder_job_spec.rb`
- **Lignes** : 33, 48, 69, 79, 94, 102, 114, 130
- **Tests** : 9 tests échouent tous
- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/jobs/event_reminder_job_spec.rb
  ```

---

## 🔴 Erreurs

### Erreur 1 : Ligne 33 - `sends reminder email to active attendees with wants_reminder = true`
```
Failure/Error: expect(mail).to be_present
  expected `nil.present?` to be truthy, got false
```

### Erreur 2 : Ligne 48 - `sends reminder for events at different times tomorrow`
```
Failure/Error: expected `ActionMailer::Base.deliveries.count` to have changed by at least 3, but was changed by 1
```

### Erreur 3 : Ligne 69 - `does not send reminder for canceled attendance`
```
Failure/Error: expected `ActionMailer::Base.deliveries.count` not to have changed, but did change from 6 to 7
```

### Erreur 4 : Ligne 79 - `does not send reminder if wants_reminder is false`
```
Failure/Error: expected `ActionMailer::Base.deliveries.count` not to have changed, but did change from 6 to 7
```

### Erreur 5 : Ligne 94 - `does not send reminder for events today`
```
Failure/Error: expected `ActionMailer::Base.deliveries.count` not to have changed, but did change from 6 to 7
```

### Erreur 6 : Ligne 102 - `does not send reminder for events day after tomorrow`
```
Failure/Error: expected `ActionMailer::Base.deliveries.count` not to have changed, but did change from 6 to 7
```

### Erreur 7 : Ligne 114 - `does not send reminder for draft events`
```
Failure/Error: expected `ActionMailer::Base.deliveries.count` not to have changed, but did change from 6 to 7
```

### Erreur 8 : Ligne 130 - `sends reminder only to attendees with wants_reminder = true`
```
Failure/Error: expected `ActionMailer::Base.deliveries.count` to have changed by at least 2, but was changed by 0
```

---

## 🔍 Analyse

### Constats
- ❌ Les tests utilisent `create(:event, :published, ...)` qui peut échouer (même problème que 084)
- ❌ Les emails ne sont pas envoyés correctement (le job ne trouve pas les événements ou les attendees)
- ⚠️ Il y a déjà 6 emails dans `ActionMailer::Base.deliveries` avant les tests (pollution de données)
- ✅ Le test utilise `perform_enqueued_jobs` et `ActiveJob::TestHelper` correctement
- ✅ Le job filtre correctement avec `Event.published.upcoming.where(start_at: tomorrow_start..tomorrow_end)`

### Cause Probable

1. **Pollution de données** : Il y a déjà 6 emails dans `ActionMailer::Base.deliveries` avant les tests, ce qui fausse les compteurs
2. **Factories qui échouent** : `create(:event, ...)` peut échouer (même problème que 084)
3. **Filtrage des événements** : Le job peut ne pas trouver les événements créés dans les tests à cause de la plage de dates ou du scope `upcoming`
4. **Scope `active`** : Si le scope `active` a un problème (voir 084), cela affecte aussi le job

### Code Actuel

```ruby
# spec/jobs/event_reminder_job_spec.rb
let!(:event_tomorrow_morning) { create(:event, :published, creator_user: organizer, start_at: Time.zone.now.beginning_of_day + 1.day + 10.hours, title: 'Event Tomorrow Morning') }
let!(:attendance) { create(:attendance, user: user, event: event_tomorrow_morning, status: 'registered', wants_reminder: true) }

it 'sends reminder email to active attendees with wants_reminder = true' do
  expect do
    perform_enqueued_jobs do
      EventReminderJob.perform_now
    end
  end.to change { ActionMailer::Base.deliveries.count }.by_at_least(1)
  
  mail = ActionMailer::Base.deliveries.find { |m| m.subject.include?(event_tomorrow_morning.title) }
  expect(mail).to be_present
end

# app/jobs/event_reminder_job.rb
def perform
  tomorrow_start = Time.zone.now.beginning_of_day + 1.day
  tomorrow_end = tomorrow_start.end_of_day
  
  events = Event.published
                .upcoming
                .where(start_at: tomorrow_start..tomorrow_end)
  
  events.find_each do |event|
    event.attendances.active
         .where(wants_reminder: true)
         .includes(:user, :event)
         .find_each do |attendance|
      EventMailer.event_reminder(attendance).deliver_later
    end
  end
end
```

---

## 💡 Solutions Proposées

### Solution 1 : Nettoyer `ActionMailer::Base.deliveries` avant chaque test

**Problème** : Pollution de données (6 emails déjà présents).

**Solution** : Ajouter un `before` block pour nettoyer les emails.

```ruby
before do
  ActionMailer::Base.deliveries.clear
end
```

### Solution 2 : Utiliser les helpers au lieu des factories

**Problème** : `create(:event, ...)` peut échouer (même problème que 084).

**Solution** : Utiliser `build_event` et `create_attendance` des helpers.

```ruby
let!(:event_tomorrow_morning) do
  e = build_event(status: 'published', start_at: Time.zone.now.beginning_of_day + 1.day + 10.hours, title: 'Event Tomorrow Morning', creator_user: organizer)
  e.save!
  e
end
let!(:attendance) { create_attendance(user: user, event: event_tomorrow_morning, status: 'registered', wants_reminder: true) }
```

### Solution 3 : Vérifier le scope `upcoming` et la plage de dates

**Problème** : Le job peut ne pas trouver les événements créés.

**Solution** : Vérifier que `Event.upcoming` fonctionne correctement et que la plage de dates inclut bien les événements créés.

### Solution 4 : Vérifier le scope `active` (voir erreur 084)

**Problème** : Si le scope `active` a un problème, cela affecte le job.

**Solution** : Corriger le scope `active` dans `Attendance` (voir 084-models-attendance.md).

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** :
- Pollution de données (emails non nettoyés)
- Factories qui échouent
- Configuration ActiveJob peut être manquante

⚠️ **PROBLÈME DE LOGIQUE** :
- Scope `active` peut avoir un problème (voir erreur 084)
- Filtrage des événements peut ne pas fonctionner correctement

---

## 📊 Statut

✅ **RÉSOLU** - Tous les tests passent (8 examples, 0 failures)

---

## 🔗 Erreurs Similaires

Cette erreur est similaire aux erreurs suivantes :
- [084-models-attendance.md](084-models-attendance.md) - Même problème avec `create(:event, ...)` et scope `active`
- [039-mailers-event-mailer.md](039-mailers-event-mailer.md) - Même problème avec `create(:event, ...)`

---

## 📝 Notes

- Le test utilise déjà `ActionMailer::Base.deliveries.clear` dans un `before` block (ligne 10), mais il y a quand même 6 emails présents
- Le problème peut venir d'autres tests qui ne nettoient pas correctement
- Le job est exécuté chaque jour à 19h pour envoyer des rappels pour les événements du lendemain

---

## ✅ Actions à Effectuer

1. [x] Vérifier que `ActionMailer::Base.deliveries.clear` est appelé avant chaque test
2. [x] Remplacer `create(:event, ...)` par `create_event` (qui utilise maintenant `build_event` + `save!`)
3. [x] Remplacer `create(:attendance, ...)` par `create_attendance`
4. [x] Remplacer `create(:user, ...)` par `create_user`
5. [x] Configurer ActiveJob avec `around` block (`:test` adapter)
6. [x] Nettoyer les données avant chaque test (Attendance, Event, ActionMailer::Base.deliveries)
7. [x] Corriger les dates des événements "today" et "day after tomorrow" pour qu'ils ne soient pas dans la plage de demain
8. [x] Exécuter les tests pour vérifier qu'ils passent
9. [x] Mettre à jour le statut dans [README.md](../README.md)

## ✅ Solution Appliquée

**Modifications dans `spec/jobs/event_reminder_job_spec.rb`** :
1. Ajout d'un `around` block pour configurer ActiveJob avec `:test` adapter
2. Nettoyage des données avant chaque test (Attendance, Event, ActionMailer::Base.deliveries)
3. Remplacement de `create(:event, ...)` par `create_event(...)`
4. Remplacement de `create(:attendance, ...)` par `create_attendance(...)`
5. Remplacement de `create(:user, ...)` par `create_user(...)`
6. Correction de la date de `event_today` pour être aujourd'hui à midi au lieu de `2.hours.from_now`
7. Ajout de vérifications pour s'assurer que les événements ne sont pas dans la plage de demain

**Modification dans `spec/support/test_data_helper.rb`** :
- `create_event` utilise maintenant `build_event` + `save!` au lieu de `FactoryBot.create(:event, attrs)`
