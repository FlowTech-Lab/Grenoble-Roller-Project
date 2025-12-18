# Roadmap - Correction des Erreurs RSpec

**Date de création** : 2025-01-17  
**Statut initial** : 472 examples, 89 failures, 15 pending

---

## 📊 Vue d'Ensemble

### Changements de Fonctionnement Récents

1. **Événements normaux (randos) - Validation d'adhésion modifiée** :
   - ✅ Tous les enfants peuvent être inscrits, quel que soit leur statut (active, expired, trial, pending)
   - ✅ Le parent doit avoir une adhésion active OU un essai gratuit disponible
   - ✅ `EventPolicy#attend?` vérifie maintenant l'adhésion pour les événements normaux
   - ✅ `Events::AttendancesController` ne vérifie plus le statut d'adhésion pour les enfants
   - ✅ `Attendance#can_register_to_event` permet tous les statuts pour les enfants

2. **Initiations - Logique inchangée** :
   - ✅ Les enfants doivent avoir une adhésion active, trial ou pending
   - ✅ Le parent peut utiliser son essai gratuit ou avoir une adhésion active

---

## 🎯 Plan d'Action par Catégorie

### Phase 1 : Tests de Modèles (Priorité 🔴)

**Impact** : 12 erreurs - Fondamentaux de l'application

#### 1.1 Attendance Model (12 erreurs)
- **Fichier** : `spec/models/attendance_spec.rb`
- **Problèmes identifiés** :
  - Tests ne reflètent pas la nouvelle logique pour les événements normaux
  - Tests de validation d'adhésion obsolètes
  - Tests de `can_register_to_event` manquants ou incorrects

**Actions** :
1. [ ] Mettre à jour les tests de validation pour refléter la nouvelle logique
2. [ ] Ajouter des tests pour `can_register_to_event` avec différents statuts d'adhésion enfant
3. [ ] Vérifier que les tests d'initiation fonctionnent toujours

**Tests à corriger** :
- `is valid with default attributes`
- `enforces uniqueness of user scoped to event`
- `accepts an optional payment`
- `counter cache increments/decrements`
- `max_participants validation` (4 tests)
- `scopes` (4 tests)

---

### Phase 2 : Tests de Features (Priorité 🔴)

**Impact** : 19 erreurs - Tests d'intégration critiques

#### 2.1 Event Attendance Features (4 erreurs)
- **Fichier** : `spec/features/event_attendance_spec.rb`
- **Problèmes identifiés** :
  - Tests vérifient des comportements qui ont changé (adhésion requise)
  - Tests de boutons d'inscription/désinscription obsolètes
  - Tests de places restantes peuvent être affectés

**Actions** :
1. [ ] Mettre à jour les tests pour refléter la nouvelle logique d'adhésion
2. [ ] Vérifier que les tests de boutons fonctionnent avec la nouvelle politique
3. [ ] Adapter les tests de places restantes si nécessaire

**Tests à corriger** :
- `affiche le bouton "Se désinscrire" après inscription`
- `affiche le badge "Complet" et désactive le bouton S'inscrire`
- `n'affiche pas le bouton S'inscrire sur la liste des événements`
- `affiche le nombre de places disponibles` (2 tests)

#### 2.2 Initiation Registration Features (6 erreurs)
- **Fichier** : `spec/features/initiation_registration_spec.rb`
- **Problèmes identifiés** :
  - Tests peuvent être affectés par les changements de validation
  - Tests d'essai gratuit à vérifier
  - Tests de capacité à vérifier

**Actions** :
1. [ ] Vérifier que les tests d'essai gratuit fonctionnent toujours
2. [ ] Adapter les tests de capacité si nécessaire
3. [ ] Vérifier les tests de bénévoles

**Tests à corriger** :
- `prevents user from registering twice`
- `allows user without membership to register using free trial`
- `prevents user from using free trial twice`
- `prevents registration when initiation is full`
- `allows volunteers to register even when initiation is full`
- `generates unique UID for each initiation ICS export`
- `allows parent to register child using child membership`

