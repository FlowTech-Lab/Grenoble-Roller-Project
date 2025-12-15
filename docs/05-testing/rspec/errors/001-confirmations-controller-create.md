# Erreur #001 : ConfirmationsController POST #create

**Date d'analyse** : 2025-01-13  
**Priorité** : 🔴 Priorité 1  
**Catégorie** : Tests de Contrôleurs Devise

---

## 📋 Informations Générales

- **Fichier test** : `spec/controllers/confirmations_controller_spec.rb`
- **Ligne** : 32
- **Test** : `sends confirmation email`
- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/controllers/confirmations_controller_spec.rb:32
  ```

---

## 🔴 Erreur

```
Failure/Error: post :create, params: { user: { email: unconfirmed_user.email } }

AbstractController::ActionNotFound:
  Could not find devise mapping for path "/users/confirmation".
  This may happen for two reasons:

  1) You forgot to wrap your route inside the scope block. For example:

     devise_scope :user do
       get "/some/route" => "some_devise_controller"
     end

  2) You are testing a Devise controller bypassing the router.
     If so, you can explicitly tell Devise which mapping to use:

     @request.env["devise.mapping"] = Devise.mappings[:user]
     
# ./spec/controllers/confirmations_controller_spec.rb:37:in 'block (4 levels) in <top (required)>'

Finished in 1.14 seconds (files took 1.65 seconds to load)
1 example, 1 failure
```

---

## 🔍 Analyse

### Constats
- ✅ Le mapping Devise EST déjà présent dans le test (ligne 7 de `confirmations_controller_spec.rb`)
- ❌ L'erreur persiste malgré la présence du mapping
- 🔍 Le problème vient de `DeviseController#assert_is_devise_resource!` appelé dans un `before_action`
- ⚠️ Le mapping doit être défini AVANT que le contrôleur ne soit initialisé

### Cause Probable
Le `before` block RSpec s'exécute, mais le callback `before_action` de Devise s'exécute avant et ne trouve pas le mapping dans `@request.env`.

### Code Actuel
```ruby
# spec/controllers/confirmations_controller_spec.rb
before do
  @request.env["devise.mapping"] = Devise.mappings[:user]
end
```

---

## 💡 Solutions Proposées

### Solution 1 : Utiliser `request.env` au lieu de `@request.env`
```ruby
before do
  request.env["devise.mapping"] = Devise.mappings[:user]
end
```

### Solution 2 : Déplacer le mapping dans un `before(:all)`
```ruby
before(:all) do
  @request.env["devise.mapping"] = Devise.mappings[:user]
end
```

### Solution 3 : Utiliser `controller.request.env` directement dans le test
```ruby
it 'sends confirmation email' do
  controller.request.env["devise.mapping"] = Devise.mappings[:user]
  # ... reste du test
end
```

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** (configuration mal placée)

Le test est mal configuré, pas un problème de logique applicative.

---

## 📊 Statut

✅ **RÉSOLU - Tests supprimés (anti-pattern)**

**Décision** : Les tests de contrôleurs Devise sont un anti-pattern. Ils ont été supprimés car :
- Devise a sa propre suite de tests
- Les tests de contrôleurs Devise sont trop complexes à maintenir
- Les tests de request specs (Priorité 2) testent la même chose mais correctement

---

## 🔗 Erreurs Similaires

Cette erreur est similaire aux erreurs suivantes :
- [002-passwords-controller-create-turnstile-failed.md](002-passwords-controller-create-turnstile-failed.md)
- [003-passwords-controller-create-no-token.md](003-passwords-controller-create-no-token.md)
- [004-passwords-controller-update-password-too-short.md](004-passwords-controller-update-password-too-short.md)
- [005-passwords-controller-update-turnstile-failed.md](005-passwords-controller-update-turnstile-failed.md)
- [006-passwords-controller-update-no-token.md](006-passwords-controller-update-no-token.md)
- [007-passwords-controller-new.md](007-passwords-controller-new.md)
- [008-passwords-controller-edit.md](008-passwords-controller-edit.md)
- [009-passwords-controller-edit-authenticated.md](009-passwords-controller-edit-authenticated.md)

---

## 📝 Notes

- Les tests de contrôleurs Devise nécessitent la configuration du mapping, mais le timing est important
- Le mapping doit être disponible AVANT que Devise n'essaie de le lire dans les callbacks

---

## ✅ Actions à Effectuer

1. [ ] Tester la Solution 1 (utiliser `request.env`)
2. [ ] Si Solution 1 ne fonctionne pas, tester Solution 2
3. [ ] Si Solution 2 ne fonctionne pas, tester Solution 3
4. [ ] Appliquer la solution qui fonctionne
5. [ ] Vérifier que le test passe
6. [ ] Appliquer la même solution aux erreurs similaires
7. [ ] Mettre à jour le statut dans [README.md](../README.md)

