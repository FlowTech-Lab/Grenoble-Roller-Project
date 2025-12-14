# Erreur #016-023 : Features Event Attendance (8 erreurs)

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟡 Priorité 4  
**Catégorie** : Tests Feature Capybara

---

## 📋 Informations Générales

- **Fichier test** : `spec/features/event_attendance_spec.rb`
- **Lignes** : 15, 21, 27, 39, 58, 79, 88, 148
- **Tests** :
  1. Ligne 15 : `affiche le bouton S'inscrire sur la page événements`
  2. Ligne 21 : `affiche le bouton S'inscrire sur la page détail de l'événement`
  3. Ligne 27 : `ouvre le popup de confirmation lors du clic sur S'inscrire`
  4. Ligne 39 : `inscrit l'utilisateur après confirmation dans le popup`
  5. Ligne 58 : `annule l'inscription si l'utilisateur clique sur Annuler dans le popup`
  6. Ligne 79 : `affiche le bouton "Se désinscrire" après inscription`
  7. Ligne 88 : `désinscrit l'utilisateur lors du clic sur Se désinscrire`
  8. Ligne 148 : `permet l'inscription même avec max_participants = 0` (événement illimité)

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/features/event_attendance_spec.rb
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
Les tests Feature Capybara nécessitent :
- Configuration JavaScript (selenium-webdriver, chromedriver)
- Configuration dans `spec/rails_helper.rb` ou `spec/support/capybara.rb`
- ChromeDriver dans Docker

---

## 💡 Solutions Proposées

⏳ **À DÉTERMINER** après analyse

Solutions possibles :
1. Configurer ChromeDriver dans Docker
2. Configurer Capybara pour utiliser JavaScript
3. Ajouter les helpers nécessaires
4. Vérifier la configuration dans `spec/rails_helper.rb`

---

## 🎯 Type de Problème

⚠️ **À ANALYSER** (probablement ❌ **PROBLÈME DE TEST** - configuration)

---

## 📊 Statut

⏳ **À ANALYSER**

---

## 🔗 Erreurs Similaires

Cette erreur est similaire à :
- [024-features-event-management.md](024-features-event-management.md)
- [029-features-mes-sorties.md](029-features-mes-sorties.md)

---

## ✅ Actions à Effectuer

1. [ ] Exécuter les tests pour voir les erreurs exactes
2. [ ] Vérifier la configuration Capybara
3. [ ] Vérifier la configuration JavaScript
4. [ ] Analyser chaque erreur et documenter
5. [ ] Identifier le type de problème (test ou logique)
6. [ ] Proposer des solutions
7. [ ] Mettre à jour le statut dans [README.md](../README.md)

