# Erreur #039-042 : Mailers EventMailer (4 erreurs)

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟡 Priorité 6  
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

## 🔴 Erreur

⏳ **À ANALYSER** - Exécuter les tests pour voir les erreurs exactes

---

## 🔍 Analyse

### Constats
- ⏳ Erreurs non encore analysées
- 🔍 Problème probable avec les templates de mailers
- ⚠️ Probablement problème avec les helpers `_path` vs `_url` dans les templates

### Cause Probable
Les templates de mailers utilisent probablement des helpers `_path` au lieu de `_url`, ou des associations non chargées.

---

## 💡 Solutions Proposées

⏳ **À DÉTERMINER** après analyse

Solutions possibles :
1. Remplacer `_path` par `_url` dans les templates de mailers
2. Vérifier que les associations sont chargées
3. Vérifier les helpers personnalisés

---

## 🎯 Type de Problème

⚠️ **À ANALYSER** (probablement ⚠️ **PROBLÈME DE LOGIQUE** - templates ou helpers)

---

## 📊 Statut

⏳ **À ANALYSER**

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

