# Erreur #206-219 : Registrations Request Specs

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟡 Priorité 9  
**Catégorie** : Request Spec

---

## 📋 Informations Générales

Ce fichier regroupe 13 erreurs liées aux inscriptions (registrations) :

| # | Ligne | Test | Commande |
|---|-------|------|----------|
| 206 | 36 | POST /users with valid parameters and RGPD consent creates a new user | `rspec ./spec/requests/registrations_spec.rb:36` |
| 207 | 42 | POST /users with valid parameters and RGPD consent redirects to events page | `rspec ./spec/requests/registrations_spec.rb:42` |
| 208 | 47 | POST /users with valid parameters and RGPD consent sets a personalized welcome message | `rspec ./spec/requests/registrations_spec.rb:47` |
| 209 | 54 | POST /users with valid parameters and RGPD consent sends welcome email | `rspec ./spec/requests/registrations_spec.rb:54` |
| 210 | 61 | POST /users with valid parameters and RGPD consent sends confirmation email | `rspec ./spec/requests/registrations_spec.rb:61` |
| 211 | 68 | POST /users with valid parameters and RGPD consent creates user with correct attributes | `rspec ./spec/requests/registrations_spec.rb:68` |
| 212 | 78 | POST /users with valid parameters and RGPD consent allows immediate access (grace period) | `rspec ./spec/requests/registrations_spec.rb:78` |
| 213 | 106 | POST /users without RGPD consent stays on sign_up page (does not redirect to /users) | `rspec ./spec/requests/registrations_spec.rb:106` |
| 214 | 128 | POST /users with invalid email displays email validation error | `rspec ./spec/requests/registrations_spec.rb:128` |
| 215 | 143 | POST /users with missing first_name displays first_name validation error | `rspec ./spec/requests/registrations_spec.rb:143` |
| 216 | 158 | POST /users with password too short displays password validation error with 12 characters | `rspec ./spec/requests/registrations_spec.rb:158` |
| 217 | 173 | POST /users with missing skill_level displays skill_level validation error | `rspec ./spec/requests/registrations_spec.rb:173` |
| 218 | 192 | POST /users with duplicate email displays email taken error | `rspec ./spec/requests/registrations_spec.rb:192` |

- **Fichier test** : `spec/requests/registrations_spec.rb`

---

## 🔴 Erreurs

```
[Messages d'erreur à capturer lors de l'exécution des tests]
```

---

## 🔍 Analyse

### Constats
- ⏳ Erreurs non encore analysées
- 🔍 Erreurs variées : création utilisateur, emails, validations, RGPD, grace period

### Cause Probable
Problèmes possibles :
- Configuration Devise pour les inscriptions
- Envoi d'emails (welcome, confirmation)
- Validations du modèle User
- Gestion du consentement RGPD
- Grace period pour les utilisateurs non confirmés

### Code Actuel
```ruby
# spec/requests/registrations_spec.rb
```

---

## 💡 Solutions Proposées

À déterminer après analyse.

---

## 🎯 Type de Problème

⏳ **À ANALYSER** (probablement ⚠️ **PROBLÈME DE LOGIQUE**)

---

## 📊 Statut

⏳ **À ANALYSER**

---

## 🔗 Erreurs Similaires

Cette erreur est similaire aux erreurs suivantes :
- [081-mailers-user-mailer.md](081-mailers-user-mailer.md) (erreurs liées aux emails utilisateur)
- [182-models-user.md](182-models-user.md) (erreurs liées au modèle User)

---

## 📝 Notes

- Erreurs variées couvrant plusieurs aspects de l'inscription
- Certaines erreurs peuvent être liées à la configuration Devise
- Vérifier la configuration ActionMailer pour les emails

---

## ✅ Actions à Effectuer

1. [ ] Exécuter les 13 tests pour capturer les erreurs exactes
2. [ ] Analyser chaque erreur individuellement
3. [ ] Proposer des solutions
4. [ ] Mettre à jour le statut dans [README.md](../README.md)

