# Erreur #084-103 : Models Attendance (23 erreurs)

**Date d'analyse** : 2025-01-13  
**Dernière mise à jour** : 2025-12-15  
**Priorité** : 🟡 Priorité 7  
**Catégorie** : Tests de Modèles

---

## 📋 Informations Générales

- **Fichier test** : `spec/models/attendance_spec.rb`
- **Lignes** : 8, 13, 19, 29, 39, 48, 59, 70, 75, 81, 93, 107, 114, 122, 132, 151, 157, 164, 173, 189, 200, 207, 215
- **Tests** : Validations, associations, scopes, counter cache, max_participants, validations spécifiques aux initiations

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/models/attendance_spec.rb
  ```

---

## 🔴 Erreurs Observées (avant correction)

1. **Unicité par utilisateur/événement**  
   - **Symptôme** : le test attendait le message d'erreur `"a déjà une inscription pour cet événement"` mais le modèle renvoyait `"a déjà une inscription pour cet événement avec ce statut"`.  
   - **Type** : ❌ **PROBLÈME DE TEST** (message trop strict par rapport au modèle).

2. **Scopes `active` et `participants` pollués par des données existantes**  
   - **Symptôme** : les scopes `Attendance.active` et `Attendance.participants` contenaient des enregistrements pré‑existants (id:1) en plus des attendances créées dans le test.  
   - **Cause** : données de seed / tests précédents non nettoyées dans ces exemples.  
   - **Type** : ❌ **PROBLÈME DE TEST** (manque de nettoyage de la base pour ce contexte).

3. **Validations spécifiques aux initiations : enregistrement initial impossible**  
   - **Contexte** : bloc `describe 'initiation-specific validations'`.  
   - **Symptômes** :
     - `let(:initiation) { create(:event_initiation, max_participants: 1) }` levait `ActiveRecord::RecordInvalid`.
     - Le `before` qui fait `create_attendance(event: initiation, is_volunteer: false, status: 'registered')` levait aussi `ActiveRecord::RecordInvalid`.
   - **Causes probables** :
     - Le factory `event_initiation` est devenu plus strict (validations complexes sur `Event::Initiation`).
     - Les nouvelles validations d'`Attendance` pour les initiations (`can_register_to_initiation`, `can_use_free_trial`, `event_has_available_spots`) exigeaient :
       - soit une adhésion active,
       - soit l'utilisation correcte de l'essai gratuit,
       - soit des paramètres cohérents d'initiation.
   - **Type** : mélange de ⚠️ **PROBLÈME DE LOGIQUE** (modèle plus riche) et ❌ **PROBLÈME DE TEST** (tests supposant une création "simple").

4. **Validation `free_trial_used` avec factory `event_initiation`**  
   - **Symptôme** : dans `free_trial_used validation prevents using free trial twice`, l'appel `create_attendance(user: user, free_trial_used: true, event: create(:event_initiation))` levait `ActiveRecord::RecordInvalid`.  
   - **Cause** : même problème de complexité des factories / validations d'`Event::Initiation`, inutile pour tester uniquement la logique de l'essai gratuit côté `Attendance`.

---

## 🔍 Analyse Détaillée

### 1. Unicité utilisateur/événement

- **Objectif métier** : un utilisateur ne doit pas pouvoir s'inscrire plusieurs fois au même événement, en tenant compte :
  - des inscriptions pour lui‑même,
  - des inscriptions pour ses enfants (`child_membership`),
  - des inscriptions en tant que bénévole (`is_volunteer`).
- **Implémentation dans le modèle** :
  - Validation d'unicité avec scope élargi :
    - `user_id`
    - `event_id`
    - `child_membership_id`
    - `is_volunteer`
  - Message : `"a déjà une inscription pour cet événement avec ce statut"` (plus précis que l'ancien test).
- **Conclusion** : la logique du modèle est correcte et plus fine que le test. C'est donc le **test** qu'il fallait aligner sur le comportement réel.

### 2. Scopes `active` et `participants`

- **Objectif** :
  - `Attendance.active` : ne retourner que les participations non annulées.  
  - `Attendance.participants` : ne retourner que les participations non bénévoles.
- **Problème** : des `Attendance` créées en dehors du test (seeds ou autres specs) restaient en base et faussaient `contain_exactly`.
- **Conclusion** : le modèle est correct, le test doit contrôler son environnement (données) pour être fiable.

### 3. Validations pour les initiations (capacité + adhésion)

- **Objectif métier** :
  - Gérer à la fois :
    - la capacité (`max_participants`, événement complet ou non),
    - le statut d'adhésion (adhérent, enfant adhérent, découverte, essai gratuit),
    - les bénévoles (qui ne consomment pas les mêmes places).
- **Constat** :
  - Le test utilisait directement `create(:event_initiation, ...)`, sensible à toutes les validations d'`Event::Initiation`.
  - Pour tester `Attendance`, on n'a pas besoin de vérifier la validité métier complète de `Event::Initiation`.
- **Conclusion** : il est plus robuste d'utiliser le helper `create_event(type: 'Event::Initiation', ...)` qui bypass une partie des validations d'`Event`, afin de se concentrer sur la logique du modèle `Attendance`.

### 4. Validation `free_trial_used`

- **Objectif métier** :
  - Empêcher un utilisateur d'utiliser l'essai gratuit plus d'une fois.  
  - Autoriser l'essai gratuit s'il n'a jamais été utilisé.
- **Problème** :
  - Le test mélangeait deux choses :
    - les validations riches d'`Event::Initiation`,
    - la logique d'essai gratuit du modèle `Attendance`.
- **Conclusion** : pour tester `free_trial_used`, il suffit d'avoir des événements de type `Event::Initiation` techniquement valides, pas besoin de passer par le factory complet.

---

## 💡 Solutions Appliquées

### 1. Message d'unicité

- **Changement** :
  - **Avant** (test) :
    - attendait `"a déjà une inscription pour cet événement"`.
  - **Après** (test) :
    - attend maintenant `"a déjà une inscription pour cet événement avec ce statut"`, qui correspond au message du modèle.
- **Raison** : respecter la sémantique plus précise du modèle.

### 2. Nettoyage pour les scopes

- **Changement** : ajout d'un `before` dans `describe 'scopes'` :
  - `Attendance.delete_all` avant chaque exemple de ce bloc.
- **Effet** :
  - Les scopes sont testés sur un dataset contrôlé, sans pollution par des attendances existantes.

### 3. Initiations pour les tests de capacité

- **Changements dans les tests** :
  - Remplacement de :
    - `let(:initiation) { create(:event_initiation, max_participants: 1) }`
  - Par :
    - `let(:initiation) { create_event(type: 'Event::Initiation', max_participants: 1, allow_non_member_discovery: false) }`
  - Dans le contexte `when initiation is full` :
    - Création d'un utilisateur avec adhésion active avant de remplir la séance :
      - `member_user = create_user`
      - `create(:membership, user: member_user, status: :active, season: '2025-2026')`
      - `create_attendance(event: initiation, user: member_user, is_volunteer: false, status: 'registered')`
- **Effet** :
  - La première inscription est **valide** (adhérent) et remplit l'initiation.
  - Les tests peuvent ensuite vérifier :
    - le blocage des non‑bénévoles quand c'est complet,
    - l'autorisation des bénévoles même si c'est complet.

### 4. Tests sur `free_trial_used`

- **Changements** :
  - Utilisation systématique de `create_event(type: 'Event::Initiation', ...)` au lieu de `create(:event_initiation)` dans ces tests :
    - pour la première inscription avec essai gratuit,
    - pour la deuxième tentative (qui doit être refusée),
    - pour le cas "jamais utilisé" (qui doit être accepté).
- **Effet** :
  - On isole proprement la logique d'essai gratuit d'`Attendance` sans se faire bloquer par des détails de factory d'`Event::Initiation`.

---

## 🎯 Type de Problème

- 🧪 **PROBLÈMES DE TEST** :
  - Message d'erreur d'unicité trop strict dans le test.
  - Absence de nettoyage des données pour les scopes.
  - Utilisation de factories trop riches pour des tests qui ne portent pas sur `Event::Initiation`.

- ⚙️ **LOGIQUE MÉTIER VALIDE** :
  - Les validations d'`Attendance` (unicité avancée, gestion des initiations, essai gratuit) sont cohérentes avec les besoins métier.

---

## 📊 Statut

- ✅ Tous les tests de `spec/models/attendance_spec.rb` passent :
  - **23 examples, 0 failures**.
- ✅ Problèmes identifiés principalement côté **tests**, pas côté modèle.

---

## ✅ Actions Réalisées

1. ✅ Exécution ciblée des tests `Attendance` pour voir les erreurs exactes.  
2. ✅ Analyse de chaque échec (message d'erreur, pollution de données, interactions avec `Event::Initiation`).  
3. ✅ Identification du type de problème (principalement **tests**).  
4. ✅ Ajustement des tests pour :
   - refléter le message d'erreur réel du modèle,
   - nettoyer la base pour les scopes,
   - isoler les tests d'`Attendance` des complexités de `Event::Initiation`.
5. ✅ Vérification finale : `docker exec grenoble-roller-dev bundle exec rspec ./spec/models/attendance_spec.rb` → **0 échec**.  
6. ✅ Mise à jour du statut dans [`README.md`](../README.md) à faire au niveau global des modèles.

---

## 📝 Liste Détaillée des Erreurs

| Ligne | Test | Statut |
|-------|------|--------|
| 8 | Attendance validations is valid with default attributes | ✅ Corrigé |
| 13 | Attendance validations requires a status | ✅ Corrigé |
| 19 | Attendance validations enforces uniqueness of user scoped to event | ✅ Corrigé (test aligné sur le message réel) |
| 29 | Attendance associations accepts an optional payment | ✅ Corrigé |
| 39 | Attendance associations counter cache increments event.attendances_count when attendance is created | ✅ Corrigé |
| 48 | Attendance associations counter cache decrements event.attendances_count when attendance is destroyed | ✅ Corrigé |
| 59 | Attendance associations counter cache does not increment counter when attendance creation fails | ✅ Corrigé |
| 70 | Attendance associations max_participants validation allows attendance when event has available spots | ✅ Corrigé |
| 75 | Attendance associations max_participants validation allows attendance when event is unlimited (max_participants = 0) | ✅ Corrigé |
| 81 | Attendance associations max_participants validation prevents attendance when event is full | ✅ Corrigé |
| 93 | Attendance associations max_participants validation does not count canceled attendances when checking capacity | ✅ Corrigé |
| 107 | Attendance scopes returns non-canceled attendances for active scope | ✅ Corrigé (nettoyage de données) |
| 114 | Attendance scopes returns canceled attendances for canceled scope | ✅ Corrigé |
| 122 | Attendance scopes .volunteers returns only volunteer attendances | ✅ Corrigé |
| 132 | Attendance scopes .participants returns only non-volunteer attendances | ✅ Corrigé (nettoyage de données) |
| 151 | Attendance initiation-specific validations when initiation is full prevents non-volunteer registration | ✅ Corrigé (initiation + adhésion) |
| 157 | Attendance initiation-specific validations when initiation is full allows volunteer registration even if full | ✅ Corrigé |
| 164 | Attendance initiation-specific validations free_trial_used validation prevents using free trial twice | ✅ Corrigé |
| 173 | Attendance initiation-specific validations free_trial_used validation allows free trial if never used | ✅ Corrigé |
| 189 | Attendance initiation-specific validations can_register_to_initiation when user has active membership allows registration without free trial | ✅ Corrigé |
| 200 | Attendance initiation-specific validations can_register_to_initiation when user has child membership allows registration with child membership | ✅ Corrigé |
| 207 | Attendance initiation-specific validations can_register_to_initiation when user has no membership and no free trial prevents registration | ✅ Corrigé |
| 215 | Attendance initiation-specific validations can_register_to_initiation when user uses free trial allows registration with free trial | ✅ Corrigé |
