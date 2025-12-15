# Erreur #036 : EventReminderJob Envoi de rappel

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟡 Priorité 5  
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

## 🔴 Erreur

**Erreur** : `expected ActionMailer::Base.deliveries.count to have changed by 1, but was changed by 0`

**Cause** : Le job `EventReminderJob` ne trouve pas les événements créés dans les tests ou les emails ne sont pas envoyés.

**Problèmes identifiés** :
1. Factory `:user` sans rôle (corrigé)
2. Factory `:event` sans `creator_user` (corrigé)
3. Configuration `ActionMailer::Base.perform_deliveries = false` (corrigé → `true`)
4. Configuration `ActiveJob.queue_adapter` (corrigé → `:test`)
5. **PROBLÈME RESTANT** : Les événements créés dans les tests ne sont pas trouvés par le job (requête ou timing)

---

## 🔍 Analyse

### Constats
- ⏳ Erreur non encore analysée
- 🔍 Problème probable avec les jobs d'envoi d'emails
- ⚠️ Probablement problème avec `deliver_later` ou `perform_enqueued_jobs`

---

## 💡 Solutions Proposées

⏳ **À DÉTERMINER** après analyse

Solutions possibles :
1. Utiliser `ActiveJob::TestHelper` dans le test
2. Utiliser `perform_enqueued_jobs` pour exécuter les jobs
3. Vérifier la configuration des jobs en test

---

## 🎯 Type de Problème

⚠️ **À ANALYSER** (probablement ❌ **PROBLÈME DE TEST** - configuration jobs)

---

## 📊 Statut

⏳ **EN COURS** - Corrections partielles appliquées, problème de requête restant

### Corrections appliquées
1. ✅ Factory `:user` avec rôle explicite
2. ✅ Factory `:event` avec `creator_user` explicite
3. ✅ Configuration `ActionMailer::Base.perform_deliveries = true`
4. ✅ Configuration `ActiveJob.queue_adapter = :test`

### Problème restant
- Les événements créés dans les tests ne sont pas trouvés par le job
- Possible problème de timing ou de requête SQL

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

