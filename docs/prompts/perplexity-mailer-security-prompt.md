# Prompt Perplexity - Sécurité Mailer & Confirmation Email Devise

**⚠️ STATUS : OBSOLÈTE**

Ce prompt a été utilisé pour générer le guide complet de sécurité.  
**Voir maintenant** : `docs/04-rails/setup/devise-email-security-guide.md` (guide complet avec toutes les réponses)

Ce fichier est conservé uniquement pour référence historique.

---

**Objectif initial** : Obtenir les meilleures pratiques et solutions de sécurité pour un système de mailer Rails avec confirmation d'email Devise.

---

## CONTEXTE DE L'APPLICATION

### Stack Technique
- **Framework** : Ruby on Rails 8.1
- **Authentification** : Devise avec module `:confirmable`
- **Email** : ActionMailer avec SMTP (IONOS)
- **Environnements** : Development (file storage) + Production (SMTP)
- **ActiveJob** : Utilisation de `deliver_later` pour envoi asynchrone

### Configuration Actuelle

#### Devise Configuration
```ruby
# config/initializers/devise.rb
config.allow_unconfirmed_access_for = 2.days  # Période de grâce
config.reconfirmable = true  # Confirmation nécessaire pour changement d'email
```

#### User Model
```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable
  
  # Période de grâce : permet connexion sans confirmation
  def active_for_authentication?
    super || !confirmed?
  end
  
  after_create :send_welcome_email_and_confirmation
end
```

#### SMTP Configuration (Production)
```ruby
# config/environments/production.rb
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  user_name: Rails.application.credentials.dig(:smtp, :user_name),
  password: Rails.application.credentials.dig(:smtp, :password),
  address: "smtp.ionos.fr",
  port: 465,
  domain: "grenoble-roller.org",
  authentication: :plain,
  enable_starttls_auto: false,
  ssl: true,
  openssl_verify_mode: "peer"
}
```

#### Sécurité Actuelle
```ruby
# app/controllers/application_controller.rb
def ensure_email_confirmed
  return unless user_signed_in?
  return if Rails.env.development? || Rails.env.test?
  
  unless current_user.confirmed?
    redirect_to root_path,
                alert: "Vous devez confirmer votre adresse email...",
                status: :forbidden
  end
end

# Utilisé dans :
# - OrdersController (création commande)
# - EventsController (inscription événement)
```

---

## PROBLÉMATIQUES À RÉSOUDRE

### 1. Gestion Login avec Email Non Confirmé

**Situation actuelle** :
- Période de grâce de 2 jours permet connexion sans confirmation
- Aucun message spécifique au login si email non confirmé
- Aucun lien direct pour renvoyer l'email de confirmation

**Besoin** :
- Détecter si email non confirmé lors du login
- Afficher un message informatif + lien pour renvoyer confirmation
- Gérer le cas où la période de grâce est expirée
- Meilleure UX : ne pas bloquer complètement, mais guider l'utilisateur

### 2. Sécurité Email & Tokens

