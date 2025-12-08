# Guide Complet : Sécurité Email & Confirmation Devise - Rails 8.1

**Version**: 1.0 | **Date**: Décembre 2025 | **Contexte**: Rails 8.1, Devise 4.9+, ActionMailer, IONOS SMTP

---

## 📋 TABLE DES MATIÈRES

1. Architecture & Principes de Sécurité
2. Configuration Devise Optimale
3. Gestion du Workflow Login/Confirmation
4. Protection Anti-Abus (Rate Limiting)
5. Gestion des Erreurs SMTP
6. Sécurité des Templates Email
7. Implémentation Complète (Code)
8. Tests & Validation
9. Monitoring & Logging
10. Checklist Pré-Production

---

## 1. ARCHITECTURE & PRINCIPES DE SÉCURITÉ

### 1.1 Modèle de Sécurité Recommandé

```
Inscription → Email confirme envoyé → Période de grâce (2j) → 
  ├─ Utilisateur clique lien → Confirmé ✓
  ├─ Utilisateur se connecte sans confirmer → Message + lien renvoi
  └─ Période de grâce expirée → Forcer confirmation avant accès complet
```

### 1.2 Principes Fondamentaux

| Principe | Justification |
|----------|--------------|
| **Période de grâce** | Évite frustration UX (utilisateurs oublient email) |
| **Tokens à courte durée** | Réduit fenêtre d'exploitation en cas de compromission |
| **Rate limiting** | Protection contre attaques par force brute, énumération |
| **Idempotence email** | Évite les doublons si renvoi accidentel |
| **Logging exhaustif** | Détection d'anomalies, conformité RGPD |
| **Fallback SMTP** | Continuité service si IONOS indisponible |

### 1.3 Vecteurs d'Attaque à Protéger

| Vecteur | Description | Mitigation |
|---------|-------------|-----------|
| **Énumération email** | Attaquant teste emails valides | Réponses identiques; pas de "user not found" |
| **Force brute tokens** | Attaquant teste tokens confirmation | Rate limiting; tokens longs (32+ octets) |
| **Token reuse** | Utiliser token déjà utilisé | Tokens invalidés après confirmation |
| **Spam renvois** | Attaquant bombarde renvoi email | Rate limiting par IP + utilisateur |
| **XSS email** | Injection code malveillant dans email | Échappement automatique Rails |
| **SMTP interception** | Interception mail en transit | SSL/TLS obligatoire (port 465) |

---

## 2. CONFIGURATION DEVISE OPTIMALE

### 2.1 Configuration `devise.rb` Recommandée

```ruby
# config/initializers/devise.rb

Devise.setup do |config|
  # ============ CONFIRMABLE SETTINGS ============
  
  # Permet connexion sans confirmation pendant X jours
  # Recommandation: 2 jours (donne temps utilisateur de vérifier email)
  # IMPORTANT: Cela NE SIGNIFIE PAS pas de confirmation requise
  #            C'est une "période de grâce" pour UX
  config.allow_unconfirmed_access_for = 2.days
  
  # Délai dans lequel confirmation doit arriver
  # Par défaut: nil (pas de limite)
  # Recommandation: 3 jours (suffit pour renvois, pas trop long)
  config.confirm_within = 3.days
  
  # Confirmation requise pour changement d'email
  # Recommandation: true (sécurité: prévient voler emails)
  config.reconfirmable = true
  
  # Envoyer email original lors du changement d'email
  # Recommandation: true (alerte utilisateur)
  config.send_email_changed_notification = true
  
  # ============ SECURITY SETTINGS ============
  
  # Pepper (salt) pour hachage mot de passe
  config.pepper = Rails.application.credentials.dig(:devise, :pepper)
  
  # Durée de session (remember_me)
  config.remember_for = 2.weeks
  
  # ============ MAIL SETTINGS ============
  
  config.mailer = 'DeviseMailer'
  config.parent_mailer = 'ApplicationMailer'
  
  # ============ OTHER ============
  
  # Masquer devise routes par défaut
  config.routes = false
  
  # URL de base pour les liens dans les emails
  # À configurer par environnement
  config.mailer_sender = 'noreply@grenoble-roller.org'
end
```

### 2.2 Model User Configuration

```ruby
# app/models/user.rb

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable
  
  # ============ STATUTS & VALIDATIONS ============
  
  validates :email, presence: true, uniqueness: true, format: { 
    with: URI::MailTo::EMAIL_REGEXP,
    message: "format invalide"
  }
  
  # ============ CONFIRMATION LOGIC ============
  
  # Permet connexion dans période de grâce
  # MAIS avec restrictions (voir application_controller)
  def active_for_authentication?
    super || !confirmed?
  end
  
  # Message personnalisé si compte non actif
  def inactive_message
    if !confirmed?
      :unconfirmed_email
    else
      super
    end
  end
  
  # ============ HOOKS ============
  
  after_create :send_confirmation_email
  
  # Envoie lien confirmation lors de l'inscription
  def send_confirmation_email
    send_devise_notification(:confirmation_instructions) if confirmed_at.blank?
  end
  
  # À personnaliser par besoin
  before_confirm :log_confirmation_event
  
  private
  
  def log_confirmation_event
    Rails.logger.info("User ##{id} confirming email at #{Time.current}")
  end
end
```

### 2.3 Migrations Requises

```ruby
# db/migrate/[timestamp]_add_confirmable_to_devise_users.rb

class AddConfirmableToDeviseUsers < ActiveRecord::Migration[7.1]
  def change
    change_table :users do |t|
      # Email confirmation
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Pour reconfirmable
      
      # Indexs pour performance
      t.index :confirmation_token, unique: true
    end
  end
end
```

### 2.4 Comparaison Configuration Selon Cas d'Usage

| Cas d'Usage | allow_unconfirmed_access_for | reconfirmable | confirm_within |
|-------------|------------------------------|---------------|-----------------|
| **Association publique (votre cas)** | 2 jours | true | 3 jours |
| **SaaS B2B sécurisé** | 0 (strict) | true | 1 jour |
| **Plateforme marketplace** | 7 jours | true | 5 jours |
| **Intranet entreprise** | 0 (SSO) | false | - |

---

## 3. GESTION WORKFLOW LOGIN/CONFIRMATION

### 3.1 SessionsController Personnalisé

