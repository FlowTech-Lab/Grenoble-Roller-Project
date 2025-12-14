# Erreur #184 : Policies EventPolicy Scope

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟡 Priorité 8  
**Catégorie** : Tests de Policies

---

## 📋 Informations Générales

- **Fichier test** : `spec/policies/event_policy_spec.rb`
- **Ligne** : 153
- **Test** : `EventPolicy Scope returns only published events for guests`

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/policies/event_policy_spec.rb:153
  ```

---

## 🔴 Erreur

⏳ **À ANALYSER** - Exécuter le test pour voir l'erreur exacte

---

## 🔍 Analyse

### Constats
- ⏳ Erreur non encore analysée
- 🔍 Problème probable avec le scope Pundit

---

## 💡 Solutions Proposées

⏳ **À DÉTERMINER** après analyse

---

## 🎯 Type de Problème

⚠️ **À ANALYSER** (probablement ⚠️ **PROBLÈME DE LOGIQUE** - scope Pundit)

---

## 📊 Statut

⏳ **À ANALYSER**

---

## ✅ Actions à Effectuer

1. [ ] Exécuter le test pour voir l'erreur exacte
2. [ ] Analyser l'erreur et documenter
3. [ ] Identifier le type de problème (test ou logique)
4. [ ] Proposer des solutions
5. [ ] Mettre à jour le statut dans [README.md](../README.md)

