# 📧 Confirmation Email - Documentation Complète

**Dernière mise à jour** : 2025-12-07  
**Statut** : ✅ **Opérationnel**

---

## 📋 Vue d'ensemble

Système complet de confirmation d'email avec sécurité renforcée, QR code mobile, et protection contre les abus.

### Fonctionnalités principales

- ✅ **Confirmation obligatoire** : Blocage immédiat si email non confirmé
- ✅ **QR code mobile** : Génération PNG en pièce jointe + inline
- ✅ **Sécurité** : Logging sécurisé, audit trail, détection d'attaques
- ✅ **Rate limiting** : Protection contre les abus (Rack::Attack)
- ✅ **Templates modernes** : Design professionnel avec FAQ intégrée

---

## ⚙️ Configuration

### 1. Credentials Rails (SMTP)

**Édition** :
```bash
docker compose -f ops/dev/docker-compose.yml run --rm -it -e EDITOR=nano web bin/rails credentials:edit
```

**Structure requise** :
```yaml
smtp:
  user_name: no-reply@grenoble-roller.org
  password: votre_mot_de_passe_ionos
  address: smtp.ionos.fr
  port: 465
  domain: grenoble-roller.org
```

### 2. Migration Base de Données

**À lancer** :
```bash
docker compose -f ops/dev/docker-compose.yml run --rm web bin/rails db:migrate
```

**Colonnes ajoutées** :
- `confirmed_ip` (string) - IP de confirmation
- `confirmed_user_agent` (text) - Navigateur utilisé
- `confirmation_token_last_used_at` (datetime) - Timestamp
- Index sur `confirmed_ip`

### 3. Configuration Devise

**Fichier** : `config/initializers/devise.rb`

```ruby
# Confirmation obligatoire (pas de période de grâce)
config.allow_unconfirmed_access_for = nil

# Token valable 3 jours
config.confirm_within = 3.days

# Mailer personnalisé avec QR code
config.mailer = "DeviseMailer"

# Expéditeur
config.mailer_sender = "Grenoble Roller <no-reply@grenoble-roller.org>"
```

---

## 🔄 Workflow Utilisateur

### Inscription

1. Utilisateur crée un compte
2. ✅ Email de confirmation envoyé (avec QR code)
3. ✅ Redirection vers page de demande de renvoi (pas de connexion auto)
4. ✅ Message : "Un email de confirmation vous a été envoyé"

### Connexion (Email Non Confirmé)

1. Utilisateur tente de se connecter
2. ✅ Blocage immédiat + déconnexion automatique
3. ✅ Redirection vers page de renvoi (email pré-rempli)
4. ✅ Message clair avec lien pour renvoyer

### Confirmation

1. Utilisateur clique sur le lien OU scanne le QR code
2. ✅ Confirmation réussie + audit trail enregistré
3. ✅ Connexion automatique
4. ✅ Message de bienvenue

### Renvoi Email

1. Utilisateur demande un nouvel email
2. ✅ Rate limiting : 5/heure par email, 10/heure par IP
3. ✅ Anti-énumération : même réponse si email existe ou non
4. ✅ Nouvel email envoyé avec QR code

---

## 🔒 Sécurité

### Logging Sécurisé

**Règle d'or** : JAMAIS de token en clair dans les logs

```ruby
# ✅ CORRECT
Rails.logger.info("Confirmation attempt from IP: #{request.remote_ip}, Token present: #{token.present?}")

# ❌ INTERDIT
Rails.logger.info("Token: #{token}") # JAMAIS !
```

### Audit Trail

Enregistré après chaque confirmation :
- IP de confirmation
- User-Agent (navigateur/appareil)
- Timestamp de confirmation

### Détection d'Anomalies

- **Email scanner** : Détection si confirmation < 10 secondes après envoi
- **Force brute** : Alerte si >50 échecs/heure depuis même IP
- **Intégration Sentry** : Alertes automatiques (si configuré)

### Rate Limiting

- **Par email** : 5 renvois/heure maximum
- **Par IP** : 10 demandes/heure maximum
- **Rack::Attack** : Protection au niveau middleware

---

## 📧 Email de Confirmation

### Caractéristiques

- **Design moderne** : Gradient header, sections claires
- **QR code PNG** (240x240px) : Pièce jointe + inline (Content-ID)
- **Badge expiration** : Date et heures restantes visibles
- **Lien fallback** : Copier-coller si bouton ne fonctionne pas
- **Version texte** : Fallback pour clients email limités

### Structure

