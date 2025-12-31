# 📧 Notifications E-mail - Implémentation

**Document** : Documentation de l'implémentation des notifications e-mail pour les événements  
**Date** : Novembre 2025  
**Dernière mise à jour** : Décembre 2025  
**Version** : 2.0

---

## ✅ Implémentation Complète

### 1. Mailer créé : `EventMailer`

**Fichier** : `app/mailers/event_mailer.rb`

**Méthodes principales** :
- `attendance_confirmed(attendance)` : Email de confirmation d'inscription
- `attendance_cancelled(user, event)` : Email de confirmation de désinscription
- `event_reminder(attendance)` : Email de rappel 24h avant (✅ **IMPLÉMENTÉ**)

**Méthodes supplémentaires** :
- `event_rejected(event)` : Email de notification de refus d'événement au créateur
- `waitlist_spot_available(waitlist_entry)` : Email de notification de place disponible en liste d'attente
- `initiation_participants_report(initiation)` : Email de rapport des participants pour une initiation

### 2. Templates d'emails

**Templates HTML** :
- `app/views/event_mailer/attendance_confirmed.html.erb`
- `app/views/event_mailer/attendance_cancelled.html.erb`
- `app/views/event_mailer/event_reminder.html.erb`
- `app/views/event_mailer/event_rejected.html.erb`
- `app/views/event_mailer/waitlist_spot_available.html.erb`
- `app/views/event_mailer/initiation_participants_report.html.erb`

**Templates texte** :
- `app/views/event_mailer/attendance_confirmed.text.erb`
- `app/views/event_mailer/attendance_cancelled.text.erb`
- `app/views/event_mailer/event_reminder.text.erb`
- `app/views/event_mailer/event_rejected.text.erb`
- `app/views/event_mailer/waitlist_spot_available.text.erb`
- `app/views/event_mailer/initiation_participants_report.text.erb`

**Layout mailer amélioré** :
- `app/views/layouts/mailer.html.erb` : Design cohérent avec l'application

### 3. Configuration ActionMailer

**Développement** (`config/environments/development.rb`) :
- `delivery_method = :smtp` : Envoi via SMTP (configuré avec credentials)
- `raise_delivery_errors = true` : Afficher les erreurs
- `default_url_options = { host: "dev-grenoble-roller.flowtech-lab.org", protocol: "https" }`
- Configuration SMTP : `smtp.ionos.fr` (port 465, SSL)

**Production** (`config/environments/production.rb`) :
- ✅ **CONFIGURÉ** : `delivery_method = :smtp`
- Configuration SMTP complète avec credentials (voir `config/environments/production.rb` lignes 71-82)
- `default_url_options = { host: "grenoble-roller.org", protocol: "https" }`

**Staging** (`config/environments/staging.rb`) :
- ✅ **CONFIGURÉ** : Même configuration que production
- `default_url_options = { host: "grenoble-roller.flowtech-lab.org", protocol: "https" }`

### 4. Intégration dans les contrôleurs

**Contrôleurs utilisant EventMailer** :

**`app/controllers/events_controller.rb`** :
- `reject` : Envoie `event_rejected` après refus d'un événement

**`app/controllers/events/attendances_controller.rb`** :
- Inscription : Envoie `attendance_confirmed` si `current_user.wants_events_mail?`
- Désinscription : Envoie `attendance_cancelled` si `current_user.wants_events_mail?`

**`app/controllers/initiations/attendances_controller.rb`** :
- Inscription : Envoie `attendance_confirmed` si `current_user.wants_initiation_mail?`
- Désinscription : Envoie `attendance_cancelled` si `current_user.wants_initiation_mail?`

**`app/controllers/events/waitlist_entries_controller.rb`** :
- Confirmation place : Envoie `attendance_confirmed` si `current_user.wants_events_mail?`

**`app/controllers/initiations/waitlist_entries_controller.rb`** :
- Confirmation place : Envoie `attendance_confirmed` si `current_user.wants_initiation_mail?`

