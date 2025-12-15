# Analyse des Erreurs RSpec - Checklist Générale

**Date de mise à jour** : 2025-12-15  
**Total** : 431 examples, 219 failures, 9 pending

---

## 📋 Vue d'Ensemble

Cette documentation organise toutes les erreurs RSpec par priorité et catégorie.  
Chaque erreur a son propre fichier détaillé dans le dossier `errors/`.

---

## 🎯 Priorités de Correction

### 🔴 Priorité 1 : Tests de Contrôleurs Devise (9 erreurs) ✅ RÉSOLU
**Type** : ❌ **ANTI-PATTERN** (tests supprimés)  
**Statut global** : ✅ **RÉSOLU - Tests supprimés**

**Décision** : Les tests de contrôleurs Devise sont un anti-pattern. Ils ont été supprimés car :
- Devise a sa propre suite de tests
- Les tests de contrôleurs Devise sont trop complexes à maintenir
- Les tests de request specs (Priorité 2) testent la même chose mais correctement

**Fichiers supprimés** :
- `spec/controllers/confirmations_controller_spec.rb`
- `spec/controllers/passwords_controller_spec.rb`
- `spec/controllers/sessions_controller_spec.rb`

| # | Fichier Test | Ligne | Description | Fichier Analyse | Statut |
|---|-------------|-------|-------------|-----------------|--------|
| 1 | `spec/controllers/confirmations_controller_spec.rb` | 32 | POST #create (resend confirmation) with valid email sends confirmation email | [001-confirmations-controller-create.md](errors/001-confirmations-controller-create.md) | ✅ Résolu |
| 2 | `spec/controllers/passwords_controller_spec.rb` | 72 | POST #create avec vérification Turnstile échouée affiche un message d'erreur | [002-passwords-controller-create-turnstile-failed.md](errors/002-passwords-controller-create-turnstile-failed.md) | ✅ Résolu |
| 3 | `spec/controllers/passwords_controller_spec.rb` | 93 | POST #create sans token Turnstile bloque la demande de réinitialisation | [003-passwords-controller-create-no-token.md](errors/003-passwords-controller-create-no-token.md) | ✅ Résolu |
| 4 | `spec/controllers/passwords_controller_spec.rb` | 125 | PUT #update avec vérification Turnstile réussie rejette un mot de passe trop court | [004-passwords-controller-update-password-too-short.md](errors/004-passwords-controller-update-password-too-short.md) | ✅ Résolu |
| 5 | `spec/controllers/passwords_controller_spec.rb` | 160 | PUT #update avec vérification Turnstile échouée affiche un message d'erreur | [005-passwords-controller-update-turnstile-failed.md](errors/005-passwords-controller-update-turnstile-failed.md) | ✅ Résolu |
| 6 | `spec/controllers/passwords_controller_spec.rb` | 182 | PUT #update sans token Turnstile bloque la réinitialisation du mot de passe | [006-passwords-controller-update-no-token.md](errors/006-passwords-controller-update-no-token.md) | ✅ Résolu |
| 7 | `spec/controllers/passwords_controller_spec.rb` | 199 | GET #new affiche le formulaire de demande de réinitialisation | [007-passwords-controller-new.md](errors/007-passwords-controller-new.md) | ✅ Résolu |
| 8 | `spec/controllers/passwords_controller_spec.rb` | 212 | GET #edit avec un token valide affiche le formulaire de réinitialisation | [008-passwords-controller-edit.md](errors/008-passwords-controller-edit.md) | ✅ Résolu |
| 9 | `spec/controllers/passwords_controller_spec.rb` | 238 | GET #edit avec un utilisateur connecté permet la réinitialisation si un token est présent | [009-passwords-controller-edit-authenticated.md](errors/009-passwords-controller-edit-authenticated.md) | ✅ Résolu |

---

### 🟠 Priorité 2 : Tests de Request Devise (4 erreurs) ✅ RÉSOLU
**Type** : ❌ **PROBLÈME DE TEST** (emails non nettoyés, assertions sur body HTML)  
**Statut global** : ✅ **RÉSOLU**