#### 2.3 Mes Sorties Features (6 erreurs)
- **Fichier** : `spec/features/mes_sorties_spec.rb`
- **Problèmes identifiés** :
  - Tests d'affichage des événements inscrits
  - Tests de navigation
  - Tests de filtrage des inscriptions annulées

**Actions** :
1. [ ] Vérifier que les tests d'affichage fonctionnent
2. [ ] Adapter les tests de navigation si nécessaire
3. [ ] Vérifier les tests de filtrage

**Tests à corriger** :
- `affiche la page Mes sorties avec les événements inscrits`
- `affiche les informations de l'événement`
- `n'affiche que les événements où l'utilisateur est inscrit`
- `n'affiche pas les inscriptions annulées`
- `permet de cliquer sur un événement pour voir les détails`
- `permet de retourner à la liste des événements`

---

### Phase 3 : Tests de Jobs (Priorité 🟠)

**Impact** : 8 erreurs - Fonctionnalités de rappel

#### 3.1 Event Reminder Job (8 erreurs)
- **Fichier** : `spec/jobs/event_reminder_job_spec.rb`
- **Problèmes identifiés** :
  - Tests de rappel par email
  - Tests de filtrage des événements
  - Tests de `wants_reminder`

**Actions** :
1. [ ] Vérifier que les tests de rappel fonctionnent
2. [ ] Adapter les tests de filtrage si nécessaire
3. [ ] Vérifier les tests de `wants_reminder`

**Tests à corriger** :
- `sends reminder email to active attendees with wants_reminder = true`
- `sends reminder for events at different times tomorrow`
- `does not send reminder for canceled attendance`
- `does not send reminder if wants_reminder is false`
- `does not send reminder for events today`
- `does not send reminder for events day after tomorrow`
- `does not send reminder for draft events`
- `sends reminder only to attendees with wants_reminder = true`

---

### Phase 4 : Tests de Mailers (Priorité 🟠)

**Impact** : 13 erreurs - Emails de confirmation et rappel

#### 4.1 Event Mailer (13 erreurs)
- **Fichier** : `spec/mailers/event_mailer_spec.rb`
- **Problèmes identifiés** :
  - Tests d'envoi d'emails de confirmation
  - Tests de contenu des emails
  - Tests d'emails de rappel

**Actions** :
1. [ ] Vérifier que les tests d'envoi fonctionnent
2. [ ] Adapter les tests de contenu si nécessaire
3. [ ] Vérifier les tests de rappel

**Tests à corriger** :
- `sends to user email` (2 tests)
- `includes event title in subject` (2 tests)
- `includes event details in body` (2 tests)
- `includes user first name in body` (2 tests)
- `includes event date in body` (1 test)
- `includes event URL in body` (1 test)
- `includes route name in body` (1 test)
- `includes price in body` (1 test)
- `includes participants count in body` (1 test)

---

### Phase 5 : Tests de Modèles Event (Priorité 🟡)

**Impact** : 7 erreurs - Logique métier des événements

#### 5.1 Event Model (7 erreurs)
- **Fichier** : `spec/models/event_spec.rb`
- **Problèmes identifiés** :
  - Tests de `full?` peuvent être affectés
  - Tests de `remaining_spots` à vérifier
  - Tests de `has_available_spots?` à vérifier

**Actions** :
1. [ ] Vérifier que les tests de capacité fonctionnent
2. [ ] Adapter les tests de places restantes si nécessaire
3. [ ] Vérifier les tests de disponibilité

**Tests à corriger** :
- `returns false when not at capacity`
- `returns true when at capacity`
- `does not count canceled attendances`
- `returns correct number of remaining spots`
- `returns 0 when full`
- `does not count canceled attendances` (remaining_spots)
- `returns true/false when not at/at capacity` (has_available_spots)

