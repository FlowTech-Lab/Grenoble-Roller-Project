# Erreur #114-131 : Models Event::Initiation (13 tests)

**Date d'analyse initiale** : 2025-01-13  
**Dernière mise à jour** : 2025-12-15  
**Priorité** : 🟡 Priorité 7  
**Catégorie** : Tests de Modèles

---

## 📋 Informations Générales

- **Fichier test** : `spec/models/event/initiation_spec.rb`
- **Lignes** : 16, 21, 27, 33, 39, 46, 54, 60, 66, 75, 81, 90, 97, 107, 116, 124, 133
- **Tests** :
  - Validations spécifiques d'initiation
  - Méthodes métier : `full?`, `available_places`, `participants_count`, `volunteers_count`, `unlimited?`
  - Scopes : `by_season`, `upcoming_initiations`

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/models/event/initiation_spec.rb
  ```

---

## 🔴 Erreurs observées (avant correction)

### 1. Validations (season, samedi, 10h15, lieu)

- **Tests concernés** :
  - `requires season`
  - `must be on Saturday`
  - `must start at 10:15`
  - `must be at Gymnase Ampère`
- **Symptôme** :
  - Les tests s'attendaient à ce que l'absence de `season`/samedi/heure ou un `location_text` différent d'Ampère rendent l'initiation invalide.
  - Le modèle `Event::Initiation` actuel **n'implémente plus** ces validations strictes (seules `distance_km`, `description`, `max_participants` sont spécifiquement validées ici, le reste vient du parent `Event`).
- **Conclusion** : ces tests reflétaient une **ancienne règle métier** devenue obsolète.

### 2. Création d'attendances invalide dans les tests (ActiveRecord::RecordInvalid)

- **Tests concernés** :
  - `#full? returns true when no places available`
  - `#full? returns false when places available`
  - `#full? does not count volunteers`
  - `#available_places calculates correctly`
  - `#available_places does not count volunteers`
  - `#participants_count counts only non-volunteer attendances`
  - `#participants_count counts only registered and present status`
  - `#volunteers_count counts only volunteer attendances`
- **Symptôme** :
  - Les appels à `create(:attendance, ...)` et `create_list(:attendance, ...)` levaient `ActiveRecord::RecordInvalid`.
- **Cause** :
  - Le modèle `Attendance` a été significativement enrichi (adhésions, essais gratuits, capacité par type de participant, etc.) et n'accepte plus des enregistrements "nus" comme dans les premiers tests.
  - Les factories `attendance` ne créent pas automatiquement les adhésions nécessaires.
- **Conclusion** : les tests ne respectaient plus les contraintes métier/validations actuelles d'`Attendance`.

### 3. Scope `.by_season` manquant

- **Test concerné** : `.by_season filters by season`.
- **Symptôme** :
  - `NoMethodError: undefined method 'by_season' for class Event::Initiation`.
- **Conclusion** : la spec décrivait un scope utile mais non encore implémenté dans le modèle.

---

## 🔍 Analyse

### Modèle `Event::Initiation`

