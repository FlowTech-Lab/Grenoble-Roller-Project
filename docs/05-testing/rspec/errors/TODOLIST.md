# Todolist Détaillée - Correction des 89 Erreurs RSpec

**Date de création** : 2025-01-17  
**Statut initial** : 472 examples, 89 failures, 15 pending  
**Objectif** : Réduire à moins de 20 erreurs

---

## 📋 Légende

- ⏳ **Pending** : À faire
- 🔄 **In Progress** : En cours
- ✅ **Completed** : Terminé
- ❌ **Cancelled** : Annulé

---

## 🔴 Phase 1 : Tests de Modèles Attendance (12 erreurs)

### 1.1 Analyse et Préparation
- [ ] **Phase 1.1** - Analyser les 12 erreurs de `spec/models/attendance_spec.rb` et créer les fichiers d'erreur individuels
  - [ ] Exécuter tous les tests du fichier pour voir les erreurs complètes
  - [ ] Créer un fichier d'erreur pour chaque groupe de tests similaires
  - [ ] Documenter les causes probables dans chaque fichier

### 1.2 Tests de Validation de Base
- [ ] **Phase 1.2** - Corriger `is valid with default attributes`
  - [ ] Exécuter : `rspec ./spec/models/attendance_spec.rb:8`
  - [ ] Vérifier que les attributs par défaut sont valides avec la nouvelle logique
  - [ ] Adapter le test si nécessaire (créer adhésion active ou essai gratuit)
  - [ ] Vérifier que le test passe

- [ ] **Phase 1.3** - Corriger `enforces uniqueness of user scoped to event`
  - [ ] Exécuter : `rspec ./spec/models/attendance_spec.rb:19`
  - [ ] Vérifier l'unicité avec `child_membership_id` (parent et enfants peuvent être inscrits séparément)
  - [ ] Adapter le test pour prendre en compte `child_membership_id` dans l'unicité
  - [ ] Vérifier que le test passe

### 1.3 Tests d'Associations
- [ ] **Phase 1.4** - Corriger `accepts an optional payment`
  - [ ] Exécuter : `rspec ./spec/models/attendance_spec.rb:29`
  - [ ] Vérifier que le paiement optionnel fonctionne
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 1.5** - Corriger `counter cache increments event.attendances_count`
  - [ ] Exécuter : `rspec ./spec/models/attendance_spec.rb:39`
  - [ ] Vérifier l'incrémentation du compteur
  - [ ] S'assurer que les enfants comptent aussi dans le compteur
  - [ ] Vérifier que le test passe

- [ ] **Phase 1.6** - Corriger `counter cache decrements event.attendances_count`
  - [ ] Exécuter : `rspec ./spec/models/attendance_spec.rb:48`
  - [ ] Vérifier la décrémentation du compteur
  - [ ] S'assurer que les enfants sont bien décrémentés
  - [ ] Vérifier que le test passe

### 1.4 Tests de Validation de Capacité
- [ ] **Phase 1.7** - Corriger `max_participants validation allows attendance when event has available spots`
  - [ ] Exécuter : `rspec ./spec/models/attendance_spec.rb:70`
  - [ ] Adapter à la nouvelle logique d'adhésion (créer adhésion active ou essai gratuit)
  - [ ] Vérifier que le test passe

- [ ] **Phase 1.8** - Corriger `max_participants validation allows attendance when event is unlimited`
  - [ ] Exécuter : `rspec ./spec/models/attendance_spec.rb:75`
  - [ ] Vérifier les événements illimités (max_participants = 0)
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 1.9** - Corriger `max_participants validation prevents attendance when event is full`
  - [ ] Exécuter : `rspec ./spec/models/attendance_spec.rb:81`
  - [ ] Vérifier le blocage quand complet
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 1.10** - Corriger `max_participants validation does not count canceled attendances`
  - [ ] Exécuter : `rspec ./spec/models/attendance_spec.rb:93`
  - [ ] Vérifier l'exclusion des annulés du calcul de capacité
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

