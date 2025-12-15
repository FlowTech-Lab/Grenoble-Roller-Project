# Erreur #189-195 : Events Request Specs

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟡 Priorité 9  
**Catégorie** : Request Spec

---

## 📋 Informations Générales

Ce fichier regroupe 7 erreurs liées aux événements :

| # | Ligne | Test | Commande |
|---|-------|------|----------|
| 189 | 27 | GET /events/:id redirects visitors trying to view a draft event | `rspec ./spec/requests/events_spec.rb:27` |
| 190 | 47 | POST /events allows an organizer to create an event | `rspec ./spec/requests/events_spec.rb:47` |
| 191 | 76 | POST /events/:id/attend requires authentication | `rspec ./spec/requests/events_spec.rb:76` |
| 192 | 82 | POST /events/:id/attend registers the current user | `rspec ./spec/requests/events_spec.rb:82` |
| 193 | 97 | POST /events/:id/attend blocks unconfirmed users from attending | `rspec ./spec/requests/events_spec.rb:97` |
| 194 | 132 | DELETE /events/:event_id/attendances removes the attendance for the current user | `rspec ./spec/requests/events_spec.rb:132` |
| 195 | 152 | GET /events/:id.ics requires authentication | `rspec ./spec/requests/events_spec.rb:152` |

- **Fichier test** : `spec/requests/events_spec.rb`

---

## 🔴 Erreurs

```
[Messages d'erreur à capturer lors de l'exécution des tests]
```

---

## 🔍 Analyse

### Constats
- ⏳ Erreurs non encore analysées
- 🔍 Erreurs variées : redirections, authentification, création, export iCal

### Cause Probable
Problèmes possibles :
- Configuration Pundit pour les autorisations
- Gestion des utilisateurs non confirmés
- Export iCal (format .ics)
- Redirections pour les événements draft

### Code Actuel
```ruby
# spec/requests/events_spec.rb
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
- [196-requests-initiations.md](196-requests-initiations.md) (erreurs similaires pour les initiations)

---

## 📝 Notes

- Erreurs variées couvrant plusieurs aspects des événements
- Certaines erreurs peuvent être liées à la configuration Devise/Pundit

---

## ✅ Actions à Effectuer

1. [ ] Exécuter les 7 tests pour capturer les erreurs exactes
2. [ ] Analyser chaque erreur individuellement
3. [ ] Proposer des solutions
4. [ ] Mettre à jour le statut dans [README.md](../README.md)

