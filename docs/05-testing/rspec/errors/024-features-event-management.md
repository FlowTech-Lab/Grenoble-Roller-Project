# Erreur #024-028 : Features Event Management (5 erreurs)

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟡 Priorité 4  
**Catégorie** : Tests Feature Capybara

---

## 📋 Informations Générales

- **Fichier test** : `spec/features/event_management_spec.rb`
- **Lignes** : 20, 42, 152, 171, 235
- **Tests** :
  1. Ligne 20 : `permet de créer un événement via le formulaire`
  2. Ligne 42 : `permet de créer un événement avec max_participants = 0 (illimité)`
  3. Ligne 152 : `permet de supprimer l'événement avec confirmation`
  4. Ligne 171 : `annule la suppression si l'utilisateur clique sur Annuler dans le modal`
  5. Ligne 235 : `affiche le prochain événement en vedette`

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/features/event_management_spec.rb
  ```

---

## 🔴 Erreur

⏳ **À ANALYSER** - Exécuter les tests pour voir les erreurs exactes

---

## 🔍 Analyse

### Constats
- ⏳ Erreurs non encore analysées
- 🔍 Tests Capybara qui nécessitent probablement une configuration JavaScript
- ⚠️ Probablement problème de configuration (ChromeDriver, JavaScript, etc.)

### Cause Probable
Même problème que l'erreur #016 : configuration Capybara/JavaScript manquante.

---

## 💡 Solutions Proposées

⏳ **À DÉTERMINER** après analyse

---

## 🎯 Type de Problème

⚠️ **À ANALYSER** (probablement ❌ **PROBLÈME DE TEST** - configuration)

---

## 📊 Statut

⏳ **À ANALYSER**

---

## 🔗 Erreurs Similaires

Cette erreur est similaire à :
- [016-features-event-attendance.md](016-features-event-attendance.md)
- [029-features-mes-sorties.md](029-features-mes-sorties.md)

---

## ✅ Actions à Effectuer

1. [ ] Exécuter les tests pour voir les erreurs exactes
2. [ ] Vérifier la configuration Capybara
3. [ ] Analyser chaque erreur et documenter
4. [ ] Identifier le type de problème (test ou logique)
5. [ ] Proposer des solutions
6. [ ] Mettre à jour le statut dans [README.md](../README.md)