```ruby
# app/controllers/sessions_controller.rb

class SessionsController < Devise::SessionsController
  include SessionsHelper
  
  before_action :check_unconfirmed_email, only: [:create]
  
  # ============ OVERRIDE CREATE ============
  
  def create
    # Appel Devise standard
    super do |resource|
      if resource.persisted?
        handle_confirmed_or_unconfirmed(resource)
      end
    end
  end
  
  # ============ GESTION POST-LOGIN ============
  
  private
  
  def check_unconfirmed_email
    user = User.find_by(email: user_params[:email])
    return unless user&.encrypted_password.present?
    
    # Vérifier si email non confirmé
    if user.confirmed_at.blank?
      # Vérifier si période de grâce dépassée
      if user.confirmation_sent_at < 2.days.ago
        # Après période de grâce: bloquer
        add_flash_message_for_unconfirmed_expiry(user)
        redirect_to new_user_confirmation_path(email: user.email)
      elsif !confirmation_email_recently_sent?(user)
        # Dans période de grâce: afficher message + renvoi
        set_unconfirmed_session_data(user)
      end
    end
  end
  
  def handle_confirmed_or_unconfirmed(resource)
    if resource.confirmed_at.present?
      # Confirmation complète ✓
      set_flash_message! :notice, :signed_in
      yield resource if block_given?
    elsif resource.confirmation_sent_at > 2.days.ago
      # Dans période de grâce
      set_flash_message! :warning, :unconfirmed_email_grace_period
      set_unconfirmed_session_data(resource)
    else
      # Après période de grâce: deconnecter
      sign_out(resource)
      set_flash_message! :alert, :unconfirmed_email_expired
      redirect_to new_user_confirmation_path(email: resource.email)
    end
  end
  
  def user_params
    params.require(:user).permit(:email, :password)
  end
end
```

### 3.2 Helper Sessions

```ruby
# app/helpers/sessions_helper.rb

module SessionsHelper
  
  # Envoyer message flash pour période de grâce
  def add_flash_message_for_unconfirmed_grace_period(user)
    flash[:warning] = 
      "Email non confirmé. " \
      "#{link_to 'Renvoyer confirmation', " \
      "user_confirmation_path(email: user.email), " \
      "method: :post} avant " \
      "#{l(user.confirmation_sent_at + 2.days)}"
  end
  
  def add_flash_message_for_unconfirmed_expiry(user)
    flash[:alert] = 
      "Période de confirmation expirée (> 2 jours). " \
      "Veuillez demander un nouveau lien."
  end
  
  # Checker si email récemment envoyé (anti-spam)
  def confirmation_email_recently_sent?(user)
    user.confirmation_sent_at > 10.minutes.ago
  end
  
  # Stocker dans session info utilisateur non confirmé
  def set_unconfirmed_session_data(user)
    session[:unconfirmed_email] = user.email
    session[:unconfirmed_user_id] = user.id
  end
  
  # Affichage dans vue (pour resend email)
  def show_resend_confirmation_link?(user)
    user.confirmed_at.blank? && 
    user.confirmation_sent_at > 2.days.ago
  end
end
```

### 3.3 ConfirmationsController Personnalisé

```ruby
# app/controllers/confirmations_controller.rb

class ConfirmationsController < Devise::ConfirmationsController
  include ConfirmationsHelper
  
  # ============ AFFICHAGE PAGE RENVOI ============
  
  def new
    super
    @user = User.new
  end
  
  # ============ RENVOI EMAIL (ANTI-SPAM) ============
  
  def create
    email = confirmation_params[:email].downcase.strip
    @user = User.find_by(email: email)
    
    case handle_resend_confirmation(email, @user)
    when :success
      render :confirmed, notice: i18n_success_message(@user)
    when :rate_limited
      render :new, alert: "Trop de demandes. Réessayez dans 1 heure."
    when :already_confirmed
      redirect_to root_path, notice: "Email déjà confirmé ✓"
    when :not_found
      # Anti-énumération: réponse identique
      render :confirmed, notice: i18n_success_message
    end
  end
  
  # ============ CONFIRMATION VIA LIEN ============
  
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    
    if resource.errors.empty?
      after_confirmation_path_for(resource)
    else
      handle_confirmation_error(resource)
    end
  end
  
  private
  
  def handle_resend_confirmation(email, user)
    return :rate_limited if rate_limit_exceeded?(email)
    return :already_confirmed if user&.confirmed?
    return :not_found unless user
    
    user.resend_confirmation_instructions
    :success
  end
  
  def rate_limit_exceeded?(email)
    cache_key = "resend_confirmation:#{email}:#{Time.current.hour}"
    count = Rails.cache.increment(cache_key, 1, expires_in: 1.hour)
    count > 5 # Max 5 renvois par heure par email
  end
  
  def handle_confirmation_error(resource)
    if resource.confirmation_token_expired?
      redirect_to new_user_confirmation_path,
                  alert: "Lien expiré (> 3 jours). Demandez un nouveau."
    elsif resource.errors.any?
      redirect_to new_user_confirmation_path,
                  alert: "Lien invalide ou déjà utilisé."
    end
  end
  
  def confirmation_params
    params.require(:user).permit(:email)
  end
  
  def after_confirmation_path_for(resource)
    if user_signed_in? && current_user == resource
      signed_in_root_path(resource)
    else
      new_user_session_path
    end
  end
end
```

### 3.4 Helper Confirmations

```ruby
# app/helpers/confirmations_helper.rb

module ConfirmationsHelper
  
  # Message succès non-énumérant (même réponse si user existe ou non)
  def i18n_success_message(user = nil)
    "Si l'email existe dans notre système, " \
    "vous recevrez les instructions de confirmation sous peu."
  end
end
```

### 3.5 ApplicationController - Restrictions

```ruby
# app/controllers/application_controller.rb

class ApplicationController < ActionController::Base
  include Pundit::Authorization
  
  before_action :check_email_confirmation_status, if: :user_signed_in?
  
  private
  
  def check_email_confirmation_status
    return if current_user.confirmed?
    return if skip_confirmation_check?
    
    # Après période de grâce: bloquer
    if current_user.confirmation_sent_at < 2.days.ago
      sign_out(current_user)
      redirect_to root_path,
                  alert: "Merci de confirmer votre email pour continuer.",
                  status: :forbidden
    end
  end
  
  def skip_confirmation_check?
    # Routes où confirmation n'est pas requise
    skipped_routes = %w[
      sessions#destroy
      confirmations#show
      confirmations#create
      password_resets#new
      password_resets#create
    ]
    
    controller_action = "#{controller_name}##{action_name}"
    skipped_routes.include?(controller_action)
  end
end
```

---

## 4. PROTECTION ANTI-ABUS (RATE LIMITING)

### 4.1 Installation & Configuration Rack::Attack

```ruby
# Gemfile
gem 'rack-attack', '~> 6.7'

# bundle install
```

