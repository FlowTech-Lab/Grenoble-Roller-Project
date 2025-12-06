# 🎯 Plan d'Implémentation - Sécurité Email & Confirmation Devise

**Date de création** : 2025-01-20  
**Basé sur** : `devise-email-security-guide.md`  
**Status** : 📋 À implémenter

---

## 📊 ÉTAT ACTUEL vs RECOMMANDATIONS

### ✅ Déjà en Place

| Élément | État Actuel | Guide Recommandé | Match |
|---------|-------------|------------------|-------|
| Module `:confirmable` | ✅ Activé | ✅ Requis | ✅ **OK** |
| `allow_unconfirmed_access_for` | ✅ `2.days` | `2.days` | ✅ **OK** |
| `reconfirmable` | ✅ `true` | `true` | ✅ **OK** |
| `confirm_within` | ❌ Non configuré | `3.days` | ⚠️ **À AJOUTER** |
| `send_email_changed_notification` | ❌ Non configuré | `true` | ⚠️ **À AJOUTER** |
| Rack::Attack | ✅ Configuré (logins, passwords) | ✅ Requis | ⚠️ **À ÉTENDRE** |
| Templates email | ✅ HTML + texte (confirmations) | ✅ Requis | ✅ **OK** |
| SMTP configuré | ✅ IONOS (port 465, SSL) | ✅ Requis | ✅ **OK** |
| SessionsController | ⚠️ Basique | ✅ Custom avec détection | ⚠️ **À AMÉLIORER** |
| ConfirmationsController | ❌ N'existe pas | ✅ Custom recommandé | ❌ **À CRÉER** |
| ApplicationController | ⚠️ Partiel (`ensure_email_confirmed`) | ✅ Complet | ⚠️ **À AMÉLIORER** |
| User model | ⚠️ Basique | ✅ Complet avec logging | ⚠️ **À AMÉLIORER** |
| DeviseMailer custom | ❌ N'existe pas | ✅ Recommandé | ❌ **À CRÉER** |
| Rate limiting confirmations | ❌ Absent | ✅ Requis | ❌ **À AJOUTER** |
| Protection énumération | ❌ Absent | ✅ Requis | ❌ **À AJOUTER** |
| Logging & monitoring | ⚠️ Basique | ✅ Complet | ⚠️ **À AMÉLIORER** |

---

## 🎯 PLAN D'IMPLÉMENTATION PAR PHASES

### PHASE 1 : Configuration Devise (Priorité Haute) 🔴

**Objectif** : Configurer correctement Devise pour la confirmation d'email

#### Modifications à faire

**1.1. `config/initializers/devise.rb`**

```ruby
# Décommenter et configurer
config.confirm_within = 3.days  # Actuellement ligne 155 commentée

# Ajouter (manquant)
config.send_email_changed_notification = true

# Vérifier mailer
config.mailer_sender = 'no-reply@grenoble-roller.org'
```

**Fichier à modifier** : `config/initializers/devise.rb` lignes 155, + ajout

---

### PHASE 2 : Model User (Priorité Haute) 🔴

**Objectif** : Améliorer le modèle User avec logging et méthodes de sécurité

#### Modifications à faire

**2.1. `app/models/user.rb`**

```ruby
# Ajouter méthode inactive_message
def inactive_message
  if !confirmed?
    :unconfirmed_email
  else
    super
  end
end

# Ajouter méthode confirmation_token_expired?
def confirmation_token_expired?
  return false if confirmed_at.present?
  return false unless confirmation_sent_at.present?
  return false unless Devise.confirm_within
  confirmation_sent_at < Devise.confirm_within.ago
end

# Améliorer send_welcome_email_and_confirmation
def send_welcome_email_and_confirmation
  # Envoyer email de bienvenue
  UserMailer.welcome_email(self).deliver_later
  
  # Envoyer email de confirmation Devise
  send_confirmation_instructions
  
  # Logging
  Rails.logger.info("Confirmation email sent to #{email} at #{Time.current}")
end

# Ajouter callback pour logging confirmation
after_confirm :log_confirmation_event

private

def log_confirmation_event
  Rails.logger.info("User ##{id} confirmed email at #{Time.current}")
end
```

