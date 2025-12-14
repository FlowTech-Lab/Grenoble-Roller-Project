# Erreur #010 : Password Reset POST /users/password (2 emails au lieu d'1)

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟠 Priorité 2  
**Catégorie** : Tests de Request Devise

---

## 📋 Informations Générales

- **Fichier test** : `spec/requests/passwords_spec.rb`
- **Ligne** : 28
- **Test** : `envoie un email de réinitialisation` (avec vérification Turnstile réussie)
- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/requests/passwords_spec.rb:28
  ```

---

## 🔴 Erreur

```
expected `ActionMailer::Base.deliveries.count` to have changed by 1, but was changed by 2
```

---

## 🔍 Analyse

### Constats
- ✅ Le test attend 1 email (réinitialisation de mot de passe)
- ❌ Le contrôleur envoie 2 emails
- 🔍 Le `let(:user)` crée le user AVANT le test (ligne 7-16 de `passwords_spec.rb`)
- 🔍 Le callback `after_create :send_welcome_email_and_confirmation` (user.rb ligne 152) envoie un email lors de la création
- ⚠️ Le test compte 2 emails : 1 de création (welcome) + 1 de réinitialisation

### Cause
Le user est créé avec `let(:user)`, le callback `after_create` envoie un email de bienvenue, puis le `post` envoie un email de réinitialisation. Le test compte les 2 emails.

### Code Actuel
```ruby
# spec/requests/passwords_spec.rb
let(:user) do
  user = build(:user,
               email: 'test@example.com',
               password: 'password12345',
               confirmed_at: Time.current,
               role: role)
  allow(user).to receive(:send_confirmation_instructions).and_return(true)
  user.save!
  user
end

describe 'POST /users/password (demande de réinitialisation)' do
  context 'avec vérification Turnstile réussie' do
    before do
      # Simuler une vérification Turnstile réussie
      allow_any_instance_of(PasswordsController).to receive(:verify_turnstile).and_return(true)
      # Configurer ActionMailer pour les tests
      ActionMailer::Base.delivery_method = :test
      ActionMailer::Base.perform_deliveries = true
    end

    it 'envoie un email de réinitialisation' do
      expect do
        post user_password_path, params: { user: { email: user.email } }
      end.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end
end
```

---

## 💡 Solutions Proposées

### Solution 1 : Nettoyer les emails dans le `before` block AVANT de créer le user
```ruby
before do
  ActionMailer::Base.deliveries.clear
  # Simuler une vérification Turnstile réussie
  allow_any_instance_of(PasswordsController).to receive(:verify_turnstile).and_return(true)
  # Configurer ActionMailer pour les tests
  ActionMailer::Base.delivery_method = :test
  ActionMailer::Base.perform_deliveries = true
end
```

### Solution 2 : Stub le callback `send_welcome_email_and_confirmation`
```ruby
let(:user) do
  user = build(:user,
               email: 'test@example.com',
               password: 'password12345',
               confirmed_at: Time.current,
               role: role)
  allow(user).to receive(:send_confirmation_instructions).and_return(true)
  allow(user).to receive(:send_welcome_email_and_confirmation).and_return(true)
  user.save!
  user
end
```

### Solution 3 : Ajuster le test pour compter seulement les emails envoyés pendant le `post`
```ruby
it 'envoie un email de réinitialisation' do
  initial_count = ActionMailer::Base.deliveries.count
  post user_password_path, params: { user: { email: user.email } }
  expect(ActionMailer::Base.deliveries.count).to eq(initial_count + 1)
end
```

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** (emails non nettoyés)

Le test est mal configuré, pas un problème de logique applicative.

---

## 📊 Statut

🟢 **SOLUTION IDENTIFIÉE**

**Solution recommandée** : Solution 1 (nettoyer les emails dans le `before` block)

---

## 🔗 Erreurs Similaires

Cette erreur est similaire aux erreurs suivantes :
- [011-passwords-request-update-password-too-short.md](011-passwords-request-update-password-too-short.md)
- [012-passwords-request-update-turnstile-failed.md](012-passwords-request-update-turnstile-failed.md)
- [013-passwords-request-update-no-token.md](013-passwords-request-update-no-token.md)

---

## 📝 Notes

- Les tests de request passent mais ont des problèmes de logique (emails multiples)
- Le callback `after_create :send_welcome_email_and_confirmation` est défini dans `app/models/user.rb` ligne 152
- `ActionMailer::Base.deliveries.clear` est déjà appelé dans `spec/rails_helper.rb` ligne 105 dans un `after(:each)`, mais c'est trop tard car le user est créé dans `let(:user)` qui s'exécute avant

---

## ✅ Actions à Effectuer

1. [ ] Appliquer la Solution 1 (nettoyer les emails dans le `before` block)
2. [ ] Vérifier que le test passe
3. [ ] Appliquer la même solution aux erreurs similaires
4. [ ] Mettre à jour le statut dans [README.md](../README.md)

