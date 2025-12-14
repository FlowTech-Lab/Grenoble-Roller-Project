# Erreur #006 : PasswordsController PUT #update (sans token Turnstile)

**Date d'analyse** : 2025-01-13  
**Priorité** : 🔴 Priorité 1  
**Catégorie** : Tests de Contrôleurs Devise

---

## 📋 Informations Générales

- **Fichier test** : `spec/controllers/passwords_controller_spec.rb`
- **Ligne** : 182
- **Test** : `bloque la réinitialisation du mot de passe` (sans token Turnstile)
- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/controllers/passwords_controller_spec.rb:182
  ```

---

## 🔴 Erreur

```
AbstractController::ActionNotFound:
  Could not find devise mapping for path "/users/password".
```

---

## 🔍 Analyse

### Constats
- ✅ Le mapping Devise EST déjà présent dans le test
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
- [002-passwords-controller-create-turnstile-failed.md](002-passwords-controller-create-turnstile-failed.md)

---

## ✅ Actions à Effectuer

1. [ ] Attendre la résolution de l'erreur #001
2. [ ] Appliquer la même solution que l'erreur #001
3. [ ] Vérifier que le test passe
4. [ ] Mettre à jour le statut dans [README.md](../README.md)