**Fichier à modifier** : `app/models/user.rb`

---

### PHASE 3 : SessionsController (Priorité Haute) 🔴

**Objectif** : Détecter email non confirmé au login et afficher message

#### Modifications à faire

**3.1. `app/controllers/sessions_controller.rb`**

```ruby
# Remplacer la méthode create actuelle
def create
  super do |resource|
    if resource.persisted?
      handle_confirmed_or_unconfirmed(resource)
    end
  end
end

private

def handle_confirmed_or_unconfirmed(resource)
  if resource.confirmed?
    # Email confirmé : connexion normale
    first_name = resource.first_name.presence || "membre"
    flash[:notice] = "Bonjour #{first_name} ! 👋 Bienvenue sur Grenoble Roller."
  elsif resource.confirmation_sent_at > 2.days.ago
    # Dans période de grâce : message d'avertissement
    first_name = resource.first_name.presence || "membre"
    flash[:warning] = 
      "Bonjour #{first_name} ! 👋 " \
      "Votre email n'est pas encore confirmé. " \
      "#{view_context.link_to('Renvoyer l\'email de confirmation', " \
      "new_user_confirmation_path(email: resource.email), " \
      "class: 'alert-link')}".html_safe
  else
    # Après période de grâce : déconnecter et rediriger
    sign_out(resource)
    flash[:alert] = 
      "Votre période de confirmation est expirée. " \
      "Veuillez demander un nouveau lien de confirmation."
    redirect_to new_user_confirmation_path(email: resource.email)
    return
  end
end
```

**Fichier à modifier** : `app/controllers/sessions_controller.rb`

---

### PHASE 4 : ConfirmationsController (Priorité Haute) 🔴

**Objectif** : Créer un contrôleur custom pour gérer renvois et protection anti-abus

#### Fichier à créer

**4.1. `app/controllers/confirmations_controller.rb`** (NOUVEAU)

```ruby
class ConfirmationsController < Devise::ConfirmationsController
  # ============ RENVOI EMAIL ============
  
  def create
    email = confirmation_params[:email]&.downcase&.strip
    
    return render :new, alert: "Email requis" if email.blank?
    
    @user = User.find_by(email: email)
    
    case handle_resend_confirmation(email, @user)
    when :rate_limited
      render :new, alert: "Trop de demandes. Réessayez dans 1 heure."
    when :already_confirmed
      redirect_to root_path, notice: "Cet email est déjà confirmé ✓"
    when :not_found
      # Anti-énumération : même réponse si user existe ou non
      render :confirmed, notice: i18n_success_message
    when :success
      render :confirmed, notice: i18n_success_message(@user)
    end
  end
  
  # ============ CONFIRMATION VIA LIEN ============
  
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    
    if resource.errors.empty?
      set_flash_message! :notice, :confirmed
      sign_in(resource_name, resource)
      redirect_to after_confirmation_path_for(resource)
    else
      handle_confirmation_error(resource)
    end
  end
  
  private
  
  def handle_resend_confirmation(email, user)
    # Rate limiting
    return :rate_limited if rate_limit_exceeded?(email)
    
    # Email déjà confirmé
    return :already_confirmed if user&.confirmed?
    
    # Email non trouvé (anti-énumération : on ne révèle pas l'existence)
    return :not_found unless user
    
    # Envoyer email
    user.send_confirmation_instructions
    :success
  end
  
  def rate_limit_exceeded?(email)
    cache_key = "resend_confirmation:#{email}:#{Time.current.hour}"
    count = Rails.cache.increment(cache_key, 1, expires_in: 1.hour) || 1
    count > 5 # Max 5 renvois par heure par email
  end
  
  def handle_confirmation_error(resource)
    if resource.confirmation_token_expired?
      redirect_to new_user_confirmation_path,
                  alert: "Lien expiré (> 3 jours). Veuillez demander un nouveau lien."
    elsif resource.errors.any?
      redirect_to new_user_confirmation_path,
                  alert: "Lien invalide ou déjà utilisé."
    end
  end
  
  def confirmation_params
    params.require(:user).permit(:email)
  end
  
  def i18n_success_message(user = nil)
    "Si l'email existe dans notre système, " \
    "vous recevrez les instructions de confirmation sous peu."
  end
  
  def after_confirmation_path_for(resource)
    if user_signed_in? && current_user == resource
      root_path
    else
      new_user_session_path
    end
  end
end
```