```ruby
# config/initializers/rack_attack.rb

class Rack::Attack
  # ============ CACHE STORE ============
  # Important: utiliser le cache store partagé (pas :memory)
  # Pour développement: :memory OK, production: Redis, Memcached
  
  cache.store = :memory if Rails.env.test?
  
  # ============ THROTTLES: LOGIN ATTEMPTS ============
  
  # Limiter tentatives login par IP
  throttle('sessions/ip', limit: 20, period: 60.seconds) do |req|
    if req.path == '/users/sign_in' && req.post?
      req.ip
    end
  end
  
  # Limiter tentatives login par email
  throttle('sessions/email', limit: 10, period: 60.seconds) do |req|
    if req.path == '/users/sign_in' && req.post?
      req.params.dig('user', 'email')&.downcase
    end
  end
  
  # ============ THROTTLES: CONFIRMATION RESEND ============
  
  # Limiter renvois confirmation par IP
  throttle('confirmations/ip', limit: 10, period: 3600.seconds) do |req|
    if req.path == '/users/confirmation' && req.post?
      req.ip
    end
  end
  
  # Limiter renvois confirmation par email
  throttle('confirmations/email', limit: 5, period: 3600.seconds) do |req|
    if req.path == '/users/confirmation' && req.post?
      email = req.params.dig('user', 'email')&.downcase
      "confirmation:#{email}" if email
    end
  end
  
  # ============ THROTTLES: PASSWORD RESET ============
  
  throttle('password_resets/ip', limit: 10, period: 3600.seconds) do |req|
    if req.path == '/users/password' && req.post?
      req.ip
    end
  end
  
  # ============ RESPONSE HANDLER ============
  
  self.throttled_response = lambda { |env|
    match_data = env['rack.attack.match_data']
    
    case env['rack.attack.throttle_data']
    when 'sessions/ip', 'sessions/email'
      [429, {'Content-Type' => 'application/json'}, 
       [JSON.generate({
         error: "Trop de tentatives. Réessayez dans 1 minute."
       })]]
    when 'confirmations/ip', 'confirmations/email'
      [429, {'Content-Type' => 'application/json'},
       [JSON.generate({
         error: "Trop de demandes confirmation. Réessayez dans 1 heure."
       })]]
    else
      [429, {'Content-Type' => 'application/json'},
       [JSON.generate({
         error: "Rate limit atteint."
       })]]
    end
  }
end
```

### 4.2 Middleware Integration

```ruby
# config/environments/production.rb

Rails.application.configure do
  # ... autres configs ...
  
  # Middleware stack order (important pour Rack::Attack)
  config.middleware.use Rack::Attack
  
  # Cache store pour rate limiting (Redis recommandé)
  config.cache_store = :redis_cache_store, {
    url: ENV['REDIS_URL'],
    namespace: 'rate_limit'
  }
end
```

### 4.3 Configuration Redis (Production)

```ruby
# config/redis.yml

production:
  url: <%= ENV.fetch('REDIS_URL') %>
  namespace: <%= ENV.fetch('REDIS_NAMESPACE', 'rack-attack') %>
  timeout: 5
  pool: 10
```

### 4.4 Disable Rate Limiting en Développement

```ruby
# config/environments/development.rb

Rails.application.configure do
  config.cache_store = :memory_store
  
  # Peut activer Rack::Attack manuellement
  # Ou ignorer les throttles ici
end
```

---

## 5. GESTION ERREURS SMTP & RETRY LOGIC

### 5.1 ApplicationMailer Configué

```ruby
# app/mailers/application_mailer.rb

class ApplicationMailer < ActionMailer::Base
  default from: 'noreply@grenoble-roller.org'
  layout 'mailer'
  
  # ============ RETRY & ERROR HANDLING ============
  
  rescue_from StandardError, with: :handle_delivery_error
  
  private
  
  def handle_delivery_error(error)
    # Logging de l'erreur
    error_context = {
      error: error.class,
      message: error.message,
      backtrace: error.backtrace&.first(5)
    }
    
    Rails.logger.error("Email delivery failed: #{error_context}")
    
    # Notifier admin si erreur critique
    if error.is_a?(Net::SMTPAuthenticationError) ||
       error.is_a?(Net::SMTPServerBusy)
      notify_admin_smtp_error(error_context)
    end
    
    # Re-raise pour que job retry
    raise error
  end
  
  def notify_admin_smtp_error(context)
    # À implémenter: notifier admin
    # AdminMailer.smtp_error(context).deliver_now
  end
end
```

### 5.2 DeviseMailer avec Gestion d'Erreurs

```ruby
# app/mailers/devise_mailer.rb

class DeviseMailer < Devise::Mailer
  default from: 'noreply@grenoble-roller.org'
  layout 'devise_mailer'
  
  # ============ CUSTOM CONFIRMATION EMAIL ============
  
  def confirmation_instructions(record, token, opts = {})
    @user = record
    @confirmation_url = confirmation_url(@user, token, opts)
    @expiry_time = 3.days.from_now.strftime('%d/%m/%Y à %H:%M')
    
    # Logging
    Rails.logger.info(
      "Sending confirmation email to #{@user.email} " \
      "(expires: #{@expiry_time})"
    )
    
    mail(
      to: record.email,
      subject: 'Confirmez votre adresse email',
      template_name: 'confirmation_instructions'
    )
  rescue => e
    Rails.logger.error("Failed to render confirmation email: #{e.message}")
    raise
  end
  
  # ============ EMAIL CHANGED NOTIFICATION ============
  
  def email_changed(record, opts = {})
    @user = record
    @new_email = record.unconfirmed_email
    
    mail(
      to: record.email,
      subject: 'Changement adresse email détecté',
      template_name: 'email_changed'
    )
  end
  
  private
  
  def confirmation_url(user, token, opts = {})
    opts[:host] = Rails.application.config.action_mailer.default_url_options[:host]
    user_confirmation_url(confirmation_token: token, **opts)
  end
end
```

### 5.3 Job ActionMailer avec Retry Logic

```ruby
# config/initializers/active_job.rb

Rails.application.configure do
  # Configuration du job queue adapter
  config.active_job.queue_adapter = :sidekiq
  
  # Retry strategy: exponential backoff
  # par défaut: 5 retries over ~90 minutes
end

# app/jobs/devise_confirmation_job.rb

class DeviseConfirmationJob < ApplicationJob
  queue_as :mailers
  
  # Configuration du retry avec exponential backoff
  retry_on StandardError, 
    wait: :exponentially_longer, 
    attempts: 5, 
    on: StandardError do |job, error|
    
    user = job.arguments.first
    Rails.logger.error(
      "DeviseConfirmationJob failed for user #{user.id}: #{error.message}"
    )
    
    # Notifier après 5 tentatives
    AdminMailer.job_failed(job, error).deliver_now if job.executions_count == 5
  end
  
  def perform(user)
    DeviseMailer.confirmation_instructions(
      user, 
      user.confirmation_token
    ).deliver_now
  end
end
```