---

### Phase 6 : Tests de Policies (Priorité 🟡)

**Impact** : 4 erreurs - Autorisations

#### 6.1 Event Policy (4 erreurs)
- **Fichier** : `spec/policies/event_policy_spec.rb`
- **Problèmes identifiés** :
  - Tests de `attend?` doivent refléter la nouvelle logique d'adhésion
  - Tests de `can_attend?` à mettre à jour
  - Tests de `user_has_attendance?` à vérifier

**Actions** :
1. [ ] Mettre à jour les tests de `attend?` pour refléter la vérification d'adhésion
2. [ ] Adapter les tests de `can_attend?` si nécessaire
3. [ ] Vérifier les tests de `user_has_attendance?`

**Tests à corriger** :
- `denies when event is full`
- `returns false when user is already registered`
- `returns false when event is full`
- `returns true when user has an attendance`

---

### Phase 7 : Tests de Requests (Priorité 🟡)

**Impact** : 20 erreurs - Tests d'intégration HTTP

#### 7.1 Event Requests (5 erreurs)
- **Fichier** : `spec/requests/events_spec.rb`
- **Problèmes identifiés** :
  - Tests d'inscription doivent refléter la nouvelle logique
  - Tests de désinscription à vérifier
  - Tests d'utilisateurs non confirmés à vérifier

**Actions** :
1. [ ] Mettre à jour les tests d'inscription pour refléter la vérification d'adhésion
2. [ ] Adapter les tests de désinscription si nécessaire
3. [ ] Vérifier les tests d'utilisateurs non confirmés

**Tests à corriger** :
- `registers the current user`
- `blocks unconfirmed users from attending`
- `does not duplicate an existing attendance`
- `removes the attendance for the current user`

#### 7.2 Event Email Integration (3 erreurs)
- **Fichier** : `spec/requests/event_email_integration_spec.rb`
- **Problèmes identifiés** :
  - Tests d'envoi d'emails de confirmation
  - Tests d'envoi d'emails d'annulation

**Actions** :
1. [ ] Vérifier que les tests d'envoi fonctionnent
2. [ ] Adapter les tests si nécessaire

**Tests à corriger** :
- `sends confirmation email when user attends event`
- `creates attendance and sends email`
- `sends cancellation email when user cancels attendance`

#### 7.3 Initiation Registration Requests (12 erreurs)
- **Fichier** : `spec/requests/initiation_registration_spec.rb`
- **Problèmes identifiés** :
  - Tests d'inscription d'enfants à mettre à jour
  - Tests d'inscription parent/enfant à vérifier
  - Tests de cas limites à vérifier
  - Tests de volontaires à vérifier
  - Tests de non-membres à vérifier

**Actions** :
1. [ ] Mettre à jour les tests d'inscription d'enfants
2. [ ] Adapter les tests d'inscription parent/enfant
3. [ ] Vérifier les tests de cas limites
4. [ ] Vérifier les tests de volontaires
5. [ ] Vérifier les tests de non-membres

**Tests à corriger** :
- `allows parent to register child using child membership` (2 tests)
- `permet inscription adulte puis enfant`
- `permet inscription enfant puis adulte`
- `permet inscription plusieurs enfants`
- `permet inscription adulte + plusieurs enfants`
- `permet inscription adulte avec essai gratuit puis enfant avec adhésion`
- `permet inscription enfant avec adhésion puis adulte (sans essai gratuit car parent considéré membre)`
- `empêche inscription double du même enfant`
- `permet inscription adulte même si enfant déjà inscrit`
- `permet inscription enfant même si adulte déjà inscrit`
- `famille remplit initiation`
- `Volontaires enfant CANNOT être volontaire`
- `famille non-adhérente peut s'inscrire avec découverte` (4 tests)

#### 7.4 Memberships Requests (2 erreurs)
- **Fichier** : `spec/requests/memberships_spec.rb`
- **Problèmes identifiés** :
  - Tests de création sans paiement
  - Tests de questionnaire