**Fichier à créer** : `app/controllers/confirmations_controller.rb`

**4.2. Mettre à jour `config/routes.rb`**

```ruby
devise_for :users, controllers: {
  sessions: "sessions",
  registrations: "registrations",
  passwords: "passwords",
  confirmations: "confirmations"  # AJOUTER CETTE LIGNE
}
```

**Fichier à modifier** : `config/routes.rb`

---

### PHASE 5 : ApplicationController (Priorité Moyenne) 🟡

**Objectif** : Améliorer la gestion de la confirmation dans ApplicationController

#### Modifications à faire

**5.1. `app/controllers/application_controller.rb`**

```ruby
# Remplacer ensure_email_confirmed par check_email_confirmation_status
before_action :check_email_confirmation_status, if: :user_signed_in?

private

def check_email_confirmation_status
  return if current_user.confirmed?
  return if skip_confirmation_check?
  
  # Après période de grâce : bloquer certaines actions
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
    passwords#new
    passwords#create
  ]
  
  controller_action = "#{controller_name}##{action_name}"
  skipped_routes.include?(controller_action)
end

# Garder aussi ensure_email_confirmed pour actions critiques
def ensure_email_confirmed
  return unless user_signed_in?
  return if Rails.env.development? || Rails.env.test?
  
  unless current_user.confirmed?
    redirect_to root_path,
                alert: "Vous devez confirmer votre adresse email pour effectuer cette action. " \
                       "Vérifiez votre boîte mail ou " \
                       "#{view_context.link_to('demandez un nouvel email de confirmation', " \
                       "new_user_confirmation_path, class: 'alert-link')}".html_safe,
                status: :forbidden
  end
end
```

**Fichier à modifier** : `app/controllers/application_controller.rb`

---

### PHASE 6 : Rack::Attack - Rate Limiting Confirmations (Priorité Haute) 🔴

**Objectif** : Ajouter rate limiting pour les renvois de confirmation

#### Modifications à faire

**6.1. `config/initializers/rack_attack.rb`**

```ruby
# Ajouter après les throttles existants (ligne 32)

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
```

**Fichier à modifier** : `config/initializers/rack_attack.rb`

**6.2. Améliorer la réponse throttled**

```ruby
# Modifier Rack::Attack.throttled_responder (ligne 48)
Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env["rack.attack.match_data"]
  throttle_name = request.env["rack.attack.matched"]
  
  retry_after = 60
  if match_data
    if match_data.is_a?(Hash)
      retry_after = match_data[:period] || match_data["period"] || 60
    elsif match_data.respond_to?(:period)
      retry_after = match_data.period
    end
  end
  
  # Messages spécifiques selon le throttle
  message = case throttle_name
  when 'confirmations/ip', 'confirmations/email'
    "Trop de demandes de renvoi d'email. Réessayez dans 1 heure."
  when 'sessions/ip', 'sessions/email'
    "Trop de tentatives de connexion. Réessayez dans 1 minute."
  else
    "Trop de tentatives. Réessayez plus tard."
  end
  
  [
    429,
    {
      "Content-Type" => "text/html; charset=utf-8",
      "Retry-After" => retry_after.to_s
    },
    ["<html><body><h1>Trop de tentatives</h1><p>#{message}</p></body></html>"]
  ]
end
```

---

### PHASE 7 : Templates Email & Vues (Priorité Moyenne) 🟡

**Objectif** : Améliorer les templates et la page de renvoi

#### Modifications à faire

**7.1. Améliorer `app/views/devise/confirmations/new.html.erb`**