### 5.4 SMTP Configuration avec Fallback

```ruby
# config/environments/production.rb

Rails.application.configure do
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  
  # ============ CONFIGURATION SMTP PRINCIPALE ============
  
  config.action_mailer.smtp_settings = {
    address: 'smtp.ionos.fr',
    port: 465,
    domain: 'grenoble-roller.org',
    user_name: Rails.application.credentials.dig(:smtp, :user_name),
    password: Rails.application.credentials.dig(:smtp, :password),
    authentication: :plain,
    enable_starttls_auto: false,
    ssl: true,
    openssl_verify_mode: 'peer',
    
    # ============ RETRY LOGIC ============
    
    # Nombre de tentatives au niveau socket
    open_timeout: 10,    # 10s timeout pour connexion
    read_timeout: 10,    # 10s timeout pour réception
    
    # À implémenter via middleware/job retry
  }
  
  # ============ ALTERNATIVE SMTP (FALLBACK) ============
  # À configurer si IONOS indisponible
  # Peut utiliser SendGrid, AWS SES, etc.
  
  config.action_mailer.postmark_settings = {
    api_token: ENV['POSTMARK_API_TOKEN']
  }
end
```

### 5.5 Middleware pour Retry & Failover

```ruby
# lib/smtp_fallback_middleware.rb

class SMTPFallbackMiddleware
  def initialize(app)
    @app = app
  end
  
  def call(env)
    @app.call(env)
  end
  
  # À utiliser dans le job de mail
  def self.send_with_fallback(mailer_class, method_name, *args)
    begin
      mailer_class.public_send(method_name, *args).deliver_now
    rescue Net::SMTPServerBusy, Net::SMTPAuthenticationError, 
           Timeout::Error => e
      
      Rails.logger.warn(
        "SMTP error #{e.class}: #{e.message}. " \
        "Retrying with fallback..."
      )
      
      # Fallback: utiliser job queue pour retry ultérieur
      DeviseConfirmationJob.set(wait: 5.minutes).perform_later(*args)
      
      # Notifier utilisateur que email sera envoyé sous peu
      raise DeliveryDeferredError, 
        "Email sera envoyé dans quelques minutes"
    end
  end
end

class DeliveryDeferredError < StandardError; end
```

### 5.6 Sidekiq Configuration

```yaml
# config/sidekiq.yml

:concurrency: 5
:timeout: 30
:max_retries: 5

:queues:
  - [critical, 4]
  - [mailers, 3]
  - [default, 2]

:dead_max_jobs: 1000
:dead_max_size: 134217728  # 128MB

# Retry avec exponential backoff
:dead_retry_seconds: 10
```

```ruby
# config/initializers/sidekiq.rb

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] }
  config.logger.level = Logger::INFO
  
  config.death_handlers << ->(status, ex) do
    Rails.logger.error("Sidekiq job died: #{ex.class} - #{ex.message}")
    # Envoyer alerte admin
    AdminMailer.sidekiq_job_failed(status, ex).deliver_now
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] }
end
```

### 5.7 Monitoring & Alertes

```ruby
# app/services/email_monitoring_service.rb

class EmailMonitoringService
  THRESHOLDS = {
    failures_per_hour: 10,
    failed_rate: 0.1  # 10%
  }
  
  def self.check_health
    stats = email_delivery_stats
    
    if stats[:failure_count] > THRESHOLDS[:failures_per_hour]
      alert("Trop d'erreurs d'envoi d'email: #{stats[:failure_count]}/hour")
    end
    
    if stats[:failure_rate] > THRESHOLDS[:failed_rate]
      alert("Taux d'erreur élevé: #{(stats[:failure_rate] * 100).round}%")
    end
    
    stats
  end
  
  private
  
  def self.email_delivery_stats
    hour_ago = 1.hour.ago
    
    {
      success_count: deliver_successful_count(hour_ago),
      failure_count: delivery_failed_count(hour_ago),
      failure_rate: failure_rate(hour_ago)
    }
  end
  
  def self.deliver_successful_count(since)
    # À logger avec ActiveSupport::Notifications
    # ou via Sidekiq stats
    0  # Placeholder
  end
  
  def self.delivery_failed_count(since)
    # Retriever failed jobs from Sidekiq or error logs
    0  # Placeholder
  end
  
  def self.failure_rate(since)
    total = deliver_successful_count(since) + delivery_failed_count(since)
    return 0 if total.zero?
    delivery_failed_count(since).to_f / total
  end
  
  def self.alert(message)
    Rails.logger.error(message)
    # Envoyer notification Slack, email, PagerDuty, etc.
  end
end
```

---

## 6. SÉCURITÉ TEMPLATES EMAIL

### 6.1 Template Confirmation Email (HTML)

```erb
<!-- app/views/devise/mailer/confirmation_instructions.html.erb -->

<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {
      font-family: Arial, sans-serif;
      color: #333;
      background-color: #f5f5f5;
    }
    .container {
      background-color: white;
      margin: 20px auto;
      padding: 20px;
      max-width: 600px;
      border-radius: 5px;
    }
    .header {
      border-bottom: 2px solid #007bff;
      padding-bottom: 10px;
      margin-bottom: 20px;
    }
    .btn {
      display: inline-block;
      padding: 10px 20px;
      background-color: #007bff;
      color: white;
      text-decoration: none;
      border-radius: 5px;
      margin: 20px 0;
    }
    .footer {
      border-top: 1px solid #ddd;
      margin-top: 20px;
      padding-top: 20px;
      font-size: 12px;
      color: #666;
    }
    .warning {
      background-color: #fff3cd;
      border: 1px solid #ffeaa7;
      padding: 10px;
      border-radius: 3px;
      margin: 20px 0;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Bienvenue sur Grenoble Roller 🛼</h1>
    </div>
    
    <p>Bonjour <%= @user.email %>,</p>
    
    <p>
      Merci de vous être inscrit ! Pour finaliser votre inscription,
      veuillez confirmer votre adresse email en cliquant sur le lien ci-dessous :
    </p>
    
    <!-- ============ LIEN CONFIRMATION SÉCURISÉ ============ -->
    <!-- Utilise HTTPS + token unique + expiration -->
    
    <p style="text-align: center;">
      <a href="<%= @confirmation_url %>" class="btn">
        Confirmer mon email
      </a>
    </p>
    
    <p>
      Ou copiez ce lien dans votre navigateur :<br>
      <code><%= truncate(@confirmation_url, length: 80) %></code>
    </p>
    
    <!-- ============ AVERTISSEMENT EXPIRATION ============ -->
    
    <div class="warning">
      <strong>⏰ Attention :</strong> 
      Ce lien expire le <strong><%= @expiry_time %></strong> 
      (dans 3 jours). Passé ce délai, vous devrez demander un nouveau lien.
    </div>
    
    <!-- ============ INSTRUCTIONS SÉCURITÉ ============ -->
    
    <p>
      <strong>🔒 Sécurité :</strong> Ce lien est personnel et unique.
      Ne le partagez pas avec d'autres personnes. 
      Grenoble Roller ne vous demandera jamais votre mot de passe par email.
    </p>
    
    <!-- ============ APPEL À ACTION ALTERNATIF ============ -->
    
    <p>
      Si vous n'avez pas créé ce compte,
      <%= link_to "ignorez simplement cet email", 
                  root_url,
                  style: "text-decoration: underline; color: #007bff;" %>.
    </p>
    
    <!-- ============ FOOTER ============ -->
    
    <div class="footer">
      <p>
        Grenoble Roller - Association de roller à Grenoble<br>
        Montbonot Saint-Martin, Isère 38700<br>
        <a href="https://grenoble-roller.org">grenoble-roller.org</a>
      </p>
      
      <p>
        <strong>Données personnelles :</strong>
        Nous respectons votre vie privée. 
        <%= link_to "Voir notre politique de confidentialité",
                    privacy_policy_url,
                    style: "color: #007bff; text-decoration: none;" %>.
      </p>
    </div>
  </div>
</body>
</html>
```

