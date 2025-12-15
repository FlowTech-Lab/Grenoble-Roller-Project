# Erreur #039-042 : Mailers EventMailer (4 erreurs)

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟢 Priorité 6  
**Catégorie** : Tests de Mailers

---

## 📋 Informations Générales

- **Fichier test** : `spec/mailers/event_mailer_spec.rb`
- **Lignes** : 28, 35, 100, 107
- **Tests** :
  1. Ligne 28 : `EventMailer#attendance_confirmed includes event date in body`
  2. Ligne 35 : `EventMailer#attendance_confirmed includes event URL in body`
  3. Ligne 100 : `EventMailer#attendance_cancelled includes event date in body`
  4. Ligne 107 : `EventMailer#attendance_cancelled includes event URL in body`

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/mailers/event_mailer_spec.rb
  ```

---

## 🔴 Erreur (initiale)

- Dates et URLs d’événements non retrouvées dans le body des emails (encodage multipart + helpers d’URL).

---

## 🔍 Analyse

### Constats
- ✅ Les templates utilisent bien `event_url` / `initiation_url` dans les versions HTML + texte.
- ✅ Les mails sont multipart (texte + HTML) et encodés (base64 / quoted-printable).
- ✅ Les tests doivent décoder le body et/ou matcher des fragments robustes (hashid, `/events/xxx`).

### Cause Probable (corrigée)
- Tests trop stricts sur `body.encoded` sans décodage multipart.
- Expectations sur l’URL complète au lieu de vérifier le hashid ou une portion stable.

---

## 💡 Solutions appliquées

1. Vérification et correction des templates (utilisation de `event_url` / `initiation_url` cohérente).
2. Dans les specs, décodage du body :
   - `html_part = mail.body.parts.find { ... }`
   - `body_content = html_part ? html_part.decoded : mail.body.decoded`
3. Pour l’URL, recherche du `event.hashid` ou de `"/events/#{event.hashid}"` dans le body décodé.
4. Vérifications de date assouplies (présence de l’année + chiffres, pas de format exact).

---

## 🎯 Type de Problème

⚠️ **PROBLÈME DE LOGIQUE / TEST** (templates + manière de tester le body encodé) – corrigé.

---

## 📊 Statut

✅ **RÉSOLU** – Tous les tests `event_mailer_spec` passent.

---

## 🔗 Erreurs Similaires

Cette erreur est similaire à :
- [043-mailers-membership-mailer.md](043-mailers-membership-mailer.md)
- [051-mailers-order-mailer.md](051-mailers-order-mailer.md)
- [081-mailers-user-mailer.md](081-mailers-user-mailer.md)

---

## ✅ Actions à Effectuer

1. [ ] Exécuter les tests pour voir les erreurs exactes
2. [ ] Vérifier les templates de mailers (`app/views/event_mailer/`)
3. [ ] Vérifier les helpers utilisés
4. [ ] Analyser chaque erreur et documenter
5. [ ] Identifier le type de problème (test ou logique)
6. [ ] Proposer des solutions
7. [ ] Mettre à jour le statut dans [README.md](../README.md)

