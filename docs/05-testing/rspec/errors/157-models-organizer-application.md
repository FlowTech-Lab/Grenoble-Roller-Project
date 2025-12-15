# Erreur #157-161 : Models OrganizerApplication (5 tests)

**Date d'analyse initiale** : 2025-01-13  
**Dernière mise à jour** : 2025-12-15  
**Priorité** : 🟡 Priorité 7  
**Catégorie** : Tests de Modèles

---

## 📋 Informations Générales

- **Fichier test** : `spec/models/organizer_application_spec.rb`  
- **Lignes** : 9, 14, 20, 25, 33  
- **Tests** : validations de statut/motivation, association avec un reviewer.

- **Commande pour exécuter les tests** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/models/organizer_application_spec.rb
  ```

---

## 🔴 État des tests

Après exécution :

```text
5 examples, 0 failures
```

Tous les tests de `OrganizerApplication` passent déjà. Les "erreurs" listées dans la doc étaient des points à auditer, mais ils sont désormais couverts par des specs vertes.

---

## 🔍 Analyse rapide

### 1. Validation du statut et de la motivation

- `status` est un `enum` : `pending`, `approved`, `rejected` avec validation.
- Règles dans le modèle :
  ```ruby
  validates :status, presence: true
  validates :motivation, presence: true, if: -> { status == "pending" }
  ```
- Les specs vérifient :
  - qu’une application `pending` avec `motivation` est valide ;
  - qu’une `pending` sans `motivation` est invalide (et qu’une erreur est bien présente sur `motivation`) ;
  - qu’une `approved` peut avoir une motivation vide si elle a été revue (`reviewed_by` + `reviewed_at`) ;
  - qu’un `status` nil rend l’objet invalide (erreur présente sur `status`).

Ces règles sont cohérentes avec le métier : on exige une motivation uniquement au moment de la demande (`pending`).

### 2. Association `reviewed_by`

- Associations dans le modèle :
  ```ruby
  belongs_to :user
  belongs_to :reviewed_by, class_name: "User", optional: true
  ```
- La spec `allows attaching a reviewer` crée une application `approved` avec :
  - `reviewed_by` = un utilisateur admin,
  - `reviewed_at` = `Time.current`.
- Le test vérifie simplement que `application.reviewed_by == reviewer` → OK.

---

## 🎯 Type de problème

- ✅ **Aucun problème restant** sur ce modèle :
  - La logique de validations et d’associations est cohérente.
  - Tous les tests de `organizer_application_spec` sont verts.
- Les entrées `#157-161` dans cette doc étaient plutôt des TODO d’analyse ; elles sont maintenant satisfaites.

---

## 📊 Statut

- ✅ `spec/models/organizer_application_spec.rb` : **5 examples, 0 failures**.  
- ✅ `OrganizerApplication` est considéré comme **RÉSOLU** dans la campagne de correction RSpec.

---

## ✅ Actions réalisées

1. ✅ Exécution de tous les tests `OrganizerApplication`.  
2. ✅ Vérification de la cohérence entre le modèle (`status` enum, validations conditionnelles) et les specs.  
3. ✅ Confirmation qu’aucune modification de code n’est nécessaire.  
4. ✅ Mise à jour de cette fiche pour refléter le statut **corrigé / conforme**.  
5. ✅ Mise à jour du `README` RSpec pour marquer `OrganizerApplication` comme résolu dans la section "Tests de modèles".

---

## 📝 Récap des tests

| Ligne | Test | Statut |
|-------|------|--------|
| 9  | OrganizerApplication validations is valid with a pending status and motivation | ✅ OK |
| 14 | OrganizerApplication validations requires a motivation when status is pending | ✅ OK |
| 21 | OrganizerApplication validations allows blank motivation when status is approved | ✅ OK |
| 26 | OrganizerApplication validations requires a status value | ✅ OK |
| 35 | OrganizerApplication associations allows attaching a reviewer | ✅ OK |
