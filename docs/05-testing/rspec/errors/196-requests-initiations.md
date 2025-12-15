# Erreur #196-201 : Initiations Request Specs

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟡 Priorité 9  
**Catégorie** : Request Spec

---

## 📋 Informations Générales

Ce fichier regroupe 6 erreurs liées aux initiations :

| # | Ligne | Test | Commande |
|---|-------|------|----------|
| 196 | 29 | GET /initiations/:id redirects visitors trying to view a draft initiation | `rspec ./spec/requests/initiations_spec.rb:29` |
| 197 | 43 | GET /initiations/:id.ics requires authentication | `rspec ./spec/requests/initiations_spec.rb:43` |
| 198 | 51 | GET /initiations/:id.ics exports initiation as iCal file for published initiation when authenticated | `rspec ./spec/requests/initiations_spec.rb:51` |
| 199 | 67 | GET /initiations/:id.ics redirects to root for draft initiation when authenticated but not creator | `rspec ./spec/requests/initiations_spec.rb:67` |
| 200 | 77 | GET /initiations/:id.ics allows creator to export draft initiation | `rspec ./spec/requests/initiations_spec.rb:77` |
| 201 | 98 | POST /initiations/:initiation_id/attendances registers the current user | `rspec ./spec/requests/initiations_spec.rb:98` |

- **Fichier test** : `spec/requests/initiations_spec.rb`

---

## 🔴 Erreurs

```
[Messages d'erreur à capturer lors de l'exécution des tests]
```

---

## 🔍 Analyse

### Constats
- ⏳ Erreurs non encore analysées
- 🔍 Erreurs similaires à celles des événements : redirections, authentification, export iCal

### Cause Probable
Problèmes possibles :
- Configuration Pundit pour les autorisations
- Export iCal (format .ics)
- Redirections pour les initiations draft
- Gestion des créateurs vs visiteurs

### Code Actuel
```ruby
# spec/requests/initiations_spec.rb
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
- [189-requests-events.md](189-requests-events.md) (erreurs similaires pour les événements)

---

## 📝 Notes

- Erreurs similaires à celles des événements (initiations héritent de Event)
- Certaines erreurs peuvent être liées à la configuration Devise/Pundit

---

## ✅ Actions à Effectuer

1. [ ] Exécuter les 6 tests pour capturer les erreurs exactes
2. [ ] Analyser chaque erreur individuellement
3. [ ] Proposer des solutions
4. [ ] Mettre à jour le statut dans [README.md](../README.md)

