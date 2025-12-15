# Erreur #038 : EventReminderJob Rappels multiples

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟢 Priorité 5  
**Catégorie** : Tests de Jobs

---

## 📋 Informations Générales

- **Fichier test** : `spec/jobs/event_reminder_job_spec.rb`
- **Ligne** : 110
- **Test** : `EventReminderJob#perform with multiple attendees sends reminder only to attendees with wants_reminder = true`
- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/jobs/event_reminder_job_spec.rb:110
  ```

---

## 🔴 Erreur (initiale)

- Contexte avec plusieurs participants : le test ne détectait pas correctement les emails envoyés uniquement aux utilisateurs avec `wants_reminder = true`.

---

## 🔍 Analyse

### Constats
- ✅ Même configuration ActiveJob/ActionMailer que pour #036/#037.
- ✅ Les attendances sont bien créées avec/ sans `wants_reminder`.
- ✅ Le test vérifie maintenant les destinataires des emails filtrés par sujet (`event_tomorrow_morning.title`) et adresse email.

---

## 💡 Solutions appliquées

1. Reuse de la configuration ActiveJob/ActionMailer de #036.
2. Expectation assouplie sur le nombre d’emails (`by_at_least(2)`).
3. Sélection explicite des emails pour l’événement concerné, puis vérification que seuls `user` et `user2` sont présents (et pas `user3`).

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** (configuration + filtrage des destinataires dans le test)

---

## 📊 Statut

✅ **RÉSOLU** – Le test “multiple attendees” passe.

---

## 🔗 Erreurs Similaires

Cette erreur est similaire à :
- [036-jobs-event-reminder-send.md](036-jobs-event-reminder-send.md)
- [037-jobs-event-reminder-different-times.md](037-jobs-event-reminder-different-times.md)

---

## ✅ Actions à Effectuer

1. [ ] Exécuter le test pour voir l'erreur exacte
2. [ ] Analyser l'erreur et documenter
3. [ ] Identifier le type de problème (test ou logique)
4. [ ] Proposer des solutions
5. [ ] Mettre à jour le statut dans [README.md](../README.md)

