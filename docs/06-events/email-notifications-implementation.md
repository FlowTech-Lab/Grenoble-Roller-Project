# 📧 Notifications E-mail - Implémentation

**Document** : Documentation de l'implémentation des notifications e-mail pour les événements  
**Date** : Novembre 2025  
**Version** : 1.0

---

## ✅ Implémentation Complète

### 1. Mailer créé : `EventMailer`

**Fichier** : `app/mailers/event_mailer.rb`

**Méthodes** :
- `attendance_confirmed(attendance)` : Email de confirmation d'inscription
- `attendance_cancelled(user, event)` : Email de confirmation de désinscription
- `event_reminder(attendance)` : Email de rappel (optionnel, pour plus tard)

### 2. Templates d'emails

**Templates HTML** :
- `app/views/event_mailer/attendance_confirmed.html.erb`
- `app/views/event_mailer/attendance_cancelled.html.erb`

**Templates texte** :
- `app/views/event_mailer/attendance_confirmed.text.erb`
- `app/views/event_mailer/attendance_cancelled.text.erb`

**Layout mailer amélioré** :
- `app/views/layouts/mailer.html.erb` : Design cohérent avec l'application

### 3. Configuration ActionMailer

**Développement** (`config/environments/development.rb`) :
- `delivery_method = :file` : Stockage des emails dans `tmp/mails/`
- `raise_delivery_errors = true` : Afficher les erreurs
- `default_url_options = { host: "localhost", port: 3000 }`

**Production** (`config/environments/production.rb`) :
- À configurer avec les credentials SMTP (voir commentaires dans le fichier)

### 4. Intégration dans le contrôleur

**Fichier** : `app/controllers/events_controller.rb`

**Méthodes modifiées** :
- `attend` : Envoie un email de confirmation après inscription
- `cancel_attendance` : Envoie un email de confirmation après désinscription

**Utilisation de `deliver_later`** :
- Les emails sont envoyés de manière asynchrone via Active Job
- Pas de blocage de la requête HTTP

### 5. Tests RSpec

**Fichier** : `spec/mailers/event_mailer_spec.rb`

**Couverture** :
- Tests pour `attendance_confirmed` (8 exemples)
- Tests pour `attendance_cancelled` (5 exemples)
- Tests pour `event_reminder` (3 exemples)
- Tests avec routes, prix, max_participants

---

## 📋 Contenu des Emails

### Email de Confirmation d'Inscription

**Sujet** : `✅ Inscription confirmée : [Titre de l'événement]`

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

**Sujet** : `❌ Désinscription confirmée : [Titre de l'événement]`

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

## 🔧 Configuration et Utilisation

### Développement

**Visualisation des emails** :
1. Les emails sont stockés dans `tmp/mails/`
2. Ouvrir les fichiers `.html` dans un navigateur
3. Ou utiliser un outil comme `letter_opener` (optionnel)

**Test manuel** :
```ruby
# Rails console
user = User.first
event = Event.first
attendance = Attendance.create!(user: user, event: event, status: 'registered')

# Envoyer l'email
EventMailer.attendance_confirmed(attendance).deliver_now

# Vérifier dans tmp/mails/
```

### Production

**Configuration SMTP** (à faire) :
```ruby
# config/environments/production.rb
config.action_mailer.smtp_settings = {
  user_name: Rails.application.credentials.dig(:smtp, :user_name),
  password: Rails.application.credentials.dig(:smtp, :password),
  address: "smtp.example.com",
  port: 587,
  authentication: :plain
}
```

**Credentials** :
```bash
# Ajouter les credentials SMTP
rails credentials:edit
```

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

### Optionnel (Pour plus tard)

1. **Email de rappel 24h avant** :
   - Job `EventReminderJob` (à créer)
   - Planification avec `whenever` ou `sidekiq-cron`
   - Template `event_reminder.html.erb` (déjà créé)

2. **Email à l'organisateur** :
   - Notification quand quelqu'un s'inscrit
   - Notification quand quelqu'un se désinscrit

3. **Email de confirmation de paiement** :
   - Si l'événement est payant
   - Intégration avec le système de paiement

4. **Personnalisation avancée** :
   - Templates avec images
   - Signature personnalisée
   - Préférences utilisateur (notification ou non)

---

## 📊 Statistiques

### Fichiers créés/modifiés

**Créés** :
- `app/mailers/event_mailer.rb`
- `app/views/event_mailer/attendance_confirmed.html.erb`
- `app/views/event_mailer/attendance_confirmed.text.erb`
- `app/views/event_mailer/attendance_cancelled.html.erb`
- `app/views/event_mailer/attendance_cancelled.text.erb`
- `spec/mailers/event_mailer_spec.rb`

**Modifiés** :
- `app/mailers/application_mailer.rb` (email expéditeur)
- `app/controllers/events_controller.rb` (intégration mailer)
- `app/views/layouts/mailer.html.erb` (design amélioré)
- `config/environments/development.rb` (configuration ActionMailer)

### Tests

**Exemples de tests** : 16 exemples
- `attendance_confirmed` : 8 exemples
- `attendance_cancelled` : 5 exemples
- `event_reminder` : 3 exemples

---

## ✅ Checklist

- [x] Mailer créé (`EventMailer`)
- [x] Templates HTML créés
- [x] Templates texte créés
- [x] Layout mailer amélioré
- [x] Configuration ActionMailer (dev)
- [x] Intégration dans `EventsController`
- [x] Tests RSpec créés
- [x] Documentation créée
- [ ] Configuration SMTP (production) - À faire
- [ ] Tests d'intégration Capybara - À faire
- [ ] Job de rappel 24h avant - Optionnel

---

**Document créé le** : Novembre 2025  
**Dernière mise à jour** : Novembre 2025  
**Version** : 1.0

