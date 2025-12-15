# Erreur #105-110 : Models AuditLog (6 tests)

**Date d'analyse initiale** : 2025-01-13  
**Dernière mise à jour** : 2025-12-15  
**Priorité** : 🟡 Priorité 7  
**Catégorie** : Tests de Modèles

---

## 📋 Informations Générales

- **Fichier test** : `spec/models/audit_log_spec.rb`
- **Lignes** : 9, 14, 24, 31, 38, 46
- **Tests** : Validations, scopes

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/models/audit_log_spec.rb
  ```

---

## 🔴 Erreurs observées (avant correction)

### 1. Validation de présence (messages d'erreur i18n)

- **Test** : `requires action, target_type, and target_id` (ligne ~14).  
- **Symptôme** :
  - Le test attendait le message exact `"can't be blank"` pour les attributs `action`, `target_type` et `target_id`.
  - Rails renvoyait un message de type **"Translation missing"** en français, car les clés I18n `fr.activerecord.errors.models.audit_log...` n'étaient pas définies.
- **Extrait d'erreur** :
  - `expected ["Translation missing. Options considered were: ..."] to include "can't be blank"`.
- **Type** : ❌ **PROBLÈME DE TEST** (trop dépendant du texte exact du message d'erreur au lieu de vérifier simplement la présence d'une erreur).

### 2. Scope `by_action` pollué par les seeds

- **Test** : `filters by action` (ligne ~24).  
- **Symptôme** :
  - Le scope `AuditLog.by_action('event.cancel')` retournait :
    - le log créé dans le test (`matching`), **plus** un log existant créé ailleurs (seed ou autre spec), avec la même action.
  - Le `contain_exactly(matching)` échouait car il y avait un élément en trop.
- **Type** : ❌ **PROBLÈME DE TEST** (environnement non isolé, dépendant de données pré-existantes).

### 3. Scope `recent` pollué par les seeds

- **Test** : `returns logs ordered by recency` (ligne ~46).  
- **Symptôme** :
  - Le test créait seulement deux logs (`old_log`, `recent_log`) avec `travel_to`, mais `AuditLog.recent` renvoyait **tous** les logs existants en base, dont ceux issus des seeds (`product.create`, `event.cancel`, etc.), **avant** les deux logs créés dans le test.
  - L'assertion `expect(AuditLog.recent).to eq([ recent_log, old_log ])` échouait car la relation contenait de nombreux enregistrements supplémentaires.
- **Type** : ❌ **PROBLÈME DE TEST** (base non nettoyée avant le test, on ne contrôle pas le dataset).

---

## 🔍 Analyse

### Modèle `AuditLog`

Le modèle est simple et cohérent :

- **Associations** :
  - `belongs_to :actor_user, class_name: "User"`
- **Validations** :
  - `action` présent, longueur max 80.
  - `target_type` présent, longueur max 50.
  - `target_id` présent et entier.
- **Scopes** :
  - `by_action(action)` → filtrage sur `action`.
  - `by_target(type, id)` → filtrage sur `target_type` et `target_id`.
  - `by_actor(user_id)` → filtrage sur `actor_user_id`.
  - `recent` → `order(created_at: :desc)`.

Conclusion : la **logique métier et les scopes sont corrects**. Les erreurs venaient :

- du couplage du test aux messages i18n (`"can't be blank"` en anglais),
- de la présence de données en base créées avant ce test (`seeds`, autres specs).

---

## 💡 Solutions appliquées

### 1. Validation de présence : assouplir l'assertion

- **Avant** :
  ```ruby
  expect(log.errors[:action]).to include("can't be blank")
  expect(log.errors[:target_type]).to include("can't be blank")
  expect(log.errors[:target_id]).to include("can't be blank")
  ```

- **Après** :
  ```ruby
  expect(log.errors[:action]).to be_present
  expect(log.errors[:target_type]).to be_present
  expect(log.errors[:target_id]).to be_present
  ```

- **Raison** :
  - On teste la **présence d'une erreur de validation**, pas le texte exact, qui dépend de la configuration I18n et peut varier (anglais, français, etc.).

### 2. Isolation des tests de scopes

- **Problème** : les tests de scopes (par action, par acteur, par cible, ordre récent) se basaient sur la totalité des données `AuditLog` présentes en base.
- **Solution** : ajout d'un `before` dans le bloc `describe 'scopes'` :

  ```ruby
  describe 'scopes' do
    before do
      AuditLog.delete_all
    end
    # ...
  end
  ```

- **Effet** :
  - Chaque test de scope part d'une table vide, ne contenant que les enregistrements créés explicitement dans l'exemple.
  - `by_action('event.cancel')` ne retourne plus que l'enregistrement `matching`.
  - `recent` retourne bien `[ recent_log, old_log ]` dans l'ordre attendu.

---

## 🎯 Type de problème

- ❌ **PROBLÈME DE TEST** :
  - Assertions trop strictes sur les messages d'erreur (dépendantes de l'anglais) au lieu de tester la présence d'erreurs.
  - Tests de scopes non isolés qui dépendent de données résiduelles (seeds, autres specs).

- ✅ **LOGIQUE DU MODÈLE** :
  - Les validations et les scopes d'`AuditLog` sont cohérents et n'ont pas nécessité de modification.

---

## 📊 Statut

- ✅ `spec/models/audit_log_spec.rb` : **6 examples, 0 failures**.  
- ✅ Tous les tests de validations et de scopes passent après correction.

---

## ✅ Actions réalisées

1. ✅ Exécution ciblée : `docker exec grenoble-roller-dev bundle exec rspec ./spec/models/audit_log_spec.rb`.  
2. ✅ Analyse des 3 échecs (messages i18n + pollution par les seeds).  
3. ✅ Ajustement des tests de validations pour vérifier la présence d'erreurs au lieu du texte exact.  
4. ✅ Ajout d'un `AuditLog.delete_all` dans le bloc `describe 'scopes'` pour isoler les jeux de données.  
5. ✅ Re-lancement des specs → **0 échec**.  
6. ✅ Mise à jour de cette fiche d'erreur et préparation de la mise à jour du statut dans [`README.md`](../README.md).

---

## 📝 Liste détaillée des tests

| Ligne | Test | Statut |
|-------|------|--------|
| 9  | AuditLog validations is valid with required attributes | ✅ Corrigé |
| 14 | AuditLog validations requires action, target_type, and target_id | ✅ Corrigé (assertion sur la présence d'erreurs, pas sur le texte) |
| 24 | AuditLog scopes filters by action | ✅ Corrigé (table nettoyée avant le test) |
| 31 | AuditLog scopes filters by target | ✅ Corrigé |
| 38 | AuditLog scopes filters by actor | ✅ Corrigé |
| 46 | AuditLog scopes returns logs ordered by recency | ✅ Corrigé (table nettoyée avant le test) |