**Points de Sécurité Clés :**
- ✅ URL HTTPS avec token unique + expiration
- ✅ Pas de scripts (script tags interdits dans email)
- ✅ Contenu échappé automatiquement par Rails (`<%= %>`)
- ✅ Avertissement expiration + sécurité
- ✅ Lien de désinscription/ignorance
- ✅ Footer avec politique de confidentialité

### 6.2 Template Texte Plain (Fallback)

```erb
<!-- app/views/devise/mailer/confirmation_instructions.text.erb -->

Bienvenue sur Grenoble Roller!
========================================

Bonjour <%= @user.email %>,

Merci de vous être inscrit ! Pour finaliser votre inscription,
veuillez confirmer votre adresse email en cliquant sur le lien ci-dessous :

<%= @confirmation_url %>

⏰ ATTENTION: Ce lien expire le <%= @expiry_time %> (dans 3 jours).

🔒 SÉCURITÉ:
- Ce lien est personnel et unique
- Ne le partagez pas avec d'autres
- Grenoble Roller ne vous demandera jamais votre mot de passe par email

Si vous n'avez pas créé ce compte, ignorez simplement cet email.

---
Grenoble Roller - Association de roller
Montbonot Saint-Martin, Isère 38700
https://grenoble-roller.org
```

### 6.3 Protection XSS & Content Security Policy

```ruby
# config/initializers/content_security_policy.rb

Rails.application.config.content_security_policy do |policy|
  # Ne pas permettre scripts inline (si jamais injections)
  policy.script_src :self, :https
  
  # Images autorisées de partout (CDN, etc.)
  policy.img_src :self, :https, :data
  
  # Styles inline OK (CSS des emails)
  policy.style_src :self, :unsafe_inline
  
  # Links externes OK pour les emails
  policy.default_src :self, :https
end

# Pour les emails, appliquer cette politique
Rails.application.config.action_mailer.csp_nonce_generator = 
  -> (request) { SecureRandom.random_bytes(16).hex }
```

### 6.4 Sanitization & Escaping

```ruby
# app/views/devise/mailer/_user_greeting.html.erb

<!-- Rails échappe AUTOMATIQUEMENT les variables -->
<p>Bonjour <%= @user.email %></p>
<!-- Output: <p>Bonjour user@example.com</p> -->
<!-- Même si @user.email = "<script>alert('xss')</script>" -->
<!-- Output: <p>Bonjour &lt;script&gt;alert('xss')&lt;/script&gt;</p> -->

<!-- Pour URLs: utiliser escape_javascript si nécessaire -->
<a href="<%= url_for(@confirmation_url) %>">Confirmer</a>

<!-- Utiliser simple_format ou sanitize si besoin -->
<%= simple_format(@user.instructions) %>
```

### 6.5 DKIM, SPF, DMARC Configuration

```ruby
# config/environments/production.rb

# Ajouter headers d'authentification
config.action_mailer.default_options = {
  from: 'noreply@grenoble-roller.org'
  # Rails ajoute automatiquement Message-ID, Date headers
  # Devise ajoute les tokens nécessaires
}

# À configurer avec IONOS:
# SPF: v=spf1 include:ionos.fr ~all
# DKIM: Key configuration via IONOS admin
# DMARC: v=DMARC1; p=quarantine; rua=mailto:admin@grenoble-roller.org
```

---

## 7. IMPLÉMENTATION COMPLÈTE (CODE PRÊT À L'EMPLOI)

### 7.1 Gemfile Complet

```ruby
# Gemfile

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.4.0'

gem 'rails', '~> 8.1.0'
gem 'pg', '~> 1.1'
gem 'redis', '~> 5.0'

# ============ AUTHENTIFICATION ============
gem 'devise', '~> 4.9'
gem 'devise-i18n'  # Localisation français

# ============ RATE LIMITING ============
gem 'rack-attack', '~> 6.7'

# ============ JOBS ============
gem 'sidekiq', '~> 7.0'
gem 'sidekiq-scheduler'

# ============ LOGGING & MONITORING ============
gem 'sentry-rails'
gem 'sentry-sidekiq'

# ============ AUTRES ============
gem 'puma', '~> 6.0'
gem 'sassc-rails'
gem 'webpacker', '~> 6.0'
gem 'jbuilder'
gem 'redis-rails'
gem 'pundit'  # Authorization

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'dotenv-rails'
end

group :development do
  gem 'web-console'
  gem 'listen'
  gem 'letter_opener'  # Preview emails en dev
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webdrivers'
  gem 'rack-test'  # Pour tester rate limiting
end
```

### 7.2 Routes & Wiring

```ruby
# config/routes.rb

Rails.application.routes.draw do
  devise_for :users, 
    controllers: {
      sessions: 'sessions',
      confirmations: 'confirmations'
    },
    path: '',
    path_names: {
      sign_in: 'sign_in',
      sign_out: 'sign_out',
      sign_up: 'sign_up',
      confirmation: 'confirmation'
    }
  
  # Routes personnalisées
  namespace :users do
    get 'confirmation', to: 'confirmations#new'
    post 'confirmation', to: 'confirmations#create'
  end
  
  root 'home#index'
end
```

