# Analyse des Erreurs RSpec - Étape par Étape

**Date** : 2025-01-13  
**Total** : 431 examples, 219 failures, 9 pending

---

## 📊 Résumé des Erreurs par Catégorie

### 1. Tests de Contrôleurs Devise (8 erreurs) ✅ ANALYSÉ
**Problème** : Tests de contrôleurs Devise qui bypassent le router - mapping Devise mal configuré.

**Erreurs** :
- `spec/controllers/confirmations_controller_spec.rb:32` - POST #create
- `spec/controllers/passwords_controller_spec.rb:72` - POST #create (Turnstile échouée)
- `spec/controllers/passwords_controller_spec.rb:93` - POST #create (sans token)
- `spec/controllers/passwords_controller_spec.rb:125` - PUT #update (mot de passe trop court)
- `spec/controllers/passwords_controller_spec.rb:160` - PUT #update (Turnstile échouée)
- `spec/controllers/passwords_controller_spec.rb:182` - PUT #update (sans token)
- `spec/controllers/passwords_controller_spec.rb:199` - GET #new
- `spec/controllers/passwords_controller_spec.rb:212` - GET #edit
- `spec/controllers/passwords_controller_spec.rb:238` - GET #edit (utilisateur connecté)

**Cause** : Le mapping Devise est défini dans `before do`, mais le callback `before_action` de Devise s'exécute avant et ne trouve pas le mapping.

**Solution** : Utiliser `request.env` au lieu de `@request.env` ou déplacer le mapping dans un contexte plus tôt.

**Type** : ❌ **PROBLÈME DE TEST** (configuration mal placée)

**Statut** : 🟡 **SOLUTION À TESTER**

---

### 2. Tests de Request Devise (5 erreurs) ✅ ANALYSÉ
**Problème** : Les tests comptent 2 emails au lieu d'1 car le user est créé avec un callback qui envoie un email.

**Erreurs** :
- `spec/requests/passwords_spec.rb:28` - POST /users/password envoie 2 emails au lieu d'1 ✅ ANALYSÉ
- `spec/requests/passwords_spec.rb:104` - PUT /users/password (mot de passe trop court)
- `spec/requests/passwords_spec.rb:137` - PUT /users/password (Turnstile échouée)
- `spec/requests/passwords_spec.rb:157` - PUT /users/password (sans token)

**Cause** : Le `let(:user)` crée le user avec `after_create :send_welcome_email_and_confirmation` qui envoie un email, puis le `post` envoie un autre email.

**Solution** : Nettoyer les emails dans le `before` block AVANT de créer le user, ou stub le callback.

**Type** : ❌ **PROBLÈME DE TEST** (emails non nettoyés)

**Statut** : 🟢 **SOLUTION IDENTIFIÉE**

---

### 3. Tests de Sessions (2 erreurs)
**Erreurs** :
- `spec/controllers/sessions_controller_spec.rb:56` - Grace period avec warning
- `spec/controllers/sessions_controller_spec.rb:66` - Grace period expirée

**À analyser** : Exécuter les tests pour voir l'erreur exacte.

**Type** : ⚠️ **À ANALYSER**

---

### 4. Tests Feature (Capybara) (19 erreurs)
**Erreurs** :
- `spec/features/event_attendance_spec.rb` (8 erreurs)
- `spec/features/event_management_spec.rb` (3 erreurs)
- `spec/features/mes_sorties_spec.rb` (8 erreurs)

**À analyser** : Tests Capybara qui nécessitent probablement une configuration JavaScript ou des helpers.

**Type** : ⚠️ **À ANALYSER**

---

### 5. Tests de Jobs (3 erreurs)
**Erreurs** :
- `spec/jobs/event_reminder_job_spec.rb:25` - Envoi de rappel
- `spec/jobs/event_reminder_job_spec.rb:38` - Rappels à différents moments
- `spec/jobs/event_reminder_job_spec.rb:110` - Rappels multiples

**À analyser** : Problèmes avec les jobs d'envoi d'emails.

**Type** : ⚠️ **À ANALYSER**

---

### 6. Tests de Mailers (30+ erreurs)
**Erreurs** :
- `spec/mailers/event_mailer_spec.rb` (4 erreurs)
- `spec/mailers/membership_mailer_spec.rb` (8 erreurs)
- `spec/mailers/order_mailer_spec.rb` (20+ erreurs)
- `spec/mailers/user_mailer_spec.rb` (3 erreurs)

**Problème probable** : Les templates de mailers utilisent probablement des helpers `_path` au lieu de `_url`, ou des associations non chargées.

**Type** : ⚠️ **PROBLÈME DE LOGIQUE** (templates ou helpers)

---

### 7. Tests de Modèles (100+ erreurs)
**Erreurs** :
- `spec/models/attendance_spec.rb` (20+ erreurs)
- `spec/models/audit_log_spec.rb` (6 erreurs)
- `spec/models/contact_message_spec.rb` (3 erreurs)
- `spec/models/event_spec.rb` (20+ erreurs)
- `spec/models/event/initiation_spec.rb` (15+ erreurs)
- `spec/models/organizer_application_spec.rb` (5 erreurs)
- `spec/models/product_spec.rb` (2 erreurs)
- Et autres...

**Problème probable** : Validations, associations, ou logique métier qui a changé.

**Type** : ⚠️ **PROBLÈME DE LOGIQUE** (modèles)

---

### 8. Tests de Policies (1 erreur)
**Erreurs** :
- `spec/policies/event_policy_spec.rb:153` - Scope pour guests