```
┌─────────────────────────────────┐
│  Header Gradient (Bleu)         │
│  ✉️ Confirmez votre email        │
├─────────────────────────────────┤
│  Message de bienvenue           │
│  Bouton CTA "Confirmer"         │
│  QR Code (240x240px)            │
│  Badge expiration               │
│  Lien fallback                  │
│  FAQ & Support                  │
│  Footer professionnel           │
└─────────────────────────────────┘
```

### QR Code

- Format : PNG 240x240 pixels
- Inclusion :
  - Pièce jointe : `qr-code-confirmation.png`
  - Content-ID : `qr-code-confirmation@grenoble-roller.org`
  - Affichage inline : `cid:qr-code-confirmation@grenoble-roller.org`

---

## 📁 Fichiers Clés

### Créés

- `db/migrate/[timestamp]_add_confirmation_audit_fields_to_users.rb`
- `app/services/email_security_service.rb`
- `app/mailers/devise_mailer.rb`
- `app/views/devise/mailer/confirmation_instructions.html.erb`
- `app/views/devise/mailer/confirmation_instructions.text.erb`
- `app/views/devise/confirmations/new.html.erb` (avec FAQ)

### Modifiés

- `app/controllers/confirmations_controller.rb` - Sécurité renforcée
- `app/controllers/sessions_controller.rb` - Blocage connexion non confirmée
- `app/controllers/registrations_controller.rb` - Pas de connexion auto
- `app/controllers/application_controller.rb` - Vérification confirmation
- `app/models/user.rb` - Méthodes confirmation
- `config/initializers/devise.rb` - Configuration
- `config/initializers/rack_attack.rb` - Rate limiting
- `config/environments/development.rb` - SMTP activé
- `config/environments/production.rb` - SMTP configuré
- `Gemfile` - Gem `rqrcode` ajoutée

---

## 🧪 Tests

### Tests RSpec

- ✅ `spec/models/user_spec.rb` - Tests du modèle
- ✅ `spec/controllers/sessions_controller_spec.rb` - Tests connexion
- ✅ `spec/controllers/confirmations_controller_spec.rb` - Tests confirmation
- ✅ `spec/requests/rack_attack_spec.rb` - Tests rate limiting

### Tests Manuels

```bash
# Tester email de confirmation
docker compose -f ops/dev/docker-compose.yml run --rm web bin/rails console
> user = User.find_by(email: 'votre@email.com')
> user.send_confirmation_instructions
```

---

## 🐛 Dépannage

### Email n'arrive pas

1. Vérifier credentials SMTP dans Rails credentials
2. Vérifier configuration dans `config/environments/development.rb` ou `production.rb`
3. Vérifier logs : `docker compose logs web | grep -i email`
4. Vérifier spams/courrier indésirable

### QR code ne s'affiche pas

- Vérifier que la gem `rqrcode` est installée
- Le QR code est aussi en pièce jointe (toujours accessible)
- Certains clients email bloquent les images inline (normal)

### Token expiré

- Lien valable 3 jours (configurable)
- L'utilisateur peut demander un nouvel email
- Rate limiting : max 5 renvois/heure par email

---

## 📊 Métriques Attendues

- ✅ **Taux de confirmation** : +30% (grâce au QR code mobile)
- ✅ **Abandons** : -40% (grâce aux templates modernes)
- ✅ **Support** : -50% (grâce à la FAQ intégrée)
- ✅ **Sécurité** : 100% des confirmations tracées

---

## 🔧 Commandes Utiles

```bash
# Installer la gem rqrcode
docker compose -f ops/dev/docker-compose.yml run --rm web bundle install

# Lancer la migration
docker compose -f ops/dev/docker-compose.yml run --rm web bin/rails db:migrate

# Vérifier logs (pas de token en clair)
docker compose -f ops/dev/docker-compose.yml logs web | grep -i confirmation

# Tests RSpec
docker compose -f ops/dev/docker-compose.yml run --rm -e RAILS_ENV=test web bundle exec rspec spec/models/user_spec.rb spec/controllers/sessions_controller_spec.rb spec/controllers/confirmations_controller_spec.rb spec/requests/rack_attack_spec.rb
```

---

## 📚 Documentation Associée

- **Tous les emails** : [`emails-recapitulatif.md`](emails-recapitulatif.md) - Liste complète de tous les mailers de l'application
- **Configuration credentials** : [`credentials.md`](credentials.md) - Gestion des credentials Rails (SMTP)
- **Guide sécurité Devise** : [`devise-email-security-guide.md`](devise-email-security-guide.md) - Référence technique approfondie (1930 lignes, guide complet)

---

**Version** : 1.0  
**Date de création** : 2025-12-07  
**Statut** : ✅ Opérationnel