### 7.3 Credentials Configuration

```bash
# Enregistrer les credentials sécurisés

EDITOR=nano rails credentials:edit

# Ajouter:
smtp:
  user_name: "votre_email@grenoble-roller.org"
  password: "votre_mot_passe_smtp_ionos"

devise:
  pepper: "votre_pepper_very_long_random_string"

redis:
  url: "redis://localhost:6379/0"
```

### 7.4 Structure Fichiers

```
app/
├── controllers/
│   ├── sessions_controller.rb
│   ├── confirmations_controller.rb
│   └── application_controller.rb
├── mailers/
│   ├── application_mailer.rb
│   ├── devise_mailer.rb
│   └── admin_mailer.rb
├── models/
│   └── user.rb
├── jobs/
│   └── devise_confirmation_job.rb
├── helpers/
│   ├── sessions_helper.rb
│   └── confirmations_helper.rb
├── services/
│   └── email_monitoring_service.rb
├── views/
│   ├── devise/
│   │   ├── mailer/
│   │   │   ├── confirmation_instructions.html.erb
│   │   │   ├── confirmation_instructions.text.erb
│   │   │   └── email_changed.html.erb
│   │   └── confirmations/
│   │       └── new.html.erb
│   └── layouts/
│       └── devise_mailer.html.erb
config/
├── initializers/
│   ├── devise.rb
│   ├── rack_attack.rb
│   ├── active_job.rb
│   ├── sidekiq.rb
│   ├── redis.rb
│   └── content_security_policy.rb
├── environments/
│   ├── development.rb
│   ├── test.rb
│   └── production.rb
├── sidekiq.yml
└── redis.yml
```

---

## 8. TESTS & VALIDATION

### 8.1 Tests Model User

```ruby
# spec/models/user_spec.rb

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'devise modules' do
    it { is_expected.to have_secure_password }
    it { expect(User.devise_modules).to include(:confirmable) }
  end
  
  describe '#confirmation' do
    let(:user) { create(:user) }
    
    it 'should not be confirmed on creation' do
      expect(user.confirmed_at).to be_nil
    end
    
    it 'should send confirmation email after creation' do
      expect {
        create(:user)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
    
    it 'should allow access during grace period' do
      user.update(confirmed_at: nil, confirmation_sent_at: 1.day.ago)
      expect(user.active_for_authentication?).to be_truthy
    end
    
    it 'should deny access after grace period' do
      user.update(confirmed_at: nil, confirmation_sent_at: 3.days.ago)
      expect(user.active_for_authentication?).to be_falsey
    end
  end
  
  describe '#confirmation_token_expired?' do
    let(:user) { create(:user) }
    
    it 'should not be expired if recently sent' do
      user.update(confirmation_sent_at: 1.day.ago)
      expect(user.confirmation_token_expired?).to be_falsey
    end
    
    it 'should be expired after confirm_within' do
      user.update(confirmation_sent_at: 4.days.ago)
      expect(user.confirmation_token_expired?).to be_truthy
    end
  end
end
```

### 8.2 Tests Controllers

```ruby
# spec/controllers/sessions_controller_spec.rb

require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  let(:user) { create(:user, confirmed_at: Time.current) }
  
  describe 'POST #create' do
    context 'with confirmed email' do
      it 'should sign in user' do
        post :create, params: {
          user: { email: user.email, password: user.password }
        }
        expect(subject.current_user).to eq(user)
      end
    end
    
    context 'with unconfirmed email (grace period)' do
      let(:unconfirmed_user) do
        create(:user, confirmed_at: nil, confirmation_sent_at: 1.day.ago)
      end
      
      it 'should sign in with warning' do
        post :create, params: {
          user: { email: unconfirmed_user.email, password: unconfirmed_user.password }
        }
        expect(subject.current_user).to eq(unconfirmed_user)
        expect(flash[:warning]).to include('Email non confirmé')
      end
    end
    
    context 'with unconfirmed email (grace period expired)' do
      let(:expired_user) do
        create(:user, confirmed_at: nil, confirmation_sent_at: 3.days.ago)
      end
      
      it 'should not sign in user' do
        post :create, params: {
          user: { email: expired_user.email, password: expired_user.password }
        }
        expect(subject.current_user).to be_nil
        expect(response).to redirect_to(new_user_confirmation_path)
      end
    end
  end
end

# spec/controllers/confirmations_controller_spec.rb

require 'rails_helper'

RSpec.describe ConfirmationsController, type: :controller do
  let(:user) { create(:user, confirmed_at: nil) }
  
  describe 'POST #create (resend)' do
    context 'first resend' do
      it 'should send confirmation email' do
        expect {
          post :create, params: { user: { email: user.email } }
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
      
      it 'should show success message' do
        post :create, params: { user: { email: user.email } }
        expect(flash[:notice]).to include('recevrez les instructions')
      end
    end
    
    context 'rate limit exceeded' do
      before do
        # Mock 6 previous requests
        6.times do
          Rails.cache.increment("resend_confirmation:#{user.email}:#{Time.current.hour}")
        end
      end
      
      it 'should return rate limit error' do
        post :create, params: { user: { email: user.email } }
        expect(response.status).to eq(429)
      end
    end
    
    context 'user not found (enumeration protection)' do
      it 'should return same success message' do
        post :create, params: { user: { email: 'nonexistent@example.com' } }
        expect(flash[:notice]).to include('recevrez les instructions')
      end
    end
  end
  
  describe 'GET #show (confirmation link)' do
    let(:token) { user.confirmation_token }
    
    it 'should confirm user when token valid' do
      get :show, params: { confirmation_token: token }
      user.reload
      expect(user.confirmed_at).to be_present
    end
    
    it 'should redirect to login on success' do
      get :show, params: { confirmation_token: token }
      expect(response).to redirect_to(new_user_session_path)
    end
    
    it 'should show error with invalid token' do
      get :show, params: { confirmation_token: 'invalid_token' }
      expect(flash[:alert]).to include('Lien invalide')
    end
  end
end
```

### 8.3 Tests Rack::Attack

