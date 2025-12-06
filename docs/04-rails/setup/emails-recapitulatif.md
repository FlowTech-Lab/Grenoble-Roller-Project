# 📧 Récapitulatif Complet des Emails - Grenoble Roller

**Date de création** : 2025-01-20  
**Dernière mise à jour** : 2025-01-20

---

## 📋 Liste Complète des Mailers

### 1. **UserMailer** - Emails utilisateurs

| Méthode | Sujet | Déclencheur | Template HTML | Template Texte | Status |
|---------|-------|-------------|---------------|----------------|--------|
| `welcome_email(user)` | `🎉 Bienvenue chez Grenoble Roller!` | Inscription d'un nouvel utilisateur | ✅ `welcome_email.html.erb` | ✅ `welcome_email.text.erb` | ✅ **Configuré** |

**Où est appelé** :
- `app/models/user.rb` ligne 104 : Après création du compte

---

### 2. **EventMailer** - Emails événements

| Méthode | Sujet | Déclencheur | Template HTML | Template Texte | Status |
|---------|-------|-------------|---------------|----------------|--------|
| `attendance_confirmed(attendance)` | `✅ Inscription confirmée : [Titre]` | Inscription à un événement | ✅ `attendance_confirmed.html.erb` | ✅ `attendance_confirmed.text.erb` | ✅ **Configuré** |
| `attendance_cancelled(user, event)` | `❌ Désinscription confirmée : [Titre]` | Désinscription d'un événement | ✅ `attendance_cancelled.html.erb` | ✅ `attendance_cancelled.text.erb` | ✅ **Configuré** |
| `event_reminder(attendance)` | `📅 Rappel : [Titre] demain !` | 24h avant l'événement (job) | ✅ `event_reminder.html.erb` | ✅ `event_reminder.text.erb` | ✅ **Configuré** |

**Où sont appelés** :
- `app/controllers/events_controller.rb` ligne 106 : `attendance_confirmed` après inscription
- `app/controllers/events_controller.rb` ligne 120 : `attendance_cancelled` après désinscription
- `app/jobs/event_reminder_job.rb` ligne 27 : `event_reminder` (job planifié)

---

### 3. **OrderMailer** - Emails commandes

| Méthode | Sujet | Déclencheur | Template HTML | Template Texte | Status |
|---------|-------|-------------|---------------|----------------|--------|
| `order_confirmation(order)` | `✅ Commande #X - Confirmation de commande` | Création commande (pending) | ✅ `order_confirmation.html.erb` | ❌ **MANQUANT** | ⚠️ **Partiel** |
| `order_paid(order)` | `💳 Commande #X - Paiement confirmé` | Statut → `paid` | ✅ `order_paid.html.erb` | ❌ **MANQUANT** | ⚠️ **Partiel** |
| `order_cancelled(order)` | `❌ Commande #X - Commande annulée` | Statut → `cancelled` | ✅ `order_cancelled.html.erb` | ❌ **MANQUANT** | ⚠️ **Partiel** |
| `order_preparation(order)` | `⚙️ Commande #X - En préparation` | Statut → `preparation` | ✅ `order_preparation.html.erb` | ❌ **MANQUANT** | ⚠️ **Partiel** |
| `order_shipped(order)` | `📦 Commande #X - Expédiée` | Statut → `shipped` | ✅ `order_shipped.html.erb` | ❌ **MANQUANT** | ⚠️ **Partiel** |
| `refund_requested(order)` | `🔄 Commande #X - Demande de remboursement en cours` | Statut → `refund_requested` | ✅ `refund_requested.html.erb` | ❌ **MANQUANT** | ⚠️ **Partiel** |
| `refund_confirmed(order)` | `✅ Commande #X - Remboursement confirmé` | Statut → `refunded` | ✅ `refund_confirmed.html.erb` | ❌ **MANQUANT** | ⚠️ **Partiel** |

**Où sont appelés** :
- `app/controllers/orders_controller.rb` ligne 57 : `order_confirmation` après création
- `app/models/order.rb` lignes 64-74 : Tous les autres via callback `after_update :notify_status_change`

**⚠️ PROBLÈME** : Les templates texte (`.text.erb`) sont **MANQUANTS** pour tous les emails OrderMailer !

---

### 4. **MembershipMailer** - Emails adhésions

| Méthode | Sujet | Déclencheur | Template HTML | Template Texte | Status |
|---------|-------|-------------|---------------|----------------|--------|
| `activated(membership)` | `✅ Adhésion Saison [X] - Bienvenue !` | Adhésion activée (paiement confirmé) | ✅ `activated.html.erb` | ✅ `activated.text.erb` | ✅ **Configuré** |
| `expired(membership)` | `⏰ Adhésion Saison [X] - Expirée` | Adhésion expirée (tâche cron) | ✅ `expired.html.erb` | ✅ `expired.text.erb` | ✅ **Configuré** |
| `renewal_reminder(membership)` | `🔄 Renouvellement d'adhésion - Dans 30 jours` | Rappel 30j avant expiration (tâche cron) | ✅ `renewal_reminder.html.erb` | ✅ `renewal_reminder.text.erb` | ✅ **Configuré** |
| `payment_failed(membership)` | `❌ Paiement adhésion Saison [X] - Échec` | Échec de paiement HelloAsso | ✅ `payment_failed.html.erb` | ✅ `payment_failed.text.erb` | ✅ **Configuré** |

**Où sont appelés** :
- `app/models/membership.rb` ligne 165 : `activated` après activation
- `app/services/helloasso_service.rb` lignes 413, 425 : `payment_failed` en cas d'échec
- `lib/tasks/memberships.rake` lignes 15, 34 : `expired` et `renewal_reminder` (tâches cron)

---

## ✅ Configuration SMTP