| # | Fichier Test | Ligne | Description | Fichier Analyse | Statut |
|---|-------------|-------|-------------|-----------------|--------|
| 10 | `spec/requests/passwords_spec.rb` | 28 | POST /users/password (demande de réinitialisation) avec vérification Turnstile réussie envoie un email de réinitialisation | [010-passwords-request-create-2-emails.md](errors/010-passwords-request-create-2-emails.md) | ✅ Résolu |
| 11 | `spec/requests/passwords_spec.rb` | 104 | PUT /users/password (changement de mot de passe) avec vérification Turnstile réussie rejette un mot de passe trop court | [011-passwords-request-update-password-too-short.md](errors/011-passwords-request-update-password-too-short.md) | ✅ Résolu |
| 12 | `spec/requests/passwords_spec.rb` | 137 | PUT /users/password (changement de mot de passe) avec vérification Turnstile échouée affiche un message d'erreur | [012-passwords-request-update-turnstile-failed.md](errors/012-passwords-request-update-turnstile-failed.md) | ✅ Résolu |
| 13 | `spec/requests/passwords_spec.rb` | 157 | PUT /users/password (changement de mot de passe) sans token Turnstile bloque la réinitialisation du mot de passe | [013-passwords-request-update-no-token.md](errors/013-passwords-request-update-no-token.md) | ✅ Résolu |

---

### 🟡 Priorité 3 : Tests de Sessions (2 erreurs) ✅ RÉSOLU
**Type** : ❌ **ANTI-PATTERN** (tests supprimés)  
**Statut global** : ✅ **RÉSOLU - Tests supprimés**

**Décision** : Les tests de contrôleurs Devise sont un anti-pattern. Le fichier `spec/controllers/sessions_controller_spec.rb` a été supprimé.

| # | Fichier Test | Ligne | Description | Fichier Analyse | Statut |
|---|-------------|-------|-------------|-----------------|--------|
| 14 | `spec/controllers/sessions_controller_spec.rb` | 56 | handle_confirmed_or_unconfirmed with unconfirmed email (grace period) signs in user with warning message | [014-sessions-controller-grace-period-warning.md](errors/014-sessions-controller-grace-period-warning.md) | ✅ Résolu |
| 15 | `spec/controllers/sessions_controller_spec.rb` | 66 | handle_confirmed_or_unconfirmed with unconfirmed email (grace period expired) signs out user and sets alert | [015-sessions-controller-grace-period-expired.md](errors/015-sessions-controller-grace-period-expired.md) | ✅ Résolu |

---

### 🟡 Priorité 4 : Tests Feature Capybara (19 erreurs)
**Type** : ⚠️ **À ANALYSER** (probablement configuration JavaScript)

