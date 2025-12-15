# Erreur #081-083 : Mailers UserMailer (3 erreurs)

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟢 Priorité 6  
**Catégorie** : Tests de Mailers

---

## 📋 Informations Générales

- **Fichier test** : `spec/mailers/user_mailer_spec.rb`
- **Lignes** : 17, 25, 30
- **Tests** :
  1. Ligne 17 : `UserMailer#welcome_email includes user first name in body`
  2. Ligne 25 : `UserMailer#welcome_email has HTML content`
  3. Ligne 30 : `UserMailer#welcome_email has text content as fallback`

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/mailers/user_mailer_spec.rb
  ```

---

## 🔴 Erreur (initiale)

- Le `UserMailer#welcome_email` réel n’incluait pas le prénom dans les vues, et les tests ne géraient pas le body encodé / multipart.

---

## 🔍 Analyse

### Constats
- ✅ Le mailer assigne `@user` et `@events_url = events_url`.
- ✅ Les vues HTML / texte étaient génériques (“Bonjour,”) sans prénom.
- ❌ Les tests vérifiaient `user.first_name` dans le body sans décoder et sans que la vue l’affiche réellement.

---

## 💡 Solutions appliquées

1. Mise à jour des vues :
   - HTML : `Bonjour <%= @user.first_name || @user.email %>,`
   - texte : `Bonjour <%= @user.first_name || @user.email %>,`
2. Dans le spec :
   - création d’un `user` avec rôle valide,
   - décodage du body (parts HTML + texte),
   - vérification de la présence du prénom et du lien `/events`.

---

## 🎯 Type de Problème

⚠️ **PROBLÈME DE LOGIQUE / TEST** (vue incomplète + test naïf sur body encodé) – corrigé.

---

## 📊 Statut

✅ **RÉSOLU** – Tous les tests `user_mailer_spec` passent.

---

## 🔗 Erreurs Similaires

Cette erreur est similaire à :
- [039-mailers-event-mailer.md](039-mailers-event-mailer.md)
- [043-mailers-membership-mailer.md](043-mailers-membership-mailer.md)
- [051-mailers-order-mailer.md](051-mailers-order-mailer.md)

---

## ✅ Actions à Effectuer

1. [ ] Exécuter les tests pour voir les erreurs exactes
2. [ ] Vérifier les templates de mailers
3. [ ] Analyser chaque erreur et documenter
4. [ ] Identifier le type de problème (test ou logique)
5. [ ] Proposer des solutions
6. [ ] Mettre à jour le statut dans [README.md](../README.md)