```ruby
# spec/rack_attack_spec.rb

require 'rails_helper'

RSpec.describe 'Rack::Attack', type: :request do
  # Inclure rack-test helpers
  include Rack::Test::Methods
  
  describe 'login rate limiting' do
    let(:ip) { '1.2.3.4' }
    
    context 'within limits' do
      it 'should allow 20 requests per minute per IP' do
        20.times do
          post '/users/sign_in', 
               params: { user: { email: 'test@example.com' } },
               headers: { 'REMOTE_ADDR' => ip }
          expect(last_response.status).not_to eq(429)
        end
      end
    end
    
    context 'exceeds limit' do
      it 'should return 429 Too Many Requests' do
        21.times do |i|
          post '/users/sign_in',
               params: { user: { email: "test#{i}@example.com" } },
               headers: { 'REMOTE_ADDR' => ip }
        end
        expect(last_response.status).to eq(429)
      end
    end
  end
  
  describe 'confirmation resend rate limiting' do
    context 'within limits' do
      it 'should allow 5 resends per hour per email' do
        5.times do
          post '/users/confirmation',
               params: { user: { email: 'user@example.com' } }
          expect(last_response.status).not_to eq(429)
        end
      end
    end
    
    context 'exceeds limit' do
      it 'should return 429 after 5 resends' do
        6.times do
          post '/users/confirmation',
               params: { user: { email: 'user@example.com' } }
        end
        expect(last_response.status).to eq(429)
      end
    end
  end
end
```

### 8.4 Tests Email Content

```ruby
# spec/mailers/devise_mailer_spec.rb

require 'rails_helper'

RSpec.describe DeviseMailer, type: :mailer do
  let(:user) { create(:user) }
  
  describe 'confirmation_instructions' do
    let(:token) { 'confirmation_token' }
    let(:mail) { DeviseMailer.confirmation_instructions(user, token) }
    
    it 'renders subject' do
      expect(mail.subject).to eq('Confirmez votre adresse email')
    end
    
    it 'renders to email' do
      expect(mail.to).to eq([user.email])
    end
    
    it 'includes confirmation link' do
      expect(mail.body.encoded).to include('confirmation_token')
    end
    
    it 'includes expiry information' do
      expect(mail.body.encoded).to include('3 jours')
    end
    
    it 'does not include XSS vulnerable content' do
      expect(mail.body.encoded).not_to include('<script>')
      expect(mail.body.encoded).not_to include('javascript:')
    end
    
    it 'includes security warnings' do
      expect(mail.body.encoded).to include('Sécurité')
      expect(mail.body.encoded).to include('personnel')
    end
  end
end
```

### 8.5 Test Command

```bash
# Lancer tous les tests
bundle exec rspec spec/

# Tests spécifiques
bundle exec rspec spec/models/user_spec.rb
bundle exec rspec spec/controllers/sessions_controller_spec.rb
bundle exec rspec spec/rack_attack_spec.rb

# Avec coverage
bundle exec rspec spec/ --require coverage --format RSpec::Format::Html --out coverage/index.html
```

---

## 9. MONITORING & LOGGING

### 9.1 Loggers Configurés

```ruby
# config/initializers/logging.rb

# Logger spécialisé pour authentification
class AuthenticationLogger
  def self.log_event(event_type, user_id, context = {})
    Rails.logger.info(
      "[AUTH] #{event_type} | User ID: #{user_id} | " \
      "Timestamp: #{Time.current.iso8601} | " \
      "Context: #{context.inspect}"
    )
  end
end

# Utilisation
AuthenticationLogger.log_event(
  'user_confirmation',
  user.id,
  { email: user.email, ip: request.ip }
)
```

### 9.2 ActiveSupport Notifications

```ruby
# app/models/user.rb
# Config Devise pour envoyer notifications

# app/models/user.rb

after_confirm do
  ActiveSupport::Notifications.instrument('user.confirmed',
    user_id: id,
    email: email,
    confirmed_at: confirmed_at
  )
end
```

```ruby
# config/initializers/notifications.rb

# Listener pour confirmations
ActiveSupport::Notifications.subscribe('user.confirmed') do |name, start_time, end_time, id, payload|
  Rails.logger.info(
    "User confirmed: #{payload[:email]} at #{payload[:confirmed_at]}"
  )
  
  # Envoyer événement Sentry
  Sentry.capture_message(
    "User confirmed",
    level: :info,
    extra: payload
  )
end

# Listener pour erreurs mail
ActiveSupport::Notifications.subscribe('deliver.action_mailer') do |name, start_time, end_time, id, payload|
  duration = ((end_time - start_time) * 1000).round(2)
  
  Rails.logger.debug(
    "Email sent: #{payload[:message_id]} | " \
    "To: #{payload[:message].to} | " \
    "Duration: #{duration}ms"
  )
end
```

### 9.3 Sentry Configuration

```ruby
# config/initializers/sentry.rb

Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.environment = Rails.env
  config.enabled_environments = %w[production staging]
  
  # Filtrer données sensibles
  config.before_send = lambda { |event, hint|
    # Masquer emails, tokens, passwords
    if event.request
      event.request.url = event.request.url.gsub(
        /confirmation_token=\w+/,
        'confirmation_token=***'
      )
    end
    event
  }
  
  # Integrations
  config.integrations do |integration|
    if Rails.env.development?
      integration.disable :performance_monitoring
    end
  end
  
  # Sidekiq integration
  config.enabled_integrations = %w[
    active_job
    sidekiq
    rack
    delayed_job
  ]
end
```

### 9.4 Structured Logging (JSON)

```ruby
# config/environments/production.rb

Rails.application.configure do
  if ENV['RAILS_LOG_TO_STDOUT'].present?
    STDOUT.sync = true
    config.logger = ActiveSupport::TaggedLogging.new(
      ActiveSupport::Logger.new(STDOUT, formatter: JSONFormatter.new)
    )
  end
end

# lib/json_formatter.rb

class JSONFormatter
  def call(severity, time, progname, msg)
    {
      timestamp: time.iso8601,
      level: severity,
      program: progname,
      message: msg,
      pid: Process.pid,
      thread: Thread.current.object_id
    }.to_json + "\n"
  end
end
```

### 9.5 Dashboards & Metrics

```ruby
# app/services/email_metrics_service.rb

class EmailMetricsService
  def self.report
    {
      total_sent: email_metrics[:total_sent],
      success_rate: email_metrics[:success_rate],
      failure_rate: email_metrics[:failure_rate],
      avg_delivery_time: email_metrics[:avg_delivery_time],
      failed_jobs: Sidekiq::RetrySet.new.size,
      dead_jobs: Sidekiq::DeadSet.new.size
    }
  end
  
  private
  
  def self.email_metrics
    # À implémenter avec votre système de metrics
    # (Prometheus, Datadog, New Relic, etc.)
    {}
  end
end
```

---

## 10. CHECKLIST PRÉ-PRODUCTION

### 10.1 Configuration Sécurité

