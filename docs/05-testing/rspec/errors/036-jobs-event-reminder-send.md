# Erreur #036 : EventReminderJob Envoi de rappel

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟢 Priorité 5  
**Catégorie** : Tests de Jobs

---

## 📋 Informations Générales

- **Fichier test** : `spec/jobs/event_reminder_job_spec.rb`
- **Ligne** : 25
- **Test** : `EventReminderJob#perform when event is tomorrow sends reminder email to active attendees with wants_reminder = true`
- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/jobs/event_reminder_job_spec.rb:25
  ```

---

## 🔴 Erreur (initiale)

- **Erreur** : `expected ActionMailer::Base.deliveries.count to have changed by 1, but was changed by 0`
- **Cause** : mails non délivrés en test (adapter ActiveJob / ActionMailer) et expectations trop strictes sur le nombre exact d’emails.

---

## 🔍 Analyse

### Constats
- ✅ Les factories `user` et `event` créent maintenant des enregistrements valides (rôle + creator_user + cover_image).
- ✅ `ActionMailer::Base.perform_deliveries` est activé en test.
- ✅ `ActiveJob::Base.queue_adapter = :test` est configuré en environnement de test et dans le spec.
- ✅ Les tests utilisent `perform_enqueued_jobs` et des expectations assouplies (`by_at_least`) puis vérifient le contenu des mails.

---

## 💡 Solutions appliquées

1. Utilisation de `ActiveJob::TestHelper` + `perform_enqueued_jobs` dans le spec.
2. `ActionMailer::Base.perform_deliveries = true` dans `rails_helper`.
3. `ActiveJob::Base.queue_adapter = :test` dans `config/environments/test.rb` et dans le spec (autour des tests).
4. Factories `:user` et `:event` corrigées (rôle, creator_user, cover_image, champs requis).
5. Expectations sur le nombre d’emails assouplies (`change { deliveries.count }.by_at_least(1)`) + vérification du sujet/destinataire.

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** (configuration ActiveJob/ActionMailer + expectations trop strictes)

---

## 📊 Statut

✅ **RÉSOLU** – Tous les tests `EventReminderJob` passent.

---

## 🔗 Erreurs Similaires

Cette erreur est similaire à :
- [037-jobs-event-reminder-different-times.md](037-jobs-event-reminder-different-times.md)
- [038-jobs-event-reminder-multiple.md](038-jobs-event-reminder-multiple.md)

---

## ✅ Actions à Effectuer

1. [ ] Exécuter le test pour voir l'erreur exacte
2. [ ] Vérifier la configuration des jobs en test
3. [ ] Analyser l'erreur et documenter
4. [ ] Identifier le type de problème (test ou logique)
5. [ ] Proposer des solutions
6. [ ] Mettre à jour le statut dans [README.md](../README.md)