**`app/models/waitlist_entry.rb`** :
- `send_notification_email` : Envoie `waitlist_spot_available` avec `deliver_now` (time-sensitive, 24h pour confirmer)

**`app/jobs/initiation_participants_report_job.rb`** :
- Envoie `initiation_participants_report` à 7h le jour de l'initiation

**Utilisation de `deliver_later`** :
- Les emails sont envoyés de manière asynchrone via Active Job (Solid Queue)
- Exception : `waitlist_spot_available` utilise `deliver_now` (notification time-sensitive)
- Pas de blocage de la requête HTTP

**Préférences utilisateur** :
- `wants_events_mail?` : Contrôle l'envoi d'emails pour les événements normaux
- `wants_initiation_mail?` : Contrôle l'envoi d'emails pour les initiations
- `wants_reminder?` : Contrôle l'envoi des rappels 24h avant (dans `EventReminderJob`)

### 5. Tests RSpec

**Fichier** : `spec/mailers/event_mailer_spec.rb`

**Couverture actuelle** :
- Tests pour `attendance_confirmed` (8 exemples) ✅
- Tests pour `attendance_cancelled` (5 exemples) ✅
- Tests pour `event_reminder` (3 exemples) ✅
- Tests avec routes, prix, max_participants ✅

**Tests manquants** :
- ⚠️ `event_rejected` : Pas de tests
- ⚠️ `waitlist_spot_available` : Pas de tests
- ⚠️ `initiation_participants_report` : Pas de tests

---

## 📋 Contenu des Emails

### Email de Confirmation d'Inscription

**Sujet** :
- Événement normal : `✅ Inscription confirmée : [Titre de l'événement]`
- Initiation : `✅ Inscription confirmée - Initiation roller samedi [Date]` (format spécial avec date formatée)

**Contenu** :
- Salutation personnalisée avec le prénom
- Titre de l'événement
- Détails de l'événement :
  - Lieu
  - Date (format français)
  - Durée
  - Prix (si applicable)
  - Parcours (si applicable)
  - Nombre de participants / limite (si applicable)
- Lien vers la page de l'événement
- Rappel : Possibilité d'annuler l'inscription

### Email de Confirmation de Désinscription

**Sujet** :
- Événement normal : `❌ Désinscription confirmée : [Titre de l'événement]`
- Initiation : `❌ Désinscription confirmée - Initiation roller samedi [Date]` (format spécial avec date formatée)

**Contenu** :
- Salutation personnalisée avec le prénom
- Titre de l'événement
- Détails de l'événement :
  - Lieu
  - Date (format français)
  - Durée
- Lien vers la page de l'événement
- Rappel : Possibilité de se réinscrire

---

## 🎨 Design des Emails

### Layout Mailer

**Caractéristiques** :
- Design responsive (mobile-first)
- Couleurs cohérentes avec l'application (Bootstrap colors)
- Header avec logo "Grenoble Roller"
- Footer avec informations de l'association
- Styles inline pour compatibilité email clients

### Templates HTML

**Structure** :
- Titre avec emoji
- Section détails avec fond coloré et bordure
- Tableau pour les informations (meilleure compatibilité)
- Bouton d'action (lien vers l'événement)
- Rappels et informations supplémentaires

### Templates Texte

**Structure** :
- Titre en majuscules
- Séparateurs visuels (`─────────────────────────`)
- Informations formatées de manière lisible
- Lien vers l'événement

---

## 📧 Emails Supplémentaires

### Email de Refus d'Événement (`event_rejected`)

**Sujet** :
- Événement normal : `❌ Votre événement "[Titre]" a été refusé`
- Initiation : `❌ Votre initiation a été refusée`

**Déclencheur** : Refus d'un événement par un modérateur/admin  
**Destinataire** : Créateur de l'événement  
**Appel** : `app/controllers/events_controller.rb` ligne 240

### Email de Place Disponible (`waitlist_spot_available`)

**Sujet** :
- Événement normal : `🎉 Place disponible : [Titre]`
- Initiation : `🎉 Place disponible - Initiation roller samedi [Date]`

