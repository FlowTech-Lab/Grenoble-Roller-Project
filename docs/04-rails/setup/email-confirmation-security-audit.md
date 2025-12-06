# 🔒 Audit Sécurité - Confirmation Email & Login

**Date** : 2025-01-20  
**Status** : ⚠️ À améliorer

---

## 📋 État Actuel

### ✅ Ce qui est en place

1. **Module Devise `:confirmable` activé**
   - Colonnes DB : `confirmed_at`, `confirmation_token`, `unconfirmed_email`
   - Configuration : `allow_unconfirmed_access_for = 2.days`

2. **Envoi automatique email de confirmation**
   - Appelé après création de compte (`after_create`)
   - Template HTML et texte en français

3. **Protection des actions critiques**
   - `ensure_email_confirmed` dans `ApplicationController`
   - Utilisé dans `OrdersController` et `EventsController`
   - Message d'erreur explicite si email non confirmé

4. **Période de grâce**
   - 2 jours d'accès sans confirmation
   - Méthode `active_for_authentication?` permet connexion

5. **SMTP configuré**
   - Production : IONOS SMTP (port 465, SSL)
   - Development : File storage (`tmp/mails/`)

---

## ⚠️ Ce qui manque / À améliorer

### 1. Gestion Login avec Email Non Confirmé

**Problème actuel** :
- ❌ Aucune détection au login si email non confirmé
- ❌ Pas de message informatif après connexion
- ❌ Pas de lien direct pour renvoyer l'email de confirmation
- ❌ Pas de gestion spécifique si période de grâce expirée

**Page de renvoi existante** :
- ✅ Route : `/users/confirmation/new`
- ⚠️ Template basique (pas stylé)
- ⚠️ Lien en anglais : "Didn't receive confirmation instructions?"

**Solution nécessaire** :
```ruby
# Dans SessionsController#create
# 1. Détecter si email non confirmé après login réussi
# 2. Afficher message informatif avec lien renvoi
# 3. Gérer cas période de grâce expirée
```

---

### 2. Sécurité & Protection Anti-Abus

**Existant** :
- ✅ `Rack::Attack` configuré (logins, registrations, password_resets)
- ✅ Rate limiting global (300 req/min par IP)

**Manquants** :
- ❌ Pas de rate limiting pour renvois email de confirmation
- ❌ Pas de protection contre énumération d'emails (email existe vs n'existe pas)
- ❌ Pas de protection spécifique contre force brute sur tokens
- ❌ Pas de limite sur nombre de renvois par email/IP spécifique

**Recommandations** :
- Étendre `Rack::Attack` pour limiter renvois confirmation email
- Logger les tentatives suspectes
- Limiter nombre de renvois par email/IP (au-delà du rate limiting global)

---

### 3. Configuration Devise

**Paramètres à optimiser** :
- `confirm_within` : Non configuré (pas de limite d'expiration token)
- Gestion des tokens expirés : Non spécifique
- Messages d'erreur : À améliorer (token invalide, expiré, déjà utilisé)

---

### 4. UX & Messages Utilisateur

**À améliorer** :
- Page renvoi confirmation : Stylée et en français
- Messages après login : Plus explicites
- Gestion erreurs confirmation : Messages clairs pour chaque cas

---

## 🎯 Plan d'Action Recommandé

### Phase 1 : Amélioration Login (Priorité Haute)

1. **Modifier `SessionsController`** :
   ```ruby
   def create
     super do |resource|
       if resource.persisted? && !resource.confirmed?
         # Afficher message + lien renvoi
       end
     end
   end
   ```

2. **Créer helper pour afficher banner** :
   ```ruby
   # app/helpers/application_helper.rb
   def email_confirmation_banner(user)
     return unless user && !user.confirmed?
     # Banner avec message + lien
   end
   ```

3. **Améliorer page renvoi** :
   - Template stylé en français
   - Messages clairs
   - Protection rate limiting

### Phase 2 : Sécurité (Priorité Haute)

1. **Configurer Rack::Attack** :
   ```ruby
   # Limiter renvois confirmation email
   # Protection énumération emails
   # Rate limiting par IP/email
   ```

2. **Logging & Monitoring** :
   - Logger tentatives confirmation
   - Logger renvois email
   - Alertes sur anomalies

### Phase 3 : Configuration Optimale (Priorité Moyenne)

1. **Configurer `confirm_within`** :
   - Durée recommandée : 7 jours
   - Gérer tokens expirés

2. **Améliorer messages d'erreur** :
   - Token invalide
   - Token expiré
   - Token déjà utilisé

---

## 📝 Références

**⚠️ Mise à jour** : Le prompt Perplexity a été utilisé pour générer le guide complet.  
Voir maintenant : `docs/04-rails/setup/devise-email-security-guide.md` (guide complet)  
Ou : `docs/04-rails/setup/plan-implementation-email-security.md` (plan d'implémentation)

**Points clés** :
1. Meilleures pratiques sécurité confirmation email
2. Configuration Devise optimale
3. Gestion UX login avec email non confirmé
4. Protection anti-abus (rate limiting, énumération)
5. Gestion erreurs SMTP robuste
6. Templates email sécurisés

---

## 🔍 Fichiers à Modifier

### Créer/Modifier
- `app/controllers/sessions_controller.rb` : Détection email non confirmé
- `app/controllers/confirmations_controller.rb` : Améliorer gestion renvoi
- `app/helpers/application_helper.rb` : Helper banner confirmation
- `app/views/devise/confirmations/new.html.erb` : Styliser page renvoi
- `config/initializers/rack_attack.rb` : Rate limiting (si existe)
- `config/initializers/devise.rb` : Configurer `confirm_within`

### Tests à Créer
- `spec/controllers/sessions_controller_spec.rb` : Test login email non confirmé
- `spec/controllers/confirmations_controller_spec.rb` : Test renvoi email
- `spec/models/user_spec.rb` : Test période de grâce
- `spec/requests/email_confirmation_spec.rb` : Tests d'intégration

---

## ✅ Checklist Validation

Avant mise en production :

- [ ] Détection email non confirmé au login fonctionnelle
- [ ] Messages utilisateur clairs et en français
- [ ] Lien renvoi email visible et fonctionnel
- [ ] Rate limiting configuré (Rack::Attack)
- [ ] Protection énumération emails active
- [ ] `confirm_within` configuré
- [ ] Gestion erreurs complète (token invalide, expiré)
- [ ] Tests écrits et passants
- [ ] Logging et monitoring en place
- [ ] Templates email stylés et sécurisés
- [ ] Documentation mise à jour

---

**Prochaine étape** : Suivre le plan d'implémentation dans `plan-implementation-email-security.md`

