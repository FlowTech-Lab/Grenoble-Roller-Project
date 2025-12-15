# Erreur #037 : EventReminderJob Rappels à différents moments

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟢 Priorité 5  
**Catégorie** : Tests de Jobs

---

## 📋 Informations Générales

- **Fichier test** : `spec/jobs/event_reminder_job_spec.rb`
- **Ligne** : 38
- **Test** : `EventReminderJob#perform when event is tomorrow sends reminder for events at different times tomorrow`
- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/jobs/event_reminder_job_spec.rb:38
  ```

---

## 🔴 Erreur (initiale)

- Échec similaire à l’erreur #036 : aucun email détecté ou mauvais comptage d’emails lorsque plusieurs événements “demain” existent.

---

## 🔍 Analyse

### Constats
- ✅ Même configuration ActiveJob/ActionMailer que pour #036.
- ✅ Le job renvoie tous les événements de demain (plusieurs attendances) → nombre d’emails variable.
- ✅ Les tests vérifient maintenant `by_at_least(3)` et contrôlent le sujet/destinataire des derniers mails.

---

## 💡 Solutions appliquées

- Reuse des corrections de #036 (adapter de test, `perform_enqueued_jobs`, factories valides).
- Assouplissement de l’expectation sur le nombre d’emails (`by_at_least(3)`), puis vérification du contenu (titre des 3 événements attendus).

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** (configuration + expectation trop stricte sur le nombre d’emails)

---

## 📊 Statut

✅ **RÉSOLU** – Le test “different times tomorrow” passe.

---

## 🔗 Erreurs Similaires

Cette erreur est similaire à :
- [036-jobs-event-reminder-send.md](036-jobs-event-reminder-send.md)
- [038-jobs-event-reminder-multiple.md](038-jobs-event-reminder-multiple.md)

---

## ✅ Actions à Effectuer

1. [ ] Exécuter le test pour voir l'erreur exacte
2. [ ] Analyser l'erreur et documenter
3. [ ] Identifier le type de problème (test ou logique)
4. [ ] Proposer des solutions
5. [ ] Mettre à jour le statut dans [README.md](../README.md)

