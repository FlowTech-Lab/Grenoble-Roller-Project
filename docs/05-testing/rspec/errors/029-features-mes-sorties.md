# Erreur #029-035 : Features Mes Sorties (7 erreurs)

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟡 Priorité 4  
**Catégorie** : Tests Feature Capybara

---

## 📋 Informations Générales

- **Fichier test** : `spec/features/mes_sorties_spec.rb`
- **Lignes** : 26, 46, 69, 81, 92, 117, 133
- **Tests** :
  1. Ligne 26 : `affiche la page Mes sorties avec les événements inscrits`
  2. Ligne 46 : `permet de se désinscrire depuis la page Mes sorties`
  3. Ligne 69 : `affiche les informations de l'événement (date, lieu, nombre d'inscrits)`
  4. Ligne 81 : `n'affiche que les événements où l'utilisateur est inscrit`
  5. Ligne 92 : `n'affiche pas les inscriptions annulées`
  6. Ligne 117 : `permet de cliquer sur un événement pour voir les détails`
  7. Ligne 133 : `permet de retourner à la liste des événements`

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/features/mes_sorties_spec.rb
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
- [024-features-event-management.md](024-features-event-management.md)

---

## ✅ Actions à Effectuer

1. [ ] Exécuter les tests pour voir les erreurs exactes
2. [ ] Vérifier la configuration Capybara
3. [ ] Analyser chaque erreur et documenter
4. [ ] Identifier le type de problème (test ou logique)
5. [ ] Proposer des solutions
6. [ ] Mettre à jour le statut dans [README.md](../README.md)