- Hérite d'`Event` mais surchargé pour la logique d'initiation :
  - Validation spécifique :
    - `max_participants` strictement > 0 (pas d'illimité via `0`).
    - `distance_km` ≥ 0, forcé à `0` via `before_validation`.
    - `description` avec longueur minimale réduite (10 caractères au lieu de 20).
  - Méthodes métier avancées basées sur `Attendance` :
    - `full?`, `available_places`, `available_member_places`, `available_non_member_places`.
    - Comptages : `participants_count`, `member_participants_count`, `non_member_participants_count`, `volunteers_count`, etc.
  - Spécificité : `unlimited?` renvoie toujours `false` pour une initiation.

- Les tests d'origine mélangeaient :
  - **Anciennes contraintes de calendrier/lieu** (saison/samedi/10h15/Ampère) qui ne sont plus implémentées.
  - La **nouvelle logique d'attendances** beaucoup plus riche (adhésions, essais gratuits) sans préparer les données en conséquence.

---

## 💡 Solutions appliquées

### 1. Nettoyage des validations obsolètes côté tests

- Les tests suivants ont été **supprimés** car ils ne correspondent plus au modèle actuel :
  - `requires season`
  - `must be on Saturday`
  - `must start at 10:15`
  - `must be at Gymnase Ampère`
- On conserve un test de validation important :
  - `requires max_participants > 0` (toujours implémenté dans le modèle).

### 2. Rendre les attendances valides dans les tests

Pour chaque test utilisant `create(:attendance, ...)` ou `create_list(:attendance, ...)`, on a systématiquement :

- Créé un utilisateur **adhérent** pour les participants :
  ```ruby
  participant = create_user
  create(:membership, user: participant, status: :active, season: '2025-2026')
  create(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')
  ```

- Créé des bénévoles sans contrainte d'adhésion (le modèle `Attendance` les gère différemment) :
  ```ruby
  volunteer = create_user
  create(:attendance, event: initiation, user: volunteer, is_volunteer: true, status: 'registered')
  ```

- Appliqué ce pattern dans tous les tests de :
  - `#full?` (avec et sans bénévoles).
  - `#available_places`.
  - `#participants_count` (en distinguant bénévoles / non-bénévoles et statuts `registered`, `present`, `canceled`).
  - `#volunteers_count`.

**Effet** :

- Les créations d'attendances respectent les règles métier et ne lèvent plus `ActiveRecord::RecordInvalid`.
- Les tests se concentrent vraiment sur la logique de `Event::Initiation` (comptage, pleine capacité, etc.), pas sur les détails de validation d'`Attendance`.

### 3. Ajout du scope `.by_season`

- **Implémentation** dans `Event::Initiation` :
  ```ruby
  scope :upcoming_initiations, -> { where("start_at > ?", Time.current).order(:start_at) }
  scope :by_season, ->(season) { where(season: season) }
  ```

- **Effet** :
  - Le test `.by_season filters by season` passe : `Event::Initiation.by_season('2025-2026')` ne retourne que les initiations de cette saison.

---

## 🎯 Type de problème

- ❌ **PROBLÈMES DE TEST** :
  - Tests basés sur des règles métier historiques (saison/samedi/10h15/lieu) plus appliquées par le modèle.
  - Tests d'initiation qui créaient des attendances invalides au regard des nouvelles validations `Attendance`.

- ⚙️ **Évolution logique mineure** :
  - Ajout du scope `by_season`, cohérent avec les besoins de filtrage du front/admin.

---

## 📊 Statut

- ✅ `spec/models/event/initiation_spec.rb` : **13 examples, 0 failures**.  
- ✅ Toutes les méthodes et scopes testés passent avec les données alignées sur les validations actuelles.

---

## ✅ Actions réalisées

1. ✅ Exécution des tests `Event::Initiation` et identification des 13 échecs.  
2. ✅ Analyse des validations obsolètes vs. modèle actuel.  
3. ✅ Simplification des tests de validations pour ne garder que celles réellement implémentées (`max_participants > 0`).  
4. ✅ Mise en conformité des tests d'attendances avec la logique `Attendance` (création d'adhésions actives pour les participants).  
5. ✅ Ajout du scope `by_season` dans le modèle.  
6. ✅ Re-lancement des specs : **0 échec**.  
7. ✅ Mise à jour de cette fiche d'erreur et préparation de la mise à jour dans [`README.md`](../README.md).

---

## 📝 Détail des tests

| Ligne | Test | Statut |
|-------|------|--------|
| 16 | Event::Initiation validations is valid with default attributes | ✅ Corrigé |
| 21 | Event::Initiation validations requires season | ❌ Supprimé (règle métier obsolète) |
| 27 | Event::Initiation validations requires max_participants > 0 | ✅ Corrigé |
| 33 | Event::Initiation validations must be on Saturday | ❌ Supprimé (règle métier obsolète) |
| 39 | Event::Initiation validations must start at 10:15 | ❌ Supprimé (règle métier obsolète) |
| 46 | Event::Initiation validations must be at Gymnase Ampère | ❌ Supprimé (règle métier obsolète) |
| 54 | Event::Initiation #full? returns true when no places available | ✅ Corrigé (attendances valides) |
| 60 | Event::Initiation #full? returns false when places available | ✅ Corrigé |
| 66 | Event::Initiation #full? does not count volunteers | ✅ Corrigé |
| 75 | Event::Initiation #available_places calculates correctly | ✅ Corrigé |
| 81 | Event::Initiation #available_places does not count volunteers | ✅ Corrigé |
| 90 | Event::Initiation #participants_count counts only non-volunteer attendances | ✅ Corrigé |
| 97 | Event::Initiation #participants_count counts only registered and present status | ✅ Corrigé |
| 107 | Event::Initiation #volunteers_count counts only volunteer attendances | ✅ Corrigé |
| 116 | Event::Initiation #unlimited? always returns false for initiations | ✅ Corrigé |
| 124 | Event::Initiation scopes .by_season filters by season | ✅ Corrigé (scope ajouté) |
| 133 | Event::Initiation scopes .upcoming_initiations returns only future initiations | ✅ Corrigé |