**Déclencheur** : Une place se libère dans un événement complet  
**Destinataire** : Premier utilisateur en liste d'attente  
**Appel** : `app/models/waitlist_entry.rb` ligne 290 (via `send_notification_email`)  
**⚠️ Important** : Utilise `deliver_now` (pas `deliver_later`) car notification time-sensitive (24h pour confirmer)  
**Contenu** : Lien de confirmation avec token sécurisé, délai de 24h

### Email de Rapport Participants (`initiation_participants_report`)

**Sujet** : `📋 Rapport participants - Initiation [Date]`

**Déclencheur** : Job `InitiationParticipantsReportJob` exécuté à 7h le jour de l'initiation  
**Destinataire** : `contact@grenoble-roller.org`  
**Contenu** : Liste des participants actifs avec matériel demandé (taille de rollers)

---

## 🔧 Configuration et Utilisation

### Développement

**Configuration** : SMTP activé (même configuration que production mais avec credentials de dev)

**Test manuel** :
```ruby
# Rails console
user = User.first
event = Event.first
attendance = Attendance.create!(user: user, event: event, status: 'registered')

# Envoyer l'email
EventMailer.attendance_confirmed(attendance).deliver_now

# Vérifier les logs ou la boîte email configurée
```

### Production

**Configuration SMTP** : ✅ **DÉJÀ CONFIGURÉ**

**Fichier** : `config/environments/production.rb` (lignes 71-82)

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  user_name: Rails.application.credentials.dig(:smtp, :user_name),
  password: Rails.application.credentials.dig(:smtp, :password),
  address: Rails.application.credentials.dig(:smtp, :address) || "smtp.ionos.fr",
  port: Rails.application.credentials.dig(:smtp, :port) || 465,
  domain: Rails.application.credentials.dig(:smtp, :domain) || "grenoble-roller.org",
  authentication: :plain,
  enable_starttls_auto: false,
  ssl: true,
  openssl_verify_mode: "peer"
}
```

**Credentials** : Configurés via `rails credentials:edit` sous la clé `:smtp`

---

## 🧪 Tests

### Tests RSpec

**Exécution** :
```bash
# Tous les tests mailers
bundle exec rspec spec/mailers/