### 1.5 Tests de Scopes
- [ ] **Phase 1.11** - Corriger les 4 tests de scopes
  - [ ] Exécuter : `rspec ./spec/models/attendance_spec.rb:111` (active scope)
  - [ ] Exécuter : `rspec ./spec/models/attendance_spec.rb:118` (canceled scope)
  - [ ] Exécuter : `rspec ./spec/models/attendance_spec.rb:126` (volunteers scope)
  - [ ] Exécuter : `rspec ./spec/models/attendance_spec.rb:136` (participants scope)
  - [ ] Vérifier tous les scopes fonctionnent correctement
  - [ ] Adapter les tests si nécessaire
  - [ ] Vérifier que tous les tests passent

### 1.6 Tests de Nouvelle Logique
- [ ] **Phase 1.12** - Ajouter/Mettre à jour les tests de `can_register_to_event`
  - [ ] Vérifier que les tests existants pour `can_register_to_event` sont à jour
  - [ ] Ajouter des tests pour événements normaux avec enfants ayant différents statuts :
    - [ ] Enfant avec adhésion active
    - [ ] Enfant avec adhésion expired
    - [ ] Enfant avec adhésion trial
    - [ ] Enfant avec adhésion pending
  - [ ] Vérifier que tous les tests passent

---

## 🔴 Phase 2 : Tests de Features (19 erreurs)

### 2.1 Event Attendance Features (4 erreurs)
- [ ] **Phase 2.1** - Analyser les 4 erreurs de `spec/features/event_attendance_spec.rb`
  - [ ] Exécuter tous les tests du fichier
  - [ ] Créer des fichiers d'erreur pour chaque test

- [ ] **Phase 2.2** - Corriger `affiche le bouton Se désinscrire après inscription`
  - [ ] Exécuter : `rspec ./spec/features/event_attendance_spec.rb:85`
  - [ ] Adapter au nouveau comportement (créer adhésion active ou essai gratuit)
  - [ ] Vérifier que le bouton s'affiche correctement
  - [ ] Vérifier que le test passe

- [ ] **Phase 2.3** - Corriger `affiche le badge Complet et désactive le bouton S'inscrire`
  - [ ] Exécuter : `rspec ./spec/features/event_attendance_spec.rb:132`
  - [ ] Vérifier l'affichage du badge "Complet"
  - [ ] Vérifier que le bouton est désactivé
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 2.4** - Corriger `n'affiche pas le bouton S'inscrire sur la liste des événements`
  - [ ] Exécuter : `rspec ./spec/features/event_attendance_spec.rb:141`
  - [ ] Vérifier la liste des événements
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 2.5** - Corriger les 2 tests d'affichage des places restantes
  - [ ] Exécuter : `rspec ./spec/features/event_attendance_spec.rb:184` (places disponibles)
  - [ ] Exécuter : `rspec ./spec/features/event_attendance_spec.rb:199` (presque plein)
  - [ ] Vérifier le calcul et l'affichage des places
  - [ ] Adapter les tests si nécessaire
  - [ ] Vérifier que les tests passent

### 2.2 Initiation Registration Features (6 erreurs)
- [ ] **Phase 2.6** - Analyser les 6 erreurs de `spec/features/initiation_registration_spec.rb`
  - [ ] Exécuter tous les tests du fichier
  - [ ] Créer des fichiers d'erreur pour chaque test

- [ ] **Phase 2.7** - Corriger `prevents user from registering twice`
  - [ ] Exécuter : `rspec ./spec/features/initiation_registration_spec.rb:17`
  - [ ] Vérifier la prévention des doublons
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 2.8** - Corriger `allows user without membership to register using free trial`
  - [ ] Exécuter : `rspec ./spec/features/initiation_registration_spec.rb:44`
  - [ ] Vérifier l'essai gratuit
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 2.9** - Corriger `prevents user from using free trial twice`
  - [ ] Exécuter : `rspec ./spec/features/initiation_registration_spec.rb:68`
  - [ ] Vérifier la limitation de l'essai gratuit
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 2.10** - Corriger `prevents registration when initiation is full`
  - [ ] Exécuter : `rspec ./spec/features/initiation_registration_spec.rb:98`
  - [ ] Vérifier le blocage quand complet
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 2.11** - Corriger `allows volunteers to register even when initiation is full`
  - [ ] Exécuter : `rspec ./spec/features/initiation_registration_spec.rb:129`
  - [ ] Vérifier les bénévoles peuvent s'inscrire même si complet
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 2.12** - Corriger `generates unique UID for each initiation ICS export`
  - [ ] Exécuter : `rspec ./spec/features/initiation_registration_spec.rb:262`
  - [ ] Vérifier l'export ICS
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 2.13** - Corriger `allows parent to register child using child membership`
  - [ ] Exécuter : `rspec ./spec/features/initiation_registration_spec.rb:297`
  - [ ] Adapter à la nouvelle logique (active, trial, pending pour initiations)
  - [ ] Vérifier que le test passe