### Credentials Rails (à configurer)

**Commande pour éditer** :
```bash
docker compose -f ops/dev/docker-compose.yml run --rm -it -e EDITOR=nano web bin/rails credentials:edit
```

**Structure YAML à ajouter** :
```yaml
smtp:
  user_name: no-reply@grenoble-roller.org
  password: votre_mot_de_passe_ionos
  address: smtp.ionos.fr
  port: 465
  domain: grenoble-roller.org
```

### Configuration par environnement

#### ✅ Développement (`config/environments/development.rb`)
- **Méthode** : `:file` (stockage dans `tmp/mails/`)
- **Host** : `localhost:3000`
- **Status** : ✅ **Configuré**

#### ✅ Production (`config/environments/production.rb`)
- **Méthode** : `:smtp` (IONOS)
- **Host** : ⚠️ **À corriger** (actuellement `"example.com"`)
- **SMTP Settings** : ✅ **Configuré** (utilise les credentials Rails)
- **Status** : ⚠️ **Partiel** (host à corriger)

#### ✅ Test (`config/environments/test.rb`)
- **Méthode** : `:test` (accumulation dans `ActionMailer::Base.deliveries`)
- **Status** : ✅ **Configuré**

---

## 📊 Statistiques Globales

### Résumé par Mailer

| Mailer | Nombre d'emails | Templates HTML | Templates Texte | Status Global |
|--------|----------------|----------------|-----------------|---------------|
| **UserMailer** | 1 | ✅ 1/1 | ✅ 1/1 | ✅ **100%** |
| **EventMailer** | 3 | ✅ 3/3 | ✅ 3/3 | ✅ **100%** |
| **OrderMailer** | 7 | ✅ 7/7 | ❌ 0/7 | ⚠️ **50%** |
| **MembershipMailer** | 4 | ✅ 4/4 | ✅ 4/4 | ✅ **100%** |
| **TOTAL** | **15** | ✅ **15/15** | ⚠️ **11/15** | ⚠️ **73%** |

### Résumé par Type

| Type | Compteur |
|------|----------|
| ✅ **Emails complets** (HTML + Texte) | 11 |
| ⚠️ **Emails partiels** (HTML seulement) | 4 |
| ❌ **Emails manquants** | 0 |

---

## ⚠️ Points d'Attention / Actions Requises

### 🔴 Priorité Haute

1. **❌ Templates texte manquants pour OrderMailer**
   - 7 fichiers `.text.erb` à créer
   - Fichiers concernés :
     - `order_confirmation.text.erb`
     - `order_paid.text.erb`
     - `order_cancelled.text.erb`
     - `order_preparation.text.erb`
     - `order_shipped.text.erb`
     - `refund_requested.text.erb`
     - `refund_confirmed.text.erb`

2. **⚠️ Host à corriger en production**
   - `config/environments/production.rb` ligne 60
   - Actuellement : `host: "example.com"`
   - À remplacer par : `host: "grenoble-roller.org"` (ou le vrai domaine)

### 🟡 Priorité Moyenne

3. **Vérifier que tous utilisent `deliver_later`**
   - ✅ UserMailer : `deliver_later` (ligne 104 user.rb)
   - ✅ EventMailer : `deliver_later` (tous les appels)
   - ✅ OrderMailer : `deliver_later` (tous les appels)
   - ✅ MembershipMailer : `deliver_later` (sauf dans rake tasks qui utilisent `deliver_now`)

### 🟢 Priorité Basse / Améliorations

4. **Considérer créer des versions texte pour meilleure compatibilité email**
   - Les clients email modernes supportent HTML, mais certaines boîtes de réception d'entreprise filtrent le HTML
   - Les versions texte sont un fallback important

5. **Vérifier les templates HTML pour compatibilité email**
   - Tester sur différents clients (Gmail, Outlook, Apple Mail)
   - Utiliser des styles inline pour compatibilité

---

## 🧪 Tests

### Script de Test

Un script de test SMTP a été créé : `bin/test-mailer`

**Usage** :
```bash
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle exec ruby bin/test-mailer votre-email@example.com
```

### Tests RSpec

**Fichiers de tests existants** :
- ✅ `spec/mailers/user_mailer_spec.rb`
- ✅ `spec/mailers/event_mailer_spec.rb`
- ✅ `spec/mailers/membership_mailer_spec.rb`
- ❌ `spec/mailers/order_mailer_spec.rb` - **MANQUANT**

---

## 📚 Documentation Associée

- **Emails Événements** : `docs/06-events/email-notifications-implementation.md`
- **Emails Commandes** : `docs/09-product/orders-workflow-emails.md`
- **Credentials Rails** : `docs/04-rails/setup/credentials.md`

---

## ✅ Checklist de Configuration

### Configuration SMTP
- [x] Credentials SMTP ajoutés dans Rails credentials
- [x] Configuration SMTP dans `production.rb`
- [x] Configuration file storage dans `development.rb`
- [x] Configuration test dans `test.rb`
- [ ] **Host corrigé dans `production.rb`** ⚠️

### Mailers
- [x] ApplicationMailer configuré avec bonne adresse `from`
- [x] UserMailer : ✅ Complet
- [x] EventMailer : ✅ Complet
- [x] MembershipMailer : ✅ Complet
- [ ] **OrderMailer : Templates texte à créer** ⚠️

### Tests
- [x] Script de test SMTP créé (`bin/test-mailer`)
- [x] Tests RSpec pour UserMailer
- [x] Tests RSpec pour EventMailer
- [x] Tests RSpec pour MembershipMailer
- [ ] **Tests RSpec pour OrderMailer** ⚠️

---

**Dernière vérification** : 2025-01-20  
**Prochaine révision recommandée** : Après ajout des templates texte OrderMailer