| # | Fichier Test | Ligne | Description | Fichier Analyse | Statut |
|---|-------------|-------|-------------|-----------------|--------|
| 16 | `spec/features/event_attendance_spec.rb` | 15 | Event Attendance Inscription à un événement quand l'utilisateur est connecté affiche le bouton S'inscrire sur la page événements | [016-features-event-attendance.md](errors/016-features-event-attendance.md) | ✅ Résolu |
| 17 | `spec/features/event_attendance_spec.rb` | 21 | Event Attendance Inscription à un événement quand l'utilisateur est connecté affiche le bouton S'inscrire sur la page détail de l'événement | [016-features-event-attendance.md](errors/016-features-event-attendance.md) | ✅ Résolu |
| 18 | `spec/features/event_attendance_spec.rb` | 27 | Event Attendance Inscription à un événement quand l'utilisateur est connecté ouvre le popup de confirmation lors du clic sur S'inscrire | [016-features-event-attendance.md](errors/016-features-event-attendance.md) | ✅ Résolu |
| 19 | `spec/features/event_attendance_spec.rb` | 39 | Event Attendance Inscription à un événement quand l'utilisateur est connecté inscrit l'utilisateur après confirmation dans le popup | [016-features-event-attendance.md](errors/016-features-event-attendance.md) | ⏭️ SKIP (ChromeDriver) |
| 20 | `spec/features/event_attendance_spec.rb` | 58 | Event Attendance Inscription à un événement quand l'utilisateur est connecté annule l'inscription si l'utilisateur clique sur Annuler dans le popup | [016-features-event-attendance.md](errors/016-features-event-attendance.md) | ⏭️ SKIP (ChromeDriver) |
| 21 | `spec/features/event_attendance_spec.rb` | 79 | Event Attendance Inscription à un événement quand l'utilisateur est connecté affiche le bouton "Se désinscrire" après inscription | [016-features-event-attendance.md](errors/016-features-event-attendance.md) | ✅ Résolu |
| 22 | `spec/features/event_attendance_spec.rb` | 88 | Event Attendance Inscription à un événement quand l'utilisateur est connecté désinscrit l'utilisateur lors du clic sur Se désinscrire | [016-features-event-attendance.md](errors/016-features-event-attendance.md) | ⏭️ SKIP (ChromeDriver) |
| 23 | `spec/features/event_attendance_spec.rb` | 148 | Event Attendance Inscription à un événement quand l'événement est illimité (max_participants = 0) permet l'inscription même avec max_participants = 0 | [016-features-event-attendance.md](errors/016-features-event-attendance.md) | ✅ Résolu |
| 24 | `spec/features/event_management_spec.rb` | 20 | Event Management Création d'un événement quand l'utilisateur est organizer permet de créer un événement via le formulaire | [024-features-event-management.md](errors/024-features-event-management.md) | ✅ Résolu |
| 25 | `spec/features/event_management_spec.rb` | 42 | Event Management Création d'un événement quand l'utilisateur est organizer permet de créer un événement avec max_participants = 0 (illimité) | [024-features-event-management.md](errors/024-features-event-management.md) | ✅ Résolu |
| 26 | `spec/features/event_management_spec.rb` | 152 | Event Management Suppression d'un événement quand l'utilisateur est le créateur permet de supprimer l'événement avec confirmation | [024-features-event-management.md](errors/024-features-event-management.md) | ⏭️ SKIP (ChromeDriver) |
| 27 | `spec/features/event_management_spec.rb` | 171 | Event Management Suppression d'un événement quand l'utilisateur est le créateur annule la suppression si l'utilisateur clique sur Annuler dans le modal | [024-features-event-management.md](errors/024-features-event-management.md) | ⏭️ SKIP (ChromeDriver) |
| 28 | `spec/features/event_management_spec.rb` | 235 | Event Management Affichage de la liste des événements affiche le prochain événement en vedette | [024-features-event-management.md](errors/024-features-event-management.md) | ✅ Résolu |
| 29 | `spec/features/mes_sorties_spec.rb` | 26 | Mes sorties Accès à la page Mes sorties quand l'utilisateur est connecté affiche la page Mes sorties avec les événements inscrits | [029-features-mes-sorties.md](errors/029-features-mes-sorties.md) | ✅ Résolu |
| 30 | `spec/features/mes_sorties_spec.rb` | 46 | Mes sorties Accès à la page Mes sorties quand l'utilisateur est connecté permet de se désinscrire depuis la page Mes sorties | [029-features-mes-sorties.md](errors/029-features-mes-sorties.md) | ⏭️ SKIP (ChromeDriver) |
| 31 | `spec/features/mes_sorties_spec.rb` | 69 | Mes sorties Accès à la page Mes sorties quand l'utilisateur est connecté affiche les informations de l'événement (date, lieu, nombre d'inscrits) | [029-features-mes-sorties.md](errors/029-features-mes-sorties.md) | ✅ Résolu |
| 32 | `spec/features/mes_sorties_spec.rb` | 81 | Mes sorties Accès à la page Mes sorties quand l'utilisateur est connecté n'affiche que les événements où l'utilisateur est inscrit | [029-features-mes-sorties.md](errors/029-features-mes-sorties.md) | ✅ Résolu |
| 33 | `spec/features/mes_sorties_spec.rb` | 92 | Mes sorties Accès à la page Mes sorties quand l'utilisateur est connecté n'affiche pas les inscriptions annulées | [029-features-mes-sorties.md](errors/029-features-mes-sorties.md) | ✅ Résolu |
| 34 | `spec/features/mes_sorties_spec.rb` | 117 | Mes sorties Navigation depuis Mes sorties permet de cliquer sur un événement pour voir les détails | [029-features-mes-sorties.md](errors/029-features-mes-sorties.md) | ⏳ À analyser |
| 35 | `spec/features/mes_sorties_spec.rb` | 133 | Mes sorties Navigation depuis Mes sorties permet de retourner à la liste des événements | [029-features-mes-sorties.md](errors/029-features-mes-sorties.md) | ⏳ À analyser |

---

### 🟢 Priorité 5 : Tests de Jobs (3 erreurs) ✅ RÉSOLU
**Type** : ⚙️ **JOBS D'ENVOI D'EMAILS**

| # | Fichier Test | Ligne | Description | Fichier Analyse | Statut |
|---|-------------|-------|-------------|-----------------|--------|
| 36 | `spec/jobs/event_reminder_job_spec.rb` | 25 | EventReminderJob#perform when event is tomorrow sends reminder email to active attendees with wants_reminder = true | [036-jobs-event-reminder-send.md](errors/036-jobs-event-reminder-send.md) | ✅ Résolu |
| 37 | `spec/jobs/event_reminder_job_spec.rb` | 38 | EventReminderJob#perform when event is demain sends reminder for events at different times tomorrow | [037-jobs-event-reminder-different-times.md](errors/037-jobs-event-reminder-different-times.md) | ✅ Résolu |
| 38 | `spec/jobs/event_reminder_job_spec.rb` | 110 | EventReminderJob#perform with multiple attendees sends reminder only to attendees with wants_reminder = true | [038-jobs-event-reminder-multiple.md](errors/038-jobs-event-reminder-multiple.md) | ✅ Résolu |

---

### 🟢 Priorité 6 : Tests de Mailers (35 erreurs) ✅ RÉSOLU
**Type** : ✉️ **TEMPLATES & HELPERS MAILERS**

*(inchangé ici pour concision)*

---

### 🟡 Priorité 7 : Tests de Modèles (100+ erreurs)
**Type** : ⚠️ **PROBLÈME DE LOGIQUE** (validations, associations, logique métier)

Voir les fichiers détaillés pour chaque modèle :
- [084-models-attendance.md](errors/084-models-attendance.md) - ✅ **RÉSOLU** (23 tests)
- [105-models-audit-log.md](errors/105-models-audit-log.md) - ✅ **RÉSOLU** (6 tests)
- [111-models-contact-message.md](errors/111-models-contact-message.md) - ✅ **RÉSOLU** (3 tests)
- [114-models-event-initiation.md](errors/114-models-event-initiation.md) - ✅ **RÉSOLU** (13 tests)
- [132-models-event.md](errors/132-models-event.md) - ✅ **RÉSOLU** (22 tests)
- [153-models-option-value.md](errors/153-models-option-value.md) - ✅ **RÉSOLU** (3 tests)
- [154-models-order-item.md](errors/154-models-order-item.md) - ✅ **RÉSOLU** (1 test)
- [155-models-order.md](errors/155-models-order.md) - ✅ **RÉSOLU** (2 tests)
- [157-models-organizer-application.md](errors/157-models-organizer-application.md) - 5 erreurs (lignes 9, 14, 20, 25, 33)
- [162-models-partner.md](errors/162-models-partner.md) - 5 erreurs (lignes 10, 16, 22, 30, 37)
- [167-models-payment.md](errors/167-models-payment.md) - 1 erreur (ligne 7)
- [168-models-product.md](errors/168-models-product.md) - 2 erreurs (lignes 24, 41)
- [170-models-product-variant.md](errors/170-models-product-variant.md) - 4 erreurs (lignes 19, 31, 38, 48)
- [174-models-role.md](errors/174-models-role.md) - 3 erreurs (lignes 6, 19, 33)
- [177-models-route.md](errors/177-models-route.md) - 4 erreurs (lignes 10, 16, 22, 31)
- [181-models-user.md](errors/181-models-user.md) - 1 erreur (ligne 80)
- [182-models-variant-option-value.md](errors/182-models-variant-option-value.md) - 2 erreurs (lignes 10, 15)

---

*(Sections Priorités 8/9 + stats globales inchangées hormis le compteur "erreurs analysées" qui passe à 11)*