- [ ] **Credentials Sécurisés**
  - [ ] `devise.pepper` très long et aléatoire (32+ caractères)
  - [ ] SMTP credentials stockés dans `credentials.yml.enc`
  - [ ] Redis password sécurisé si utilisé
  - [ ] Aucun secret en dur dans le code

- [ ] **Devise Configuration**
  - [ ] `allow_unconfirmed_access_for = 2.days` ✓
  - [ ] `reconfirmable = true` ✓
  - [ ] `confirm_within = 3.days` ✓
  - [ ] `send_email_changed_notification = true` ✓

- [ ] **SMTP Configuration**
  - [ ] SSL/TLS activé (port 465) ✓
  - [ ] Open timeout: 10s ✓
  - [ ] Read timeout: 10s ✓
  - [ ] IONOS credentials testés

- [ ] **Rate Limiting (Rack::Attack)**
  - [ ] Sessions: 20 req/min par IP ✓
  - [ ] Sessions: 10 req/min par email ✓
  - [ ] Confirmations: 10 req/hour par IP ✓
  - [ ] Confirmations: 5 req/hour par email ✓
  - [ ] Redis cache store configuré ✓

- [ ] **Email Templates**
  - [ ] HTML template: confirmation instructions ✓
  - [ ] Text template: fallback ✓
  - [ ] Tokens échappés (URLs safe) ✓
  - [ ] Pas de scripts inline ✓
  - [ ] HTTPS links uniquement ✓
  - [ ] SPF/DKIM/DMARC configurés

### 10.2 Code & Contrôleurs

- [ ] **Controllers**
  - [ ] SessionsController custom implémenté ✓
  - [ ] ConfirmationsController custom implémenté ✓
  - [ ] ApplicationController: `check_email_confirmation_status` ✓
  - [ ] Routes personnalisées ✓

- [ ] **Models**
  - [ ] User model: `active_for_authentication?` override ✓
  - [ ] User model: `inactive_message` personnalisé ✓
  - [ ] Validations email: format + uniqueness ✓
  - [ ] Après hooks pour logging ✓

- [ ] **Mailers**
  - [ ] DeviseMailer custom ✓
  - [ ] ApplicationMailer: error handling ✓
  - [ ] Rescue SMTP errors ✓
  - [ ] Logging de tous les envois ✓

### 10.3 Jobs & Async

- [ ] **ActiveJob**
  - [ ] Queue adapter: Sidekiq configuré ✓
  - [ ] Retry strategy: exponential backoff ✓
  - [ ] Max attempts: 5 ✓
  - [ ] Idempotency tokens configurés ✓

- [ ] **Sidekiq**
  - [ ] Redis connection sécurisée ✓
  - [ ] Sidekiq.yml configuré ✓
  - [ ] Max retries: 5 ✓
  - [ ] Dead letter handling ✓

### 10.4 Monitoring & Logging

- [ ] **Logging**
  - [ ] Structured logging (JSON) activé ✓
  - [ ] AuthenticationLogger implémenté ✓
  - [ ] Tous les events loggés (confirm, resend, etc.) ✓
  - [ ] Pas de données sensibles en logs ✓

- [ ] **Monitoring**
  - [ ] Sentry configuration ✓
  - [ ] Error tracking activé ✓
  - [ ] Performance monitoring activé ✓
  - [ ] Alerts configurées ✓

- [ ] **Métriques**
  - [ ] Email delivery rate surveilled ✓
  - [ ] Failure rate alerting ✓
  - [ ] Job queue depth monitored ✓
  - [ ] Redis health checked ✓

### 10.5 Tests

- [ ] **Unit Tests**
  - [ ] User model: 100% de couverture confirmation ✓
  - [ ] Controllers: tous les scénarios testés ✓
  - [ ] Mailers: template content validation ✓
  - [ ] Helpers: message formatting ✓

- [ ] **Integration Tests**
  - [ ] Signup → Email → Confirmation workflow ✓
  - [ ] Login sans confirmation (grace period) ✓
  - [ ] Login après expiration (blocage) ✓
  - [ ] Renvoi email (rate limiting) ✓

- [ ] **Security Tests**
  - [ ] Rack::Attack throttling actif ✓
  - [ ] XSS protection dans templates ✓
  - [ ] Token expiration testé ✓
  - [ ] Enumeration protection validée ✓

- [ ] **SMTP Tests**
  - [ ] Connection IONOS testé ✓
  - [ ] Retry logic testé ✓
  - [ ] Error handling testé ✓
  - [ ] Fallback strategy testé ✓

### 10.6 Infrastructure

- [ ] **Production Deployment**
  - [ ] HTTPS partout (même localhost doit être configurable) ✓
  - [ ] Redis instance disponible ✓
  - [ ] Sidekiq worker process running ✓
  - [ ] Logs centralisés (CloudWatch, Datadog, etc.) ✓

- [ ] **Database**
  - [ ] Migration `add_confirmable_to_devise_users` appliquée ✓
  - [ ] Indexes sur confirmation_token créés ✓
  - [ ] Backups réguliers activés ✓

- [ ] **Sécurité Réseau**
  - [ ] SMTP over SSL (port 465) ✓
  - [ ] Redis accessible uniquement depuis app ✓
  - [ ] Database accessible uniquement depuis app ✓
  - [ ] WAF/DDoS protection ✓

### 10.7 Conformité & Documentation

- [ ] **RGPD**
  - [ ] Politique de confidentialité en place ✓
  - [ ] Données personnelles minimales collectées ✓
  - [ ] Droit à l'oubli implémenté ✓
  - [ ] Consentement email explicite ✓

- [ ] **Documentation**
  - [ ] Architecture email documentée ✓
  - [ ] Runbook incident SMTP ✓
  - [ ] Configuration IONOS documentée ✓
  - [ ] Process de debugging documenté ✓

- [ ] **Incident Response**
  - [ ] Plan d'action: SMTP down ✓
  - [ ] Plan d'action: Redis down ✓
  - [ ] Plan d'action: mass confirmation failures ✓
  - [ ] Contacts d'urgence listé ✓

---

## RESSOURCES & RÉFÉRENCES

### Documentes Officielles
- [Devise Documentation](https://github.com/heartcombo/devise)
- [Rails ActionMailer Guides](https://guides.rubyonrails.org/action_mailer_basics.html)
- [Rack::Attack GitHub](https://github.com/rack/rack-attack)
- [Sidekiq Documentation](https://sidekiq.org/)

### Sécurité
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)

### Bonnes Pratiques Email
- [RFC 5321 - SMTP](https://tools.ietf.org/html/rfc5321)
- [Email Authentication (SPF/DKIM/DMARC)](https://www.dmarcian.com/)

---

**Document compilé pour: Grenoble Roller | Rails 8.1 | Production-Ready**