**Questions de sécurité** :
- Durée de validité du token de confirmation optimal ?
- Protection contre les attaques par force brute sur les tokens ?
- Rate limiting pour les renvois d'email de confirmation ?
- Gestion des tokens expirés / réutilisation ?
- Protection contre l'énumération d'emails (email existe vs n'existe pas) ?

### 3. Bonnes Pratiques Rails/Devise

**À vérifier** :
- Best practices pour la période de grâce (`allow_unconfirmed_access_for`) ?
- Quand doit-on bloquer strictement vs permettre avec restrictions ?
- Gestion des erreurs SMTP (retry logic, queue jobs) ?
- Logging et monitoring des échecs d'envoi email ?
- Templates email : sécurité contre XSS dans les emails ?

### 4. Workflow Complet

**Scénarios à optimiser** :
1. **Inscription** : Email de confirmation envoyé → utilisateur doit cliquer
2. **Login avant confirmation** : Afficher message + option renvoi
3. **Login après expiration période de grâce** : Bloquer ou permettre avec restrictions ?
4. **Renvoi email** : Limiter les abus, gestion des spams
5. **Confirmation** : Gérer les cas d'erreur (token invalide, expiré, déjà utilisé)

---

## QUESTIONS SPÉCIFIQUES POUR PERPLEXITY

### 1. Sécurité & Meilleures Pratiques

> "Quelles sont les meilleures pratiques de sécurité pour la confirmation d'email avec Devise dans Rails 8 ? Inclure : durée de validité des tokens, protection contre les attaques, rate limiting, gestion des erreurs."

### 2. UX & Workflow Login

> "Comment gérer optimalement un utilisateur qui se connecte avec un email non confirmé ? Quelle est la meilleure approche pour : afficher des messages clairs, proposer le renvoi d'email, gérer la période de grâce, et guider l'utilisateur sans bloquer complètement ?"

### 3. Configuration Devise Optimale

> "Quelle configuration Devise `:confirmable` est recommandée pour équilibrer sécurité et UX ? Quand utiliser `allow_unconfirmed_access_for`, comment gérer `confirm_within`, et quelles sont les bonnes pratiques pour `reconfirmable` ?"

### 4. Gestion Erreurs SMTP

> "Comment gérer robustement les erreurs d'envoi d'emails (SMTP) dans Rails avec ActionMailer ? Inclure : retry logic, queue jobs, logging, monitoring, et fallback strategies."

### 5. Protection Anti-Abus

> "Comment protéger contre les abus dans un système de confirmation d'email (spam, énumération, force brute) ? Inclure : rate limiting, validation, captcha si nécessaire, et détection d'anomalies."

### 6. Templates Email Sécurisés

> "Quelles sont les bonnes pratiques de sécurité pour les templates d'email Rails/ActionMailer ? Inclure : protection XSS, validation des URLs, HTTPS, et format texte/HTML."

---

## ÉLÉMENTS À OBTENIR DE PERPLEXITY

### A. Recommandations Configuration

1. **Devise Settings** :
   - Valeur optimale pour `allow_unconfirmed_access_for`
   - Configuration `confirm_within`
   - Stratégie `reconfirmable`

2. **Token Security** :
   - Durée de validité recommandée
   - Méthodes de génération sécurisées
   - Protection contre réutilisation

3. **Rate Limiting** :
   - Configuration Rack::Attack pour renvois email
   - Limites recommandées (par IP, par email)
   - Gestion des dépassements

### B. Code & Implémentation

1. **SessionsController Override** :
   ```ruby
   # Comment détecter email non confirmé au login
   # Comment afficher message + lien renvoi
   # Comment gérer période de grâce expirée
   ```

2. **Custom Failure App** :
   ```ruby
   # Gestion personnalisée des échecs d'authentification
   # Redirection vers page de confirmation
   ```

3. **ConfirmationsController Custom** :
   ```ruby
   # Amélioration du contrôleur Devise
   # Gestion des erreurs (token invalide, expiré)
   # Messages utilisateur clairs
   ```

4. **Rack::Attack Configuration** (déjà présent, à étendre) :
   ```ruby
   # config/initializers/rack_attack.rb existe déjà
   # À ajouter : Rate limiting pour confirmation emails
   # À ajouter : Protection contre énumération emails
   # Voir fichier existant pour pattern
   ```

### C. Monitoring & Logging

1. **Stratégies de logging** :
   - Quels événements logger (tentatives, succès, échecs)
   - Format des logs recommandés
   - Intégration avec monitoring (ex: Sentry)

2. **Alertes** :
   - Quand alerter (échecs répétés, anomalies)
   - Métriques à surveiller

### D. Tests & Validation

1. **Tests recommandés** :
   - Scénarios de test pour confirmation email
   - Tests de sécurité (rate limiting, tokens)
   - Tests d'intégration SMTP

---

## CONTRAINTES & CONTEXTE MÉTIER

### Contraintes Techniques
- **Rails 8.1** : Utiliser les fonctionnalités modernes
- **SMTP IONOS** : Port 465, SSL, authentification plain
- **Production** : Haute disponibilité requise
- **Performance** : Emails envoyés de manière asynchrone (`deliver_later`)

### Contraintes Métier
- **UX importante** : Ne pas bloquer complètement les utilisateurs
- **Sécurité** : Protection contre les abus et attaques
- **Légalité** : Conformité RGPD (gestion des données, consentement)
- **Association** : Communauté locale, besoin d'accessibilité

### Cas d'Usage Spécifiques
1. **Création compte** : Utilisateur reçoit email → doit confirmer
2. **Login sans confirmation** : Guider vers confirmation sans bloquer (2 jours de grâce)
3. **Login après expiration** : Bloquer certaines actions mais permettre navigation
4. **Renvoi email** : Facile mais sécurisé (limitation abus)
5. **Changement email** : Confirmation obligatoire (reconfirmable activé)

---

## RÉSULTAT ATTENDU

### Documentation Complète
- **Guide de configuration** : Paramètres Devise optimaux
- **Code d'implémentation** : Contrôleurs, helpers, configuration
- **Tests** : Scénarios de test complets
- **Checklist sécurité** : Points à vérifier avant mise en production

### Code Prêt à Implémenter
- SessionsController avec gestion email non confirmé
- ConfirmationsController amélioré
- Configuration Rack::Attack
- Helpers pour affichage messages
- Tests RSpec

### Bonnes Pratiques Validées
- Sécurité validée par la communauté Rails/Devise
- UX optimale basée sur standards modernes
- Performance et scalabilité
- Conformité légale (RGPD)

---

## INFORMATIONS SUPPLÉMENTAIRES

### Fichiers Clés du Projet
- `app/models/user.rb` : Modèle User avec confirmable
- `app/controllers/sessions_controller.rb` : Gestion login
- `app/controllers/application_controller.rb` : Sécurité globale
- `config/initializers/devise.rb` : Configuration Devise
- `app/views/devise/mailer/confirmation_instructions.html.erb` : Template email
- `app/views/devise/confirmations/new.html.erb` : Page renvoi email

### Ressources Déjà Consultées
- Documentation Devise : https://github.com/heartcombo/devise
- Rails Guides ActionMailer
- Documentation IONOS SMTP

### Technologies Utilisées
- Rails 8.1, Ruby 3.4
- Devise 4.9+
- ActionMailer, ActiveJob
- SMTP IONOS (port 465, SSL)
- **Rack::Attack** : ✅ Déjà configuré (logins, registrations, password_resets)
  - À ajouter : Rate limiting pour renvois confirmation email

---

**MERCI DE FOURNIR** :
1. Recommandations concrètes et justifiées
2. Code d'implémentation prêt à utiliser
3. Exemples de configuration complets
4. Références aux bonnes pratiques officielles
5. Mise en garde sur les erreurs courantes
6. Checklist de vérification avant production