# Tests spécifiques
bundle exec rspec spec/mailers/event_mailer_spec.rb
```

**Couverture** :
- ✅ Envoi à la bonne adresse email
- ✅ Sujet correct
- ✅ Contenu correct (titre, détails, liens)
- ✅ Cas particuliers (route, prix, max_participants)

### Tests d'Intégration

**À faire** (dans les tests Capybara) :
- Vérifier que l'email est envoyé après inscription
- Vérifier que l'email est envoyé après désinscription
- Vérifier le contenu de l'email (si possible)

---

## 🚀 Prochaines Étapes

### ✅ Déjà Implémenté

1. **Email de rappel 24h avant** : ✅ **IMPLÉMENTÉ**
   - Job `EventReminderJob` créé (`app/jobs/event_reminder_job.rb`)
   - Planifié via `config/recurring.yml` (Solid Queue) - Tous les jours à 19h
   - Template `event_reminder.html.erb` créé
   - Respecte les préférences utilisateur (`wants_reminder?`, `wants_initiation_mail?`)

2. **Préférences utilisateur** : ✅ **IMPLÉMENTÉ**
   - `wants_events_mail?` : Contrôle emails événements normaux
   - `wants_initiation_mail?` : Contrôle emails initiations
   - `wants_reminder?` : Contrôle rappels 24h avant
   - Formulaire dans `app/views/devise/registrations/edit.html.erb`

### Optionnel (Pour plus tard)

1. **Email à l'organisateur** :
   - Notification quand quelqu'un s'inscrit
   - Notification quand quelqu'un se désinscrit

2. **Email de confirmation de paiement** :
   - Si l'événement est payant
   - Intégration avec le système de paiement

3. **Personnalisation avancée** :
   - Templates avec images
   - Signature personnalisée

---

## 📊 Statistiques

### Fichiers créés/modifiés

**Créés** :
- `app/mailers/event_mailer.rb`
- `app/views/event_mailer/attendance_confirmed.html.erb`
- `app/views/event_mailer/attendance_confirmed.text.erb`
- `app/views/event_mailer/attendance_cancelled.html.erb`
- `app/views/event_mailer/attendance_cancelled.text.erb`
- `app/views/event_mailer/event_reminder.html.erb`
- `app/views/event_mailer/event_reminder.text.erb`
- `app/views/event_mailer/event_rejected.html.erb`
- `app/views/event_mailer/event_rejected.text.erb`
- `app/views/event_mailer/waitlist_spot_available.html.erb`
- `app/views/event_mailer/waitlist_spot_available.text.erb`
- `app/views/event_mailer/initiation_participants_report.html.erb`
- `app/views/event_mailer/initiation_participants_report.text.erb`
- `spec/mailers/event_mailer_spec.rb`
- `app/jobs/event_reminder_job.rb`
- `app/jobs/initiation_participants_report_job.rb`

**Modifiés** :
- `app/mailers/application_mailer.rb` (email expéditeur)
- `app/controllers/events_controller.rb` (intégration mailer)
- `app/controllers/events/attendances_controller.rb` (emails avec préférences)
- `app/controllers/initiations/attendances_controller.rb` (emails avec préférences)
- `app/controllers/events/waitlist_entries_controller.rb` (emails avec préférences)
- `app/controllers/initiations/waitlist_entries_controller.rb` (emails avec préférences)
- `app/models/waitlist_entry.rb` (notification place disponible)
- `app/views/layouts/mailer.html.erb` (design amélioré)
- `config/environments/development.rb` (configuration ActionMailer SMTP)
- `config/environments/production.rb` (configuration ActionMailer SMTP)
- `config/environments/staging.rb` (configuration ActionMailer SMTP)
- `config/recurring.yml` (planification EventReminderJob)

### Tests

**Exemples de tests** : 15 exemples (dans `spec/mailers/event_mailer_spec.rb`)
- `attendance_confirmed` : 8 exemples ✅
- `attendance_cancelled` : 5 exemples ✅
- `event_reminder` : 3 exemples ✅
- `event_rejected` : 0 exemples ⚠️
- `waitlist_spot_available` : 0 exemples ⚠️
- `initiation_participants_report` : 0 exemples ⚠️

---

## ✅ Checklist

### Implémentation de Base
- [x] Mailer créé (`EventMailer`)
- [x] Templates HTML créés (6 méthodes)
- [x] Templates texte créés (6 méthodes)
- [x] Layout mailer amélioré
- [x] Configuration ActionMailer (dev/staging/production)
- [x] Intégration dans contrôleurs (5 contrôleurs)
- [x] Tests RSpec créés (15 exemples pour 3 méthodes)
- [x] Documentation créée

### Fonctionnalités Avancées
- [x] Configuration SMTP (production/staging/dev) ✅
- [x] Job de rappel 24h avant (`EventReminderJob`) ✅
- [x] Préférences utilisateur (`wants_events_mail?`, `wants_initiation_mail?`, `wants_reminder?`) ✅
- [x] Email de refus (`event_rejected`) ✅
- [x] Email liste d'attente (`waitlist_spot_available`) ✅
- [x] Email rapport participants (`initiation_participants_report`) ✅
- [x] Planification jobs (Solid Queue `config/recurring.yml`) ✅

### À Améliorer
- [ ] Tests d'intégration Capybara - À faire
- [ ] Tests RSpec pour `event_rejected` - À faire
- [ ] Tests RSpec pour `waitlist_spot_available` - À faire
- [ ] Tests RSpec pour `initiation_participants_report` - À faire
- [ ] Email à l'organisateur (inscription/désinscription) - Optionnel
- [ ] Email de confirmation de paiement - Optionnel

---

**Document créé le** : Novembre 2025  
**Dernière mise à jour** : Décembre 2025  
**Version** : 2.0

