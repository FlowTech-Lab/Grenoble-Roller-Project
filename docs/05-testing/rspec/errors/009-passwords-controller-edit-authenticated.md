# Erreur #009 : PasswordsController GET #edit (utilisateur connecté)

**Date d'analyse** : 2025-01-13  
**Priorité** : 🔴 Priorité 1  
**Catégorie** : Tests de Contrôleurs Devise

---

## 📋 Informations Générales

- **Fichier test** : `spec/controllers/passwords_controller_spec.rb`
- **Ligne** : 238
- **Test** : `permet la réinitialisation si un token est présent` (avec un utilisateur connecté)
- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/controllers/passwords_controller_spec.rb:238
  ```

---

## 🔴 Erreur

```
Failure/Error: before { sign_in user }

RuntimeError:
  Could not find a valid mapping for #<User id: 9779, address: nil, avatar_url: nil, bio: nil, can_be_volunteer: false, city: nil, confirmation_token_last_used_at: nil, confirmed_ip: nil, confirmed_user_agent: nil, created_at: "2025-12-14 23:44:09.763316000 +0000", date_of_birth: nil, email: [FILTERED], first_name: "User1", last_name: "Tester1", phone: "0612345678", postal_code: nil, role_id: 36, skill_level: "intermediate", updated_at: "2025-12-14 23:44:09.763316000 +0000", wants_email_info: [FILTERED], wants_events_mail: true, wants_initiation_mail: true, wants_whatsapp: false>
# ./spec/controllers/passwords_controller_spec.rb:230:in 'block (4 levels) in <top (required)>'

Finished in 0.67345 seconds (files took 1.55 seconds to load)
1 example, 1 failure
```

---

## 🔍 Analyse

### Constats
- ✅ Le mapping Devise EST déjà présent dans le test (ligne 10)
- ❌ L'erreur est différente : `RuntimeError: Could not find a valid mapping` lors de `sign_in user`
- 🔍 Le problème se produit dans le `before` block qui appelle `sign_in user`
- ⚠️ Le mapping Devise n'est pas disponible au moment où `sign_in` est appelé

### Cause Probable
Le mapping Devise est défini dans `@request.env`, mais `sign_in` (méthode Devise::Test::ControllerHelpers) ne peut pas le trouver. Le mapping doit être disponible AVANT l'appel à `sign_in`.

---

## 💡 Solutions Proposées

### Solution 1 : Utiliser `request.env` au lieu de `@request.env`
```ruby
before do
  request.env["devise.mapping"] = Devise.mappings[:user]
  allow(controller).to receive(:devise_mapping).and_return(Devise.mappings[:user])
end
```

### Solution 2 : Définir le mapping avant `sign_in`
```ruby
it 'permet la réinitialisation si un token est présent' do
  request.env["devise.mapping"] = Devise.mappings[:user]
  sign_in user
  # ... reste du test
end
```

### Solution 3 : Utiliser `controller.request.env` dans le `before` block du test
```ruby
before do
  controller.request.env["devise.mapping"] = Devise.mappings[:user]
  sign_in user
end
```

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** (configuration mal placée)

---

## 📊 Statut

🟡 **SOLUTION À TESTER**

---

## 🔗 Erreurs Similaires

Cette erreur est similaire à :
- [001-confirmations-controller-create.md](001-confirmations-controller-create.md)
- [002-passwords-controller-create-turnstile-failed.md](002-passwords-controller-create-turnstile-failed.md)

---

## ✅ Actions à Effectuer

1. [ ] Attendre la résolution de l'erreur #001
2. [ ] Appliquer la même solution que l'erreur #001
3. [ ] Vérifier que le test passe
4. [ ] Mettre à jour le statut dans [README.md](../README.md)