### 2.3 Mes Sorties Features (6 erreurs)
- [ ] **Phase 2.14** - Analyser les 6 erreurs de `spec/features/mes_sorties_spec.rb`
  - [ ] Exécuter tous les tests du fichier
  - [ ] Créer des fichiers d'erreur pour chaque test

- [ ] **Phase 2.15** - Corriger `affiche la page Mes sorties avec les événements inscrits`
  - [ ] Exécuter : `rspec ./spec/features/mes_sorties_spec.rb:28`
  - [ ] Vérifier l'affichage de base
  - [ ] Adapter le test si nécessaire (créer adhésion active ou essai gratuit)
  - [ ] Vérifier que le test passe

- [ ] **Phase 2.16** - Corriger `affiche les informations de l'événement`
  - [ ] Exécuter : `rspec ./spec/features/mes_sorties_spec.rb:71`
  - [ ] Vérifier les détails affichés (date, lieu, nombre d'inscrits)
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 2.17** - Corriger `n'affiche que les événements où l'utilisateur est inscrit`
  - [ ] Exécuter : `rspec ./spec/features/mes_sorties_spec.rb:83`
  - [ ] Vérifier le filtrage
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 2.18** - Corriger `n'affiche pas les inscriptions annulées`
  - [ ] Exécuter : `rspec ./spec/features/mes_sorties_spec.rb:94`
  - [ ] Vérifier l'exclusion des annulés
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 2.19** - Corriger `permet de cliquer sur un événement pour voir les détails`
  - [ ] Exécuter : `rspec ./spec/features/mes_sorties_spec.rb:119`
  - [ ] Vérifier la navigation
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 2.20** - Corriger `permet de retourner à la liste des événements`
  - [ ] Exécuter : `rspec ./spec/features/mes_sorties_spec.rb:136`
  - [ ] Vérifier le retour
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

---

## 🟠 Phase 3 : Tests de Jobs (8 erreurs)

### 3.1 Event Reminder Job
- [ ] **Phase 3.1** - Analyser les 8 erreurs de `spec/jobs/event_reminder_job_spec.rb`
  - [ ] Exécuter tous les tests du fichier
  - [ ] Créer des fichiers d'erreur pour chaque test

- [ ] **Phase 3.2** - Corriger `sends reminder email to active attendees with wants_reminder = true`
  - [ ] Exécuter : `rspec ./spec/jobs/event_reminder_job_spec.rb:43`
  - [ ] Vérifier l'envoi de base
  - [ ] Adapter le test si nécessaire (créer adhésion active ou essai gratuit)
  - [ ] Vérifier que le test passe

- [ ] **Phase 3.3** - Corriger `sends reminder for events at different times tomorrow`
  - [ ] Exécuter : `rspec ./spec/jobs/event_reminder_job_spec.rb:80`
  - [ ] Vérifier les différents horaires
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 3.4** - Corriger `does not send reminder for canceled attendance`
  - [ ] Exécuter : `rspec ./spec/jobs/event_reminder_job_spec.rb:101`
  - [ ] Vérifier l'exclusion des annulés
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 3.5** - Corriger `does not send reminder if wants_reminder is false`
  - [ ] Exécuter : `rspec ./spec/jobs/event_reminder_job_spec.rb:111`
  - [ ] Vérifier le respect de `wants_reminder`
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 3.6** - Corriger `does not send reminder for events today`
  - [ ] Exécuter : `rspec ./spec/jobs/event_reminder_job_spec.rb:126`
  - [ ] Vérifier le filtrage par date
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 3.7** - Corriger `does not send reminder for events day after tomorrow`
  - [ ] Exécuter : `rspec ./spec/jobs/event_reminder_job_spec.rb:139`
  - [ ] Vérifier le filtrage par date
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 3.8** - Corriger `does not send reminder for draft events`
  - [ ] Exécuter : `rspec ./spec/jobs/event_reminder_job_spec.rb:156`
  - [ ] Vérifier l'exclusion des brouillons
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 3.9** - Corriger `sends reminder only to attendees with wants_reminder = true`
  - [ ] Exécuter : `rspec ./spec/jobs/event_reminder_job_spec.rb:172`
  - [ ] Vérifier le filtrage multiple
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

---

## 🟠 Phase 4 : Tests de Mailers (13 erreurs)

### 4.1 Event Mailer
- [ ] **Phase 4.1** - Analyser les 13 erreurs de `spec/mailers/event_mailer_spec.rb`
  - [ ] Exécuter tous les tests du fichier
  - [ ] Créer des fichiers d'erreur pour chaque test

- [ ] **Phase 4.2** - Corriger `sends to user email` (attendance_confirmed)
  - [ ] Exécuter : `rspec ./spec/mailers/event_mailer_spec.rb:14`
  - [ ] Vérifier l'envoi de base
  - [ ] Adapter le test si nécessaire (créer adhésion active ou essai gratuit)
  - [ ] Vérifier que le test passe

- [ ] **Phase 4.3** - Corriger `includes event title in subject` (attendance_confirmed)
  - [ ] Exécuter : `rspec ./spec/mailers/event_mailer_spec.rb:18`
  - [ ] Vérifier le sujet
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 4.4** - Corriger `includes event details in body` (attendance_confirmed)
  - [ ] Exécuter : `rspec ./spec/mailers/event_mailer_spec.rb:23`
  - [ ] Vérifier le contenu
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 4.5** - Corriger `includes user first name in body` (attendance_confirmed)
  - [ ] Exécuter : `rspec ./spec/mailers/event_mailer_spec.rb:28`
  - [ ] Vérifier la personnalisation
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 4.6** - Corriger `includes event date in body` (attendance_confirmed)
  - [ ] Exécuter : `rspec ./spec/mailers/event_mailer_spec.rb:32`
  - [ ] Vérifier la date
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 4.7** - Corriger `includes event URL in body` (attendance_confirmed)
  - [ ] Exécuter : `rspec ./spec/mailers/event_mailer_spec.rb:39`
  - [ ] Vérifier l'URL
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 4.8** - Corriger `includes route name in body` (attendance_confirmed)
  - [ ] Exécuter : `rspec ./spec/mailers/event_mailer_spec.rb:52`
  - [ ] Vérifier le nom de route
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 4.9** - Corriger `includes price in body` (attendance_confirmed)
  - [ ] Exécuter : `rspec ./spec/mailers/event_mailer_spec.rb:62`
  - [ ] Vérifier le prix
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 4.10** - Corriger `includes participants count in body` (attendance_confirmed)
  - [ ] Exécuter : `rspec ./spec/mailers/event_mailer_spec.rb:74`
  - [ ] Vérifier le compteur
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 4.11** - Corriger `sends to user email` (event_reminder)
  - [ ] Exécuter : `rspec ./spec/mailers/event_mailer_spec.rb:133`
  - [ ] Vérifier l'envoi de rappel
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 4.12** - Corriger `includes event title in subject` (event_reminder)
  - [ ] Exécuter : `rspec ./spec/mailers/event_mailer_spec.rb:137`
  - [ ] Vérifier le sujet du rappel
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 4.13** - Corriger `includes event details in body` (event_reminder)
  - [ ] Exécuter : `rspec ./spec/mailers/event_mailer_spec.rb:142`
  - [ ] Vérifier le contenu du rappel
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 4.14** - Corriger `includes user first name in body` (event_reminder)
  - [ ] Exécuter : `rspec ./spec/mailers/event_mailer_spec.rb:147`
  - [ ] Vérifier la personnalisation du rappel
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

---

## 🟡 Phase 5 : Tests de Modèles Event (7 erreurs)

### 5.1 Event Model
- [ ] **Phase 5.1** - Analyser les 7 erreurs de `spec/models/event_spec.rb`
  - [ ] Exécuter tous les tests du fichier
  - [ ] Créer des fichiers d'erreur pour chaque test

- [ ] **Phase 5.2** - Corriger `returns false when not at capacity` (full?)
  - [ ] Exécuter : `rspec ./spec/models/event_spec.rb:99`
  - [ ] Vérifier la logique de capacité
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 5.3** - Corriger `returns true when at capacity` (full?)
  - [ ] Exécuter : `rspec ./spec/models/event_spec.rb:105`
  - [ ] Vérifier quand complet
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 5.4** - Corriger `does not count canceled attendances` (full?)
  - [ ] Exécuter : `rspec ./spec/models/event_spec.rb:113`
  - [ ] Vérifier l'exclusion des annulés
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 5.5** - Corriger `returns correct number of remaining spots`
  - [ ] Exécuter : `rspec ./spec/models/event_spec.rb:134`
  - [ ] Vérifier le calcul des places
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 5.6** - Corriger `returns 0 when full` (remaining_spots)
  - [ ] Exécuter : `rspec ./spec/models/event_spec.rb:141`
  - [ ] Vérifier quand complet
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 5.7** - Corriger `does not count canceled attendances` (remaining_spots)
  - [ ] Exécuter : `rspec ./spec/models/event_spec.rb:149`
  - [ ] Vérifier l'exclusion
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 5.8** - Corriger les 2 tests de `has_available_spots?`
  - [ ] Exécuter : `rspec ./spec/models/event_spec.rb:164` (returns true)
  - [ ] Exécuter : `rspec ./spec/models/event_spec.rb:171` (returns false)
  - [ ] Vérifier la disponibilité
  - [ ] Adapter les tests si nécessaire
  - [ ] Vérifier que les tests passent

---

## 🟡 Phase 6 : Tests de Policies (4 erreurs)

### 6.1 Event Policy
- [ ] **Phase 6.1** - Analyser les 4 erreurs de `spec/policies/event_policy_spec.rb`
  - [ ] Exécuter tous les tests du fichier
  - [ ] Créer des fichiers d'erreur pour chaque test

- [ ] **Phase 6.2** - Corriger `denies when event is full` (attend?)
  - [ ] Exécuter : `rspec ./spec/policies/event_policy_spec.rb:104`
  - [ ] Adapter à la nouvelle logique d'adhésion (créer adhésion active ou essai gratuit)
  - [ ] Vérifier que le test passe

- [ ] **Phase 6.3** - Corriger `returns false when user is already registered` (can_attend?)
  - [ ] Exécuter : `rspec ./spec/policies/event_policy_spec.rb:132`
  - [ ] Vérifier les doublons
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 6.4** - Corriger `returns false when event is full` (can_attend?)
  - [ ] Exécuter : `rspec ./spec/policies/event_policy_spec.rb:138`
  - [ ] Vérifier quand complet
  - [ ] Adapter le test si nécessaire (créer adhésion active ou essai gratuit)
  - [ ] Vérifier que le test passe

- [ ] **Phase 6.5** - Corriger `returns true when user has an attendance` (user_has_attendance?)
  - [ ] Exécuter : `rspec ./spec/policies/event_policy_spec.rb:155`
  - [ ] Vérifier la détection
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

---

## 🟡 Phase 7 : Tests de Requests (20 erreurs)

### 7.1 Event Requests (5 erreurs)
- [ ] **Phase 7.1** - Analyser les 5 erreurs de `spec/requests/events_spec.rb`
  - [ ] Exécuter tous les tests du fichier
  - [ ] Créer des fichiers d'erreur pour chaque test

- [ ] **Phase 7.2** - Corriger `registers the current user`
  - [ ] Exécuter : `rspec ./spec/requests/events_spec.rb:103`
  - [ ] Adapter à la nouvelle logique d'adhésion (créer adhésion active ou essai gratuit)
  - [ ] Vérifier que le test passe

- [ ] **Phase 7.3** - Corriger `blocks unconfirmed users from attending`
  - [ ] Exécuter : `rspec ./spec/requests/events_spec.rb:118`
  - [ ] Vérifier le blocage des non confirmés
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 7.4** - Corriger `does not duplicate an existing attendance`
  - [ ] Exécuter : `rspec ./spec/requests/events_spec.rb:138`
  - [ ] Vérifier la prévention des doublons
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 7.5** - Corriger `removes the attendance for the current user`
  - [ ] Exécuter : `rspec ./spec/requests/events_spec.rb:165`
  - [ ] Vérifier la suppression
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

### 7.2 Event Email Integration (3 erreurs)
- [ ] **Phase 7.6** - Analyser les 3 erreurs de `spec/requests/event_email_integration_spec.rb`
  - [ ] Exécuter tous les tests du fichier
  - [ ] Créer des fichiers d'erreur pour chaque test

- [ ] **Phase 7.7** - Corriger `sends confirmation email when user attends event`
  - [ ] Exécuter : `rspec ./spec/requests/event_email_integration_spec.rb:28`
  - [ ] Vérifier l'envoi
  - [ ] Adapter le test si nécessaire (créer adhésion active ou essai gratuit)
  - [ ] Vérifier que le test passe

- [ ] **Phase 7.8** - Corriger `creates attendance and sends email`
  - [ ] Exécuter : `rspec ./spec/requests/event_email_integration_spec.rb:42`
  - [ ] Vérifier la création et l'envoi
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 7.9** - Corriger `sends cancellation email when user cancels attendance`
  - [ ] Exécuter : `rspec ./spec/requests/event_email_integration_spec.rb:64`
  - [ ] Vérifier l'envoi d'annulation
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

### 7.3 Initiation Registration Requests (12 erreurs)
- [ ] **Phase 7.10** - Analyser les 12 erreurs de `spec/requests/initiation_registration_spec.rb`
  - [ ] Exécuter tous les tests du fichier
  - [ ] Créer des fichiers d'erreur pour chaque test

- [ ] **Phase 7.11** - Corriger `allows parent to register child using child membership` (2 tests)
  - [ ] Exécuter : `rspec ./spec/requests/initiation_registration_spec.rb:312`
  - [ ] Exécuter : `rspec ./spec/requests/initiation_registration_spec.rb:297` (feature)
  - [ ] Adapter à la nouvelle logique (active, trial, pending pour initiations)
  - [ ] Vérifier que les tests passent

- [ ] **Phase 7.12** - Corriger `permet inscription adulte puis enfant`
  - [ ] Exécuter : `rspec ./spec/requests/initiation_registration_spec.rb:370`
  - [ ] Vérifier l'ordre d'inscription
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 7.13** - Corriger `permet inscription enfant puis adulte`
  - [ ] Exécuter : `rspec ./spec/requests/initiation_registration_spec.rb:411`
  - [ ] Vérifier l'ordre inverse
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 7.14** - Corriger `permet inscription plusieurs enfants`
  - [ ] Exécuter : `rspec ./spec/requests/initiation_registration_spec.rb:448`
  - [ ] Vérifier les inscriptions multiples
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 7.15** - Corriger `permet inscription adulte + plusieurs enfants`
  - [ ] Exécuter : `rspec ./spec/requests/initiation_registration_spec.rb:477`
  - [ ] Vérifier les inscriptions combinées
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 7.16** - Corriger `permet inscription adulte avec essai gratuit puis enfant avec adhésion`
  - [ ] Exécuter : `rspec ./spec/requests/initiation_registration_spec.rb:513`
  - [ ] Vérifier l'essai gratuit parent
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 7.17** - Corriger `permet inscription enfant avec adhésion puis adulte (sans essai gratuit car parent considéré membre)`
  - [ ] Exécuter : `rspec ./spec/requests/initiation_registration_spec.rb:553`
  - [ ] Vérifier la logique membre
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 7.18** - Corriger `empêche inscription double du même enfant`
  - [ ] Exécuter : `rspec ./spec/requests/initiation_registration_spec.rb:641`
  - [ ] Vérifier la prévention des doublons
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 7.19** - Corriger `permet inscription adulte même si enfant déjà inscrit`
  - [ ] Exécuter : `rspec ./spec/requests/initiation_registration_spec.rb:667`
  - [ ] Vérifier l'indépendance
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 7.20** - Corriger `permet inscription enfant même si adulte déjà inscrit`
  - [ ] Exécuter : `rspec ./spec/requests/initiation_registration_spec.rb:692`
  - [ ] Vérifier l'indépendance inverse
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 7.21** - Corriger `famille remplit initiation`
  - [ ] Exécuter : `rspec ./spec/requests/initiation_registration_spec.rb:717`
  - [ ] Vérifier la capacité maximale
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 7.22** - Corriger `Volontaires enfant CANNOT être volontaire`
  - [ ] Exécuter : `rspec ./spec/requests/initiation_registration_spec.rb:779`
  - [ ] Vérifier la restriction des bénévoles
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 7.23** - Corriger les 4 tests de `famille non-adhérente avec découverte`
  - [ ] Exécuter : `rspec ./spec/requests/initiation_registration_spec.rb:911` (peut s'inscrire)
  - [ ] Exécuter : `rspec ./spec/requests/initiation_registration_spec.rb:941` (mélange)
  - [ ] Exécuter : `rspec ./spec/requests/initiation_registration_spec.rb:974` (famille + volontaires)
  - [ ] Exécuter : `rspec ./spec/requests/initiation_registration_spec.rb:1009` (count séparément)
  - [ ] Vérifier les places découverte
  - [ ] Adapter les tests si nécessaire
  - [ ] Vérifier que tous les tests passent

### 7.4 Memberships Requests (2 erreurs)
- [ ] **Phase 7.24** - Analyser les 2 erreurs de `spec/requests/memberships_spec.rb`
  - [ ] Exécuter tous les tests du fichier
  - [ ] Créer des fichiers d'erreur pour chaque test

- [ ] **Phase 7.25** - Corriger `blocks creation if questionnaire is empty for adult`
  - [ ] Exécuter : `rspec ./spec/requests/memberships_spec.rb:168`
  - [ ] Vérifier la validation adulte
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

- [ ] **Phase 7.26** - Corriger `blocks creation if questionnaire is empty for child`
  - [ ] Exécuter : `rspec ./spec/requests/memberships_spec.rb:188`
  - [ ] Vérifier la validation enfant
  - [ ] Adapter le test si nécessaire
  - [ ] Vérifier que le test passe

---

## ✅ Vérification et Documentation Finale

- [ ] **Vérification finale** - Exécuter tous les tests RSpec et vérifier qu'il reste moins de 20 erreurs
  - [ ] Exécuter : `docker exec grenoble-roller-dev bundle exec rspec`
  - [ ] Compter les erreurs restantes
  - [ ] Si > 20 erreurs, identifier les causes communes et créer un plan d'action

- [ ] **Documentation** - Mettre à jour tous les fichiers d'erreur avec les solutions appliquées
  - [ ] Mettre à jour le statut de chaque fichier d'erreur
  - [ ] Documenter les solutions appliquées
  - [ ] Mettre à jour le README.md avec le nouveau statut
  - [ ] Créer un résumé des corrections effectuées

---

## 📊 Statistiques

- **Total de tâches** : 89
- **Phase 1** : 12 tâches
- **Phase 2** : 20 tâches
- **Phase 3** : 9 tâches
- **Phase 4** : 14 tâches
- **Phase 5** : 8 tâches
- **Phase 6** : 5 tâches
- **Phase 7** : 26 tâches
- **Vérification finale** : 2 tâches

---

## 🎯 Objectifs

- **Court terme** : Réduire les erreurs de 89 à < 20
- **Moyen terme** : Tous les tests passent sauf les pending
- **Long terme** : Maintenir une couverture de tests > 80%

---

## 📝 Notes Importantes

### Changements de Fonctionnement à Prendre en Compte

1. **Événements normaux (randos)** :
   - Tous les enfants peuvent être inscrits, quel que soit leur statut
   - Le parent doit avoir une adhésion active OU un essai gratuit disponible
   - Les tests doivent créer une adhésion active ou utiliser un essai gratuit pour le parent

2. **Initiations** :
   - Les enfants doivent avoir une adhésion active, trial ou pending
   - Le parent peut utiliser son essai gratuit ou avoir une adhésion active
   - La logique reste la même, mais les tests doivent être vérifiés

3. **EventPolicy** :
   - `attend?` vérifie maintenant l'adhésion active ou l'essai gratuit disponible
   - Les tests doivent créer des utilisateurs avec adhésion active ou essai gratuit

---

## 🔗 Ressources

- [Roadmap](ROADMAP.md) - Vue d'ensemble et plan d'action
- [Méthodologie](METHODE.md) - Processus de travail
- [Template d'erreur](TEMPLATE.md) - Template pour créer de nouveaux fichiers d'erreur
