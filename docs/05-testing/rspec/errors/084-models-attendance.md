# Erreur #084-103 : Models Attendance (20 erreurs)

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟡 Priorité 7  
**Catégorie** : Tests de Modèles

---

## 📋 Informations Générales

- **Fichier test** : `spec/models/attendance_spec.rb`
- **Lignes** : 8, 13, 19, 29, 39, 48, 59, 70, 75, 81, 93, 107, 114, 122, 132, 151, 157, 164, 173, 189, 200, 207, 215
- **Tests** : Validations, associations, scopes, counter cache, max_participants, initiation-specific validations

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/models/attendance_spec.rb
  ```

---

## 🔴 Erreur

⏳ **À ANALYSER** - Exécuter les tests pour voir les erreurs exactes

---

## 🔍 Analyse

### Constats
- ⏳ Erreurs non encore analysées
- 🔍 Problème probable avec les validations, associations, ou logique métier
- ⚠️ Probablement problème avec les validations ou les counter caches

---

## 💡 Solutions Proposées

⏳ **À DÉTERMINER** après analyse

---

## 🎯 Type de Problème

⚠️ **À ANALYSER** (probablement ⚠️ **PROBLÈME DE LOGIQUE** - validations, associations, logique métier)

---

## 📊 Statut

⏳ **À ANALYSER**

---

## ✅ Actions à Effectuer

1. [ ] Exécuter les tests pour voir les erreurs exactes
2. [ ] Analyser chaque erreur et documenter
3. [ ] Identifier le type de problème (test ou logique)
4. [ ] Proposer des solutions
5. [ ] Mettre à jour le statut dans [README.md](../README.md)

---

## 📝 Liste Détaillée des Erreurs

| Ligne | Test | Statut |
|-------|------|--------|
| 8 | Attendance validations is valid with default attributes | ⏳ À analyser |
| 13 | Attendance validations requires a status | ⏳ À analyser |
| 19 | Attendance validations enforces uniqueness of user scoped to event | ⏳ À analyser |
| 29 | Attendance associations accepts an optional payment | ⏳ À analyser |
| 39 | Attendance associations counter cache increments event.attendances_count when attendance is created | ⏳ À analyser |
| 48 | Attendance associations counter cache decrements event.attendances_count when attendance is destroyed | ⏳ À analyser |
| 59 | Attendance associations counter cache does not increment counter when attendance creation fails | ⏳ À analyser |
| 70 | Attendance associations max_participants validation allows attendance when event has available spots | ⏳ À analyser |
| 75 | Attendance associations max_participants validation allows attendance when event is unlimited (max_participants = 0) | ⏳ À analyser |
| 81 | Attendance associations max_participants validation prevents attendance when event is full | ⏳ À analyser |
| 93 | Attendance associations max_participants validation does not count canceled attendances when checking capacity | ⏳ À analyser |
| 107 | Attendance scopes returns non-canceled attendances for active scope | ⏳ À analyser |
| 114 | Attendance scopes returns canceled attendances for canceled scope | ⏳ À analyser |
| 122 | Attendance scopes .volunteers returns only volunteer attendances | ⏳ À analyser |
| 132 | Attendance scopes .participants returns only non-volunteer attendances | ⏳ À analyser |
| 151 | Attendance initiation-specific validations when initiation is full prevents non-volunteer registration | ⏳ À analyser |
| 157 | Attendance initiation-specific validations when initiation is full allows volunteer registration even if full | ⏳ À analyser |
| 164 | Attendance initiation-specific validations free_trial_used validation prevents using free trial twice | ⏳ À analyser |
| 173 | Attendance initiation-specific validations free_trial_used validation allows free trial if never used | ⏳ À analyser |
| 189 | Attendance initiation-specific validations can_register_to_initiation when user has active membership allows registration without free trial | ⏳ À analyser |
| 200 | Attendance initiation-specific validations can_register_to_initiation when user has child membership allows registration with child membership | ⏳ À analyser |
| 207 | Attendance initiation-specific validations can_register_to_initiation when user has no membership and no free trial prevents registration | ⏳ À analyser |
| 215 | Attendance initiation-specific validations can_register_to_initiation when user uses free trial allows registration with free trial | ⏳ À analyser |