```erb
<div class="container-fluid py-5">
  <div class="row justify-content-center">
    <div class="col-12 col-md-6 col-lg-4">
      <div class="card card-liquid rounded-liquid shadow-liquid auth-form">
        <div class="card-body p-4">
          <div class="text-center mb-4">
            <i class="bi bi-envelope-check fs-1 text-liquid-primary"></i>
            <h3 class="mt-2">Renvoyer l'email de confirmation</h3>
            <p class="text-muted small">
              Entrez votre adresse email pour recevoir un nouveau lien de confirmation
            </p>
          </div>
          
          <%= form_for(resource, as: resource_name, 
                       url: confirmation_path(resource_name), 
                       html: { method: :post, data: { turbo: false } }) do |f| %>
            <%= render "devise/shared/error_messages", resource: resource %>
            
            <div class="mb-3">
              <%= f.label :email, "Email", class: "form-label required" %>
              <%= f.email_field :email, 
                  autofocus: true, 
                  autocomplete: "email", 
                  value: (resource.pending_reconfirmation? ? resource.unconfirmed_email : resource.email),
                  class: "form-control form-control-liquid", 
                  placeholder: "votre@email.com", 
                  required: true %>
            </div>
            
            <button type="submit" class="btn btn-liquid-primary w-100 mb-3">
              <i class="bi bi-send me-2"></i>
              Renvoyer l'email de confirmation
            </button>
          <% end %>
          
          <div class="text-center">
            <%= link_to "Retour à la connexion", new_session_path(resource_name), 
                class: "small text-decoration-none" %>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
```

**Fichier à modifier** : `app/views/devise/confirmations/new.html.erb`

**7.2. Créer `app/views/devise/confirmations/confirmed.html.erb` (NOUVEAU)**

```erb
<div class="container-fluid py-5">
  <div class="row justify-content-center">
    <div class="col-12 col-md-6 col-lg-4">
      <div class="card card-liquid rounded-liquid shadow-liquid">
        <div class="card-body p-4 text-center">
          <i class="bi bi-check-circle-fill text-success fs-1 mb-3"></i>
          <h3 class="mb-3">Email envoyé !</h3>
          <p class="text-muted">
            <%= notice || "Si l'email existe dans notre système, " \
                          "vous recevrez les instructions de confirmation sous peu." %>
          </p>
          <p class="text-muted small">
            Vérifiez votre boîte de réception (et vos spams) et cliquez sur le lien reçu.
          </p>
          <%= link_to "Retour à la connexion", new_session_path, 
              class: "btn btn-liquid-primary mt-3" %>
        </div>
      </div>
    </div>
  </div>
</div>
```

**Fichier à créer** : `app/views/devise/confirmations/confirmed.html.erb`

---

### PHASE 8 : DeviseMailer Custom (Priorité Basse) 🟢

**Objectif** : Personnaliser le mailer Devise avec meilleure gestion d'erreurs

#### Fichier à créer

**8.1. `app/mailers/devise_mailer.rb` (NOUVEAU - Optionnel)**

```ruby
class DeviseMailer < Devise::Mailer
  default from: 'Grenoble Roller <no-reply@grenoble-roller.org>'
  layout 'mailer'
  
  def confirmation_instructions(record, token, opts = {})
    @user = record
    @confirmation_url = confirmation_url(@user, confirmation_token: token)
    @expiry_time = 3.days.from_now.strftime('%d/%m/%Y à %H:%M')
    
    # Logging
    Rails.logger.info(
      "Sending confirmation email to #{@user.email} " \
      "(expires: #{@expiry_time})"
    )
    
    mail(
      to: record.email,
      subject: 'Confirmez votre adresse email - Grenoble Roller',
      template_name: 'confirmation_instructions'
    )
  rescue => e
    Rails.logger.error("Failed to render confirmation email: #{e.message}")
    raise
  end
  
  private
  
  def confirmation_url(user, confirmation_token:)
    user_confirmation_url(
      confirmation_token: confirmation_token,
      host: Rails.application.config.action_mailer.default_url_options[:host]
    )
  end
end
```

**Fichier à créer** : `app/mailers/devise_mailer.rb` (optionnel, Devise utilise le template par défaut si non défini)

---

