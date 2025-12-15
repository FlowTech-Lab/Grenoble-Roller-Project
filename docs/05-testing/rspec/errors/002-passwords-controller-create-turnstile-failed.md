# Erreur #002 : PasswordsController POST #create (Turnstile échouée)

**Date d'analyse** : 2025-01-13  
**Priorité** : 🔴 Priorité 1  
**Catégorie** : Tests de Contrôleurs Devise

---

## 📋 Informations Générales

- **Fichier test** : `spec/controllers/passwords_controller_spec.rb`
- **Ligne** : 72
- **Test** : `affiche un message d'erreur` (avec vérification Turnstile échouée)
- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/controllers/passwords_controller_spec.rb:72
  ```

---

## 🔴 Erreur

```
Failure/Error: super

AbstractController::ActionNotFound:
  Could not find devise mapping for path "/users/password".
  This may happen for two reasons:

  1) You forgot to wrap your route inside the scope block. For example:

     devise_scope :user do
       get "/some/route" => "some_devise_controller"
     end

  2) You are testing a Devise controller bypassing the router.
     If so, you can explicitly tell Devise which mapping to use:

     @request.env["devise.mapping"] = Devise.mappings[:user]
     
# ./app/controllers/passwords_controller.rb:16:in 'PasswordsController#require_no_authentication'
# ./spec/controllers/passwords_controller_spec.rb:73:in 'block (4 levels) in <top (required)>'

Finished in 1.16 seconds (files took 1.67 seconds to load)
1 example, 1 failure
```

---

## 🔍 Analyse

### Constats
- ✅ Le mapping Devise EST déjà présent dans le test (ligne 10 de `passwords_controller_spec.rb`)
- ❌ L'erreur persiste malgré la présence du mapping
- 🔍 Même problème que l'erreur #001

### Cause Probable
Identique à l'erreur #001 : le mapping Devise n'est pas disponible au bon moment.

---

## 💡 Solutions Proposées

Même solutions que l'erreur #001 :
- Solution 1 : Utiliser `request.env` au lieu de `@request.env`
- Solution 2 : Déplacer le mapping dans un `before(:all)`
- Solution 3 : Utiliser `controller.request.env` directement dans le test

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
- [003-passwords-controller-create-no-token.md](003-passwords-controller-create-no-token.md)
- [004-passwords-controller-update-password-too-short.md](004-passwords-controller-update-password-too-short.md)
- [005-passwords-controller-update-turnstile-failed.md](005-passwords-controller-update-turnstile-failed.md)
- [006-passwords-controller-update-no-token.md](006-passwords-controller-update-no-token.md)
- [007-passwords-controller-new.md](007-passwords-controller-new.md)
- [008-passwords-controller-edit.md](008-passwords-controller-edit.md)
- [009-passwords-controller-edit-authenticated.md](009-passwords-controller-edit-authenticated.md)

---

## ✅ Actions à Effectuer

1. [ ] Attendre la résolution de l'erreur #001
2. [ ] Appliquer la même solution que l'erreur #001
3. [ ] Vérifier que le test passe
4. [ ] Mettre à jour le statut dans [README.md](../README.md)

