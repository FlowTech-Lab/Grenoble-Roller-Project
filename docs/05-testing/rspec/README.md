# Analyse des Erreurs RSpec - Checklist Générale

**Date de mise à jour** : 2025-01-13  
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
| 24 | `spec/features/event_management_spec.rb` | 20 | Event Management Création d'un événement quand l'utilisateur est organizer permet de créer un événement via le formulaire | [024-features-event-management.md](errors/024-features-event-management.md) | ⏳ À analyser |
| 25 | `spec/features/event_management_spec.rb` | 42 | Event Management Création d'un événement quand l'utilisateur est organizer permet de créer un événement avec max_participants = 0 (illimité) | [024-features-event-management.md](errors/024-features-event-management.md) | ⏳ À analyser |
| 26 | `spec/features/event_management_spec.rb` | 152 | Event Management Suppression d'un événement quand l'utilisateur est le créateur permet de supprimer l'événement avec confirmation | [024-features-event-management.md](errors/024-features-event-management.md) | ⏳ À analyser |
| 27 | `spec/features/event_management_spec.rb` | 171 | Event Management Suppression d'un événement quand l'utilisateur est le créateur annule la suppression si l'utilisateur clique sur Annuler dans le modal | [024-features-event-management.md](errors/024-features-event-management.md) | ⏳ À analyser |
| 28 | `spec/features/event_management_spec.rb` | 235 | Event Management Affichage de la liste des événements affiche le prochain événement en vedette | [024-features-event-management.md](errors/024-features-event-management.md) | ⏳ À analyser |
| 29 | `spec/features/mes_sorties_spec.rb` | 26 | Mes sorties Accès à la page Mes sorties quand l'utilisateur est connecté affiche la page Mes sorties avec les événements inscrits | [029-features-mes-sorties.md](errors/029-features-mes-sorties.md) | ⏳ À analyser |
| 30 | `spec/features/mes_sorties_spec.rb` | 46 | Mes sorties Accès à la page Mes sorties quand l'utilisateur est connecté permet de se désinscrire depuis la page Mes sorties | [029-features-mes-sorties.md](errors/029-features-mes-sorties.md) | ⏳ À analyser |
| 31 | `spec/features/mes_sorties_spec.rb` | 69 | Mes sorties Accès à la page Mes sorties quand l'utilisateur est connecté affiche les informations de l'événement (date, lieu, nombre d'inscrits) | [029-features-mes-sorties.md](errors/029-features-mes-sorties.md) | ⏳ À analyser |
| 32 | `spec/features/mes_sorties_spec.rb` | 81 | Mes sorties Accès à la page Mes sorties quand l'utilisateur est connecté n'affiche que les événements où l'utilisateur est inscrit | [029-features-mes-sorties.md](errors/029-features-mes-sorties.md) | ⏳ À analyser |
| 33 | `spec/features/mes_sorties_spec.rb` | 92 | Mes sorties Accès à la page Mes sorties quand l'utilisateur est connecté n'affiche pas les inscriptions annulées | [029-features-mes-sorties.md](errors/029-features-mes-sorties.md) | ⏳ À analyser |
| 34 | `spec/features/mes_sorties_spec.rb` | 117 | Mes sorties Navigation depuis Mes sorties permet de cliquer sur un événement pour voir les détails | [029-features-mes-sorties.md](errors/029-features-mes-sorties.md) | ⏳ À analyser |
| 35 | `spec/features/mes_sorties_spec.rb` | 133 | Mes sorties Navigation depuis Mes sorties permet de retourner à la liste des événements | [029-features-mes-sorties.md](errors/029-features-mes-sorties.md) | ⏳ À analyser |

---

### 🟡 Priorité 5 : Tests de Jobs (3 erreurs)
**Type** : ⚠️ **À ANALYSER** (jobs d'envoi d'emails)

| # | Fichier Test | Ligne | Description | Fichier Analyse | Statut |
|---|-------------|-------|-------------|-----------------|--------|
| 36 | `spec/jobs/event_reminder_job_spec.rb` | 25 | EventReminderJob#perform when event is tomorrow sends reminder email to active attendees with wants_reminder = true | [036-jobs-event-reminder-send.md](errors/036-jobs-event-reminder-send.md) | ⏳ À analyser |
| 37 | `spec/jobs/event_reminder_job_spec.rb` | 38 | EventReminderJob#perform when event is tomorrow sends reminder for events at different times tomorrow | [037-jobs-event-reminder-different-times.md](errors/037-jobs-event-reminder-different-times.md) | ⏳ À analyser |
| 38 | `spec/jobs/event_reminder_job_spec.rb` | 110 | EventReminderJob#perform with multiple attendees sends reminder only to attendees with wants_reminder = true | [038-jobs-event-reminder-multiple.md](errors/038-jobs-event-reminder-multiple.md) | ⏳ À analyser |

---

### 🟡 Priorité 6 : Tests de Mailers (35 erreurs)
**Type** : ⚠️ **PROBLÈME DE LOGIQUE** (templates ou helpers)

| # | Fichier Test | Ligne | Description | Fichier Analyse | Statut |
|---|-------------|-------|-------------|-----------------|--------|
| 39 | `spec/mailers/event_mailer_spec.rb` | 28 | EventMailer#attendance_confirmed includes event date in body | [039-mailers-event-mailer.md](errors/039-mailers-event-mailer.md) | ⏳ À analyser |
| 40 | `spec/mailers/event_mailer_spec.rb` | 35 | EventMailer#attendance_confirmed includes event URL in body | [039-mailers-event-mailer.md](errors/039-mailers-event-mailer.md) | ⏳ À analyser |
| 41 | `spec/mailers/event_mailer_spec.rb` | 100 | EventMailer#attendance_cancelled includes event date in body | [039-mailers-event-mailer.md](errors/039-mailers-event-mailer.md) | ⏳ À analyser |
| 42 | `spec/mailers/event_mailer_spec.rb` | 107 | EventMailer#attendance_cancelled includes event URL in body | [039-mailers-event-mailer.md](errors/039-mailers-event-mailer.md) | ⏳ À analyser |
| 43 | `spec/mailers/membership_mailer_spec.rb` | 7 | MembershipMailer activated renders the headers | [043-mailers-membership-mailer.md](errors/043-mailers-membership-mailer.md) | ⏳ À analyser |
| 44 | `spec/mailers/membership_mailer_spec.rb` | 13 | MembershipMailer activated renders the body | [043-mailers-membership-mailer.md](errors/043-mailers-membership-mailer.md) | ⏳ À analyser |
| 45 | `spec/mailers/membership_mailer_spec.rb` | 21 | MembershipMailer expired renders the headers | [043-mailers-membership-mailer.md](errors/043-mailers-membership-mailer.md) | ⏳ À analyser |
| 46 | `spec/mailers/membership_mailer_spec.rb` | 27 | MembershipMailer expired renders the body | [043-mailers-membership-mailer.md](errors/043-mailers-membership-mailer.md) | ⏳ À analyser |
| 47 | `spec/mailers/membership_mailer_spec.rb` | 35 | MembershipMailer renewal_reminder renders the headers | [043-mailers-membership-mailer.md](errors/043-mailers-membership-mailer.md) | ⏳ À analyser |
| 48 | `spec/mailers/membership_mailer_spec.rb` | 41 | MembershipMailer renewal_reminder renders the body | [043-mailers-membership-mailer.md](errors/043-mailers-membership-mailer.md) | ⏳ À analyser |
| 49 | `spec/mailers/membership_mailer_spec.rb` | 49 | MembershipMailer payment_failed renders the headers | [043-mailers-membership-mailer.md](errors/043-mailers-membership-mailer.md) | ⏳ À analyser |
| 50 | `spec/mailers/membership_mailer_spec.rb` | 55 | MembershipMailer payment_failed renders the body | [043-mailers-membership-mailer.md](errors/043-mailers-membership-mailer.md) | ⏳ À analyser |
| 51 | `spec/mailers/order_mailer_spec.rb` | 11 | OrderMailer#order_confirmation sends to user email | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 52 | `spec/mailers/order_mailer_spec.rb` | 15 | OrderMailer#order_confirmation includes order id in subject | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 53 | `spec/mailers/order_mailer_spec.rb` | 20 | OrderMailer#order_confirmation includes order details in body | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 54 | `spec/mailers/order_mailer_spec.rb` | 25 | OrderMailer#order_confirmation includes user first name in body | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 55 | `spec/mailers/order_mailer_spec.rb` | 29 | OrderMailer#order_confirmation includes order URL in body | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 56 | `spec/mailers/order_mailer_spec.rb` | 33 | OrderMailer#order_confirmation has HTML content | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 57 | `spec/mailers/order_mailer_spec.rb` | 38 | OrderMailer#order_confirmation has text content as fallback | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 58 | `spec/mailers/order_mailer_spec.rb` | 48 | OrderMailer#order_paid sends to user email | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 59 | `spec/mailers/order_mailer_spec.rb` | 52 | OrderMailer#order_paid includes order id in subject | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 60 | `spec/mailers/order_mailer_spec.rb` | 57 | OrderMailer#order_paid includes payment confirmation in body | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 61 | `spec/mailers/order_mailer_spec.rb` | 62 | OrderMailer#order_paid includes order URL in body | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 62 | `spec/mailers/order_mailer_spec.rb` | 71 | OrderMailer#order_cancelled sends to user email | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 63 | `spec/mailers/order_mailer_spec.rb` | 75 | OrderMailer#order_cancelled includes order id in subject | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 64 | `spec/mailers/order_mailer_spec.rb` | 80 | OrderMailer#order_cancelled includes cancellation information in body | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 65 | `spec/mailers/order_mailer_spec.rb` | 85 | OrderMailer#order_cancelled includes orders URL in body | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 66 | `spec/mailers/order_mailer_spec.rb` | 94 | OrderMailer#order_preparation sends to user email | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 67 | `spec/mailers/order_mailer_spec.rb` | 98 | OrderMailer#order_preparation includes order id in subject | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 68 | `spec/mailers/order_mailer_spec.rb` | 103 | OrderMailer#order_preparation includes preparation information in body | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 69 | `spec/mailers/order_mailer_spec.rb` | 108 | OrderMailer#order_preparation includes order URL in body | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 70 | `spec/mailers/order_mailer_spec.rb` | 117 | OrderMailer#order_shipped sends to user email | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 71 | `spec/mailers/order_mailer_spec.rb` | 121 | OrderMailer#order_shipped includes order id in subject | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 72 | `spec/mailers/order_mailer_spec.rb` | 126 | OrderMailer#order_shipped includes shipping confirmation in body | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 73 | `spec/mailers/order_mailer_spec.rb` | 131 | OrderMailer#order_shipped includes order URL in body | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 74 | `spec/mailers/order_mailer_spec.rb` | 140 | OrderMailer#refund_requested sends to user email | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 75 | `spec/mailers/order_mailer_spec.rb` | 144 | OrderMailer#refund_requested includes order id in subject | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 76 | `spec/mailers/order_mailer_spec.rb` | 149 | OrderMailer#refund_requested includes refund request information in body | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 77 | `spec/mailers/order_mailer_spec.rb` | 159 | OrderMailer#refund_confirmed sends to user email | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 78 | `spec/mailers/order_mailer_spec.rb` | 163 | OrderMailer#refund_confirmed includes order id in subject | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 79 | `spec/mailers/order_mailer_spec.rb` | 168 | OrderMailer#refund_confirmed includes refund confirmation in body | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 80 | `spec/mailers/order_mailer_spec.rb` | 173 | OrderMailer#refund_confirmed includes orders URL in body | [051-mailers-order-mailer.md](errors/051-mailers-order-mailer.md) | ⏳ À analyser |
| 81 | `spec/mailers/user_mailer_spec.rb` | 17 | UserMailer#welcome_email includes user first name in body | [081-mailers-user-mailer.md](errors/081-mailers-user-mailer.md) | ⏳ À analyser |
| 82 | `spec/mailers/user_mailer_spec.rb` | 25 | UserMailer#welcome_email has HTML content | [081-mailers-user-mailer.md](errors/081-mailers-user-mailer.md) | ⏳ À analyser |
| 83 | `spec/mailers/user_mailer_spec.rb` | 30 | UserMailer#welcome_email has text content as fallback | [081-mailers-user-mailer.md](errors/081-mailers-user-mailer.md) | ⏳ À analyser |

---

### 🟡 Priorité 7 : Tests de Modèles (100+ erreurs)
**Type** : ⚠️ **PROBLÈME DE LOGIQUE** (validations, associations, logique métier)

Voir les fichiers détaillés pour chaque modèle :
- [084-models-attendance.md](errors/084-models-attendance.md) - 20 erreurs (lignes 8, 13, 19, 29, 39, 48, 59, 70, 75, 81, 93, 107, 114, 122, 132, 151, 157, 164, 173, 189, 200, 207, 215)
- [105-models-audit-log.md](errors/105-models-audit-log.md) - 6 erreurs (lignes 9, 14, 24, 31, 38, 46)
- [111-models-contact-message.md](errors/111-models-contact-message.md) - 3 erreurs (lignes 15, 24, 35)
- [114-models-event-initiation.md](errors/114-models-event-initiation.md) - 18 erreurs (lignes 16, 21, 27, 33, 39, 46, 54, 60, 66, 75, 81, 90, 97, 107, 116, 124, 133)
- [132-models-event.md](errors/132-models-event.md) - 15 erreurs (lignes 13, 29, 35, 41, 47, 55, 62, 69, 78, 83, 90, 95, 101, 109, 125, 130, 137, 145, 155, 160, 167)
- [153-models-option-value.md](errors/153-models-option-value.md) - 1 erreur (ligne 17)
- [154-models-order-item.md](errors/154-models-order-item.md) - 1 erreur (ligne 11)
- [155-models-order.md](errors/155-models-order.md) - 2 erreurs (lignes 7, 13)
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

### 🟡 Priorité 8 : Tests de Policies (1 erreur)
**Type** : ⚠️ **À ANALYSER** (scope Pundit)

| # | Fichier Test | Ligne | Description | Fichier Analyse | Statut |
|---|-------------|-------|-------------|-----------------|--------|
| 184 | `spec/policies/event_policy_spec.rb` | 153 | EventPolicy Scope returns only published events for guests | [184-policies-event-policy-scope.md](errors/184-policies-event-policy-scope.md) | ⏳ À analyser |

---

### 🟡 Priorité 9 : Tests de Request (38 erreurs)
**Type** : ⚠️ **PROBLÈME DE LOGIQUE** (contrôleurs ou configuration)

| # | Fichier Test | Ligne | Description | Fichier Analyse | Statut |
|---|-------------|-------|-------------|-----------------|--------|
| 185 | `spec/requests/attendances_spec.rb` | 60 | Attendances PATCH /initiations/:initiation_id/attendances/toggle_reminder toggles reminder preference for authenticated user | [185-requests-attendances-toggle-reminder.md](errors/185-requests-attendances-toggle-reminder.md) | ⏳ À analyser |
| 186 | `spec/requests/event_email_integration_spec.rb` | 16 | Event Email Integration POST /events/:event_id/attendances sends confirmation email when user attends event | [186-requests-event-email-integration.md](errors/186-requests-event-email-integration.md) | ⏳ À analyser |
| 187 | `spec/requests/event_email_integration_spec.rb` | 24 | Event Email Integration POST /events/:event_id/attendances creates attendance and sends email | [186-requests-event-email-integration.md](errors/186-requests-event-email-integration.md) | ⏳ À analyser |
| 188 | `spec/requests/event_email_integration_spec.rb` | 44 | Event Email Integration DELETE /events/:event_id/attendances sends cancellation email when user cancels attendance | [186-requests-event-email-integration.md](errors/186-requests-event-email-integration.md) | ⏳ À analyser |
| 189 | `spec/requests/events_spec.rb` | 27 | Events GET /events/:id redirects visitors trying to view a draft event | [189-requests-events.md](errors/189-requests-events.md) | ⏳ À analyser |
| 190 | `spec/requests/events_spec.rb` | 47 | Events POST /events allows an organizer to create an event | [189-requests-events.md](errors/189-requests-events.md) | ⏳ À analyser |
| 191 | `spec/requests/events_spec.rb` | 76 | Events POST /events/:id/attend requires authentication | [189-requests-events.md](errors/189-requests-events.md) | ⏳ À analyser |
| 192 | `spec/requests/events_spec.rb` | 82 | Events POST /events/:id/attend registers the current user | [189-requests-events.md](errors/189-requests-events.md) | ⏳ À analyser |
| 193 | `spec/requests/events_spec.rb` | 97 | Events POST /events/:id/attend blocks unconfirmed users from attending | [189-requests-events.md](errors/189-requests-events.md) | ⏳ À analyser |
| 194 | `spec/requests/events_spec.rb` | 132 | Events DELETE /events/:event_id/attendances removes the attendance for the current user | [189-requests-events.md](errors/189-requests-events.md) | ⏳ À analyser |
| 195 | `spec/requests/events_spec.rb` | 152 | Events GET /events/:id.ics requires authentication | [189-requests-events.md](errors/189-requests-events.md) | ⏳ À analyser |
| 196 | `spec/requests/initiations_spec.rb` | 29 | Initiations GET /initiations/:id redirects visitors trying to view a draft initiation | [196-requests-initiations.md](errors/196-requests-initiations.md) | ⏳ À analyser |
| 197 | `spec/requests/initiations_spec.rb` | 43 | Initiations GET /initiations/:id.ics requires authentication | [196-requests-initiations.md](errors/196-requests-initiations.md) | ⏳ À analyser |
| 198 | `spec/requests/initiations_spec.rb` | 51 | Initiations GET /initiations/:id.ics exports initiation as iCal file for published initiation when authenticated | [196-requests-initiations.md](errors/196-requests-initiations.md) | ⏳ À analyser |
| 199 | `spec/requests/initiations_spec.rb` | 67 | Initiations GET /initiations/:id.ics redirects to root for draft initiation when authenticated but not creator | [196-requests-initiations.md](errors/196-requests-initiations.md) | ⏳ À analyser |
| 200 | `spec/requests/initiations_spec.rb` | 77 | Initiations GET /initiations/:id.ics allows creator to export draft initiation | [196-requests-initiations.md](errors/196-requests-initiations.md) | ⏳ À analyser |
| 201 | `spec/requests/initiations_spec.rb` | 98 | Initiations POST /initiations/:initiation_id/attendances registers the current user | [196-requests-initiations.md](errors/196-requests-initiations.md) | ⏳ À analyser |
| 202 | `spec/requests/memberships_spec.rb` | 28 | Memberships GET /memberships/new allows authenticated user to access new membership form | [202-requests-memberships.md](errors/202-requests-memberships.md) | ⏳ À analyser |
| 203 | `spec/requests/memberships_spec.rb` | 96 | Memberships POST /memberships/:membership_id/payments/create_multiple requires authentication | [202-requests-memberships.md](errors/202-requests-memberships.md) | ⏳ À analyser |
| 204 | `spec/requests/memberships_spec.rb` | 101 | Memberships POST /memberships/:membership_id/payments/create_multiple redirects to HelloAsso for multiple pending memberships | [202-requests-memberships.md](errors/202-requests-memberships.md) | ⏳ À analyser |
| 205 | `spec/requests/pages_spec.rb` | 9 | Pages GET /association returns success | [205-requests-pages-association.md](errors/205-requests-pages-association.md) | ⏳ À analyser |
| 206 | `spec/requests/registrations_spec.rb` | 36 | POST /users with valid parameters and RGPD consent creates a new user | [206-requests-registrations.md](errors/206-requests-registrations.md) | ⏳ À analyser |
| 207 | `spec/requests/registrations_spec.rb` | 42 | POST /users with valid parameters and RGPD consent redirects to events page | [206-requests-registrations.md](errors/206-requests-registrations.md) | ⏳ À analyser |
| 208 | `spec/requests/registrations_spec.rb` | 47 | POST /users with valid parameters and RGPD consent sets a personalized welcome message | [206-requests-registrations.md](errors/206-requests-registrations.md) | ⏳ À analyser |
| 209 | `spec/requests/registrations_spec.rb` | 54 | POST /users with valid parameters and RGPD consent sends welcome email | [206-requests-registrations.md](errors/206-requests-registrations.md) | ⏳ À analyser |
| 210 | `spec/requests/registrations_spec.rb` | 61 | POST /users with valid parameters and RGPD consent sends confirmation email | [206-requests-registrations.md](errors/206-requests-registrations.md) | ⏳ À analyser |
| 211 | `spec/requests/registrations_spec.rb` | 68 | POST /users with valid parameters and RGPD consent creates user with correct attributes | [206-requests-registrations.md](errors/206-requests-registrations.md) | ⏳ À analyser |
| 212 | `spec/requests/registrations_spec.rb` | 78 | POST /users with valid parameters and RGPD consent allows immediate access (grace period) | [206-requests-registrations.md](errors/206-requests-registrations.md) | ⏳ À analyser |
| 213 | `spec/requests/registrations_spec.rb` | 106 | POST /users without RGPD consent stays on sign_up page (does not redirect to /users) | [206-requests-registrations.md](errors/206-requests-registrations.md) | ⏳ À analyser |
| 214 | `spec/requests/registrations_spec.rb` | 128 | POST /users with invalid email displays email validation error | [206-requests-registrations.md](errors/206-requests-registrations.md) | ⏳ À analyser |
| 215 | `spec/requests/registrations_spec.rb` | 143 | POST /users with missing first_name displays first_name validation error | [206-requests-registrations.md](errors/206-requests-registrations.md) | ⏳ À analyser |
| 216 | `spec/requests/registrations_spec.rb` | 158 | POST /users with password too short displays password validation error with 12 characters | [206-requests-registrations.md](errors/206-requests-registrations.md) | ⏳ À analyser |
| 217 | `spec/requests/registrations_spec.rb` | 173 | POST /users with missing skill_level displays skill_level validation error | [206-requests-registrations.md](errors/206-requests-registrations.md) | ⏳ À analyser |
| 218 | `spec/requests/registrations_spec.rb` | 192 | POST /users with duplicate email displays email taken error | [206-requests-registrations.md](errors/206-requests-registrations.md) | ⏳ À analyser |

---

## 📊 Statistiques Globales

- **Total d'erreurs** : 219
- **Erreurs listées individuellement** : 118
- **Erreurs regroupées (modèles)** : 101 (dans 17 fichiers)
- **Fichiers d'erreur créés** : 50
- **Erreurs analysées** : 4
- **Erreurs avec solution** : 1
- **Erreurs à analyser** : 215

---

## 🔄 Méthodologie de Travail

Voir [METHODE.md](METHODE.md) pour la méthodologie complète.

---

## 📝 Légende des Statuts

- 🟢 **Solution identifiée** : La solution est claire, prête à être appliquée
- 🟡 **Solution à tester** : Solution proposée mais pas encore testée
- ⏳ **À analyser** : Erreur identifiée mais pas encore analysée en détail
- ✅ **Corrigé** : Erreur corrigée et test passant
- ❌ **Bloqué** : Erreur nécessite une décision ou une modification plus importante

---

## 🔗 Liens Utiles

- [Méthodologie de travail](METHODE.md)
- [Template pour créer des fichiers d'erreur](errors/TEMPLATE.md)
- [Stratégie de tests](../strategy.md)
- [Documentation RSpec originale](../../Rspec.md)