## 📋 CHECKLIST D'IMPLÉMENTATION

### Phase 1 : Configuration
- [ ] Ajouter `config.confirm_within = 3.days` dans `devise.rb`
- [ ] Ajouter `config.send_email_changed_notification = true`
- [ ] Vérifier `config.mailer_sender`

### Phase 2 : Model User
- [ ] Ajouter `inactive_message`
- [ ] Ajouter `confirmation_token_expired?`
- [ ] Améliorer `send_welcome_email_and_confirmation` avec logging
- [ ] Ajouter callback `after_confirm :log_confirmation_event`

### Phase 3 : SessionsController
- [ ] Remplacer méthode `create` avec détection email non confirmé
- [ ] Ajouter `handle_confirmed_or_unconfirmed`

### Phase 4 : ConfirmationsController
- [ ] Créer `app/controllers/confirmations_controller.rb`
- [ ] Ajouter route dans `config/routes.rb`
- [ ] Implémenter protection anti-énumération
- [ ] Implémenter rate limiting côté contrôleur

### Phase 5 : ApplicationController
- [ ] Remplacer `ensure_email_confirmed` par `check_email_confirmation_status`
- [ ] Ajouter `skip_confirmation_check?`
- [ ] Améliorer messages d'erreur

### Phase 6 : Rack::Attack
- [ ] Ajouter throttle `confirmations/ip`
- [ ] Ajouter throttle `confirmations/email`
- [ ] Améliorer `throttled_responder` avec messages spécifiques

### Phase 7 : Templates
- [ ] Améliorer `app/views/devise/confirmations/new.html.erb`
- [ ] Créer `app/views/devise/confirmations/confirmed.html.erb`

### Phase 8 : DeviseMailer (Optionnel)
- [ ] Créer `app/mailers/devise_mailer.rb` (optionnel)

---

## 🧪 TESTS À CRÉER

### Tests Unitaires

**1. `spec/models/user_spec.rb`**
- Test `inactive_message` pour email non confirmé
- Test `confirmation_token_expired?`
- Test logging après confirmation

**2. `spec/controllers/sessions_controller_spec.rb`**
- Test login avec email confirmé
- Test login avec email non confirmé (période de grâce)
- Test login après expiration période de grâce

**3. `spec/controllers/confirmations_controller_spec.rb`** (NOUVEAU)
- Test renvoi email réussi
- Test rate limiting
- Test protection énumération
- Test confirmation via lien valide
- Test confirmation avec token expiré

**4. `spec/rack_attack_spec.rb`**
- Test throttle confirmations/ip
- Test throttle confirmations/email

---

## 📝 NOTES IMPORTANTES

### Ordre d'Implémentation Recommandé

1. **Phase 1 + Phase 6** : Configuration de base (sans casser l'existant)
2. **Phase 2** : Model User (améliore sans casser)
3. **Phase 4** : ConfirmationsController (nouveau, pas d'impact immédiat)
4. **Phase 3** : SessionsController (testez bien avant production)
5. **Phase 5** : ApplicationController (testez bien)
6. **Phase 7** : Templates (améliore UX)
7. **Phase 8** : DeviseMailer (optionnel, peut attendre)

### Points d'Attention

- ⚠️ **Tester en développement** : Tous les changements avant production
- ⚠️ **Migration DB** : Vérifier que `confirmation_sent_at` existe dans schema
- ⚠️ **Backward compatibility** : Les utilisateurs existants doivent continuer à fonctionner
- ⚠️ **Rate limiting** : Tester que Rack::Attack ne bloque pas les vrais utilisateurs

---

## 🔍 VÉRIFICATIONS AVANT PRODUCTION

- [ ] Tous les tests passent
- [ ] Configuration Devise complète
- [ ] Rate limiting testé et fonctionnel
- [ ] Templates email stylés et en français
- [ ] Messages utilisateur clairs
- [ ] Protection énumération active
- [ ] Logging fonctionnel
- [ ] Documentation mise à jour

---

**Prochaine étape** : Commencer par Phase 1 + Phase 6 (configuration) puis continuer selon l'ordre recommandé.