**Actions** :
1. [ ] Vérifier que les tests de création fonctionnent
2. [ ] Adapter les tests de questionnaire si nécessaire

**Tests à corriger** :
- `blocks creation if questionnaire is empty for adult`
- `blocks creation if questionnaire is empty for child`

---

## 🔄 Ordre d'Exécution Recommandé

1. **Phase 1** : Tests de Modèles (12 erreurs) - Fondamentaux
2. **Phase 2** : Tests de Features (19 erreurs) - Intégration critique
3. **Phase 5** : Tests de Modèles Event (7 erreurs) - Logique métier
4. **Phase 6** : Tests de Policies (4 erreurs) - Autorisations
5. **Phase 7** : Tests de Requests (20 erreurs) - Intégration HTTP
6. **Phase 3** : Tests de Jobs (8 erreurs) - Fonctionnalités secondaires
7. **Phase 4** : Tests de Mailers (13 erreurs) - Emails

---

## 📝 Checklist Globale

### Pour Chaque Phase

- [ ] Analyser les erreurs de la phase
- [ ] Identifier les causes communes
- [ ] Créer des fichiers d'erreur individuels si nécessaire
- [ ] Appliquer les corrections
- [ ] Exécuter les tests de la phase
- [ ] Vérifier qu'on ne casse pas d'autres tests
- [ ] Documenter les changements

### Pour Chaque Erreur

- [ ] Exécuter le test spécifique
- [ ] Copier l'erreur complète
- [ ] Lire le code du test
- [ ] Lire le code de l'application
- [ ] Identifier le type de problème (test ou logique)
- [ ] Proposer des solutions
- [ ] Appliquer la correction
- [ ] Vérifier que le test passe
- [ ] Documenter dans le fichier d'erreur

---

## 🎯 Objectifs

- **Court terme** : Réduire les erreurs de 89 à < 20
- **Moyen terme** : Tous les tests passent sauf les pending
- **Long terme** : Maintenir une couverture de tests > 80%

---

## 📚 Ressources

- [Méthodologie de travail](METHODE.md)
- [Template d'erreur](TEMPLATE.md)
- [README principal](../README.md)

---

## 🔗 Changements de Fonctionnement à Prendre en Compte

### Événements Normaux (Randos)

1. **Avant** : Seuls les enfants avec adhésion active pouvaient être inscrits
2. **Maintenant** : Tous les enfants peuvent être inscrits, quel que soit leur statut
3. **Impact sur les tests** :
   - Les tests qui vérifient `child_membership&.active?` doivent être mis à jour
   - Les tests qui créent des enfants avec statut `expired` ou `trial` doivent maintenant passer
   - Les tests de validation `can_register_to_event` doivent permettre tous les statuts

### Politique EventPolicy

1. **Avant** : `attend?` ne vérifiait que si l'événement était complet
2. **Maintenant** : `attend?` vérifie aussi l'adhésion active ou l'essai gratuit disponible
3. **Impact sur les tests** :
   - Les tests de `attend?` doivent créer des utilisateurs avec adhésion active ou essai gratuit
   - Les tests qui vérifient l'accès sans adhésion doivent être mis à jour

### Contrôleur Events::AttendancesController

1. **Avant** : Vérifiait `child_membership&.active?` pour les enfants
2. **Maintenant** : Vérifie seulement que l'adhésion appartient à l'utilisateur
3. **Impact sur les tests** :
   - Les tests qui créent des inscriptions d'enfants doivent être mis à jour
   - Les tests qui vérifient les erreurs d'adhésion inactive doivent être supprimés ou modifiés

---

## ✅ Prochaines Étapes

1. Commencer par la **Phase 1** (Tests de Modèles Attendance)
2. Créer un fichier d'erreur pour chaque groupe de tests similaires
3. Appliquer les corrections de manière systématique
4. Documenter chaque correction