**À analyser** : Problème de scope Pundit.

**Type** : ⚠️ **À ANALYSER**

---

### 9. Tests de Request (20+ erreurs)
**Erreurs** :
- `spec/requests/attendances_spec.rb:60` - Toggle reminder
- `spec/requests/event_email_integration_spec.rb` (3 erreurs)
- `spec/requests/events_spec.rb` (6 erreurs)
- `spec/requests/initiations_spec.rb` (5 erreurs)
- `spec/requests/memberships_spec.rb:101` - Create multiple payments
- `spec/requests/pages_spec.rb:9` - GET /association
- `spec/requests/registrations_spec.rb` (15 erreurs)

**Problème probable** : Logique des contrôleurs ou configuration de test.

**Type** : ⚠️ **PROBLÈME DE LOGIQUE** (contrôleurs)

---

## 🔍 Analyse Détaillée - Erreur #1

### ConfirmationsController POST #create

**Fichier** : `spec/controllers/confirmations_controller_spec.rb:32`

**Erreur** :
```
AbstractController::ActionNotFound:
  Could not find devise mapping for path "/users/confirmation".
```

**Analyse** :
- ✅ Le mapping Devise EST déjà présent dans le test (ligne 7)
- ❌ L'erreur persiste malgré la présence du mapping
- 🔍 Le problème vient de `DeviseController#assert_is_devise_resource!` appelé dans un `before_action`
- ⚠️ Le mapping doit être défini AVANT que le contrôleur ne soit initialisé

**Cause probable** : Le `before` block RSpec s'exécute, mais le callback `before_action` de Devise s'exécute avant et ne trouve pas le mapping dans `@request.env`.

**Solution à tester** :
1. Utiliser `request.env` au lieu de `@request.env`
2. Déplacer le mapping dans un `before(:all)` 
3. Ou utiliser `controller.request.env` directement dans le test

**Type** : ❌ **PROBLÈME DE TEST** (configuration mal placée)

**Statut** : 🟡 **SOLUTION À TESTER**

---

## 🔍 Analyse Détaillée - Erreur #2

### PasswordsController POST #create (Turnstile échouée)

**Fichier** : `spec/controllers/passwords_controller_spec.rb:72`

**Erreur** : Même problème que l'erreur #1 (mapping Devise)

**Solution** : Même solution que l'erreur #1

**Type** : ❌ **PROBLÈME DE TEST** (configuration mal placée)

**Statut** : 🟡 **SOLUTION À TESTER**

---

## 🔍 Analyse Détaillée - Erreur #3

### Password Reset POST /users/password

**Fichier** : `spec/requests/passwords_spec.rb:28`

**Erreur** :
```
expected `ActionMailer::Base.deliveries.count` to have changed by 1, but was changed by 2
```

**Analyse** :
- ✅ Le test attend 1 email (réinitialisation de mot de passe)
- ❌ Le contrôleur envoie 2 emails
- 🔍 Le `let(:user)` crée le user AVANT le test (ligne 7-16)
- 🔍 Le callback `after_create :send_welcome_email_and_confirmation` (user.rb ligne 152) envoie un email lors de la création
- ⚠️ Le test compte 2 emails : 1 de création (welcome) + 1 de réinitialisation

**Cause** : Le user est créé avec `let(:user)`, le callback `after_create` envoie un email de bienvenue, puis le `post` envoie un email de réinitialisation. Le test compte les 2 emails.

**Solution** :
1. Nettoyer les emails dans le `before` block AVANT de créer le user :
```ruby
before do
  ActionMailer::Base.deliveries.clear
  # ... reste du code
end
```
2. OU stub le callback `send_welcome_email_and_confirmation` pour éviter l'email de bienvenue
3. OU ajuster le test pour compter seulement les emails envoyés pendant le `post`

**Type** : ❌ **PROBLÈME DE TEST** (emails non nettoyés)

**Statut** : 🟢 **SOLUTION IDENTIFIÉE**

---

## 📋 Plan d'Action

### Priorité 1 : Tests de Contrôleurs Devise (8 erreurs)
1. ✅ Analyser l'erreur #1 (ConfirmationsController)
2. ✅ Analyser l'erreur #2 (PasswordsController)
3. ⏳ Tester la solution : utiliser `request.env` au lieu de `@request.env`
4. ⏳ Appliquer la correction à tous les tests de contrôleurs Devise

### Priorité 2 : Tests de Request Devise (5 erreurs)
1. ✅ Analyser l'erreur #3 (Password Reset)
2. ⏳ Corriger le test en nettoyant les emails dans le `before` block
3. ⏳ Appliquer la correction aux autres tests similaires

### Priorité 3 : Autres erreurs
1. ⏳ Analyser les tests Feature
2. ⏳ Analyser les tests de Mailers
3. ⏳ Analyser les tests de Modèles
4. ⏳ Analyser les tests de Request

---

## 📝 Notes

- Les tests de contrôleurs Devise nécessitent la configuration du mapping, mais le timing est important
- Les tests de request passent mais ont des problèmes de logique (emails multiples)
- Les tests Feature nécessitent probablement une configuration JavaScript
- Les tests de Mailers ont probablement des problèmes avec les helpers `_path` vs `_url`
- Les tests de Modèles ont probablement des problèmes de validations ou associations

---

## 🔄 Prochaines Étapes

1. **Tester la solution pour les contrôleurs Devise** : Utiliser `request.env` au lieu de `@request.env`
2. **Corriger les tests de request Devise** : Nettoyer les emails dans le `before` block
3. **Analyser les autres catégories d'erreurs** une par une
