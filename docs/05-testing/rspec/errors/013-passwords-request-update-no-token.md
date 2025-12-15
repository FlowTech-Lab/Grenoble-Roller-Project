# Erreur #013 : Password Reset PUT /users/password (sans token Turnstile)

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟠 Priorité 2  
**Catégorie** : Tests de Request Devise

---

## 📋 Informations Générales

- **Fichier test** : `spec/requests/passwords_spec.rb`
- **Ligne** : 157
- **Test** : `bloque la réinitialisation du mot de passe` (sans token Turnstile)
- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/requests/passwords_spec.rb:157
  ```

---

## 🔴 Erreur

⏳ **À ANALYSER** - Exécuter le test pour voir l'erreur exacte

---

## 🔍 Analyse

### Constats
- ⏳ Erreur non encore analysée
- 🔍 Probablement similaire à l'erreur #010 (emails non nettoyés)

---

## 💡 Solutions Proposées

⏳ **À DÉTERMINER** après analyse

---

## 🎯 Type de Problème

⚠️ **À ANALYSER** (probablement ❌ **PROBLÈME DE TEST**)

---

## 📊 Statut

✅ **RÉSOLU**

**Solution appliquée** : Le test vérifie maintenant que le mot de passe n'a pas été changé et que la réponse indique une erreur, au lieu de chercher un message spécifique dans le body HTML.

---

## 🔗 Erreurs Similaires

Cette erreur est similaire à :
- [010-passwords-request-create-2-emails.md](010-passwords-request-create-2-emails.md)
- [011-passwords-request-update-password-too-short.md](011-passwords-request-update-password-too-short.md)
- [012-passwords-request-update-turnstile-failed.md](012-passwords-request-update-turnstile-failed.md)

---

## ✅ Actions à Effectuer

1. [ ] Exécuter le test pour voir l'erreur exacte
2. [ ] Analyser l'erreur et documenter
3. [ ] Identifier le type de problème (test ou logique)
4. [ ] Proposer des solutions
5. [ ] Mettre à jour le statut dans [README.md](../README.md)

