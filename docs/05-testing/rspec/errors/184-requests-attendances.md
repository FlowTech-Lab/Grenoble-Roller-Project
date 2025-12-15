# Erreur #184-188 : Requests Attendances (5 erreurs)

**Date d'analyse** : 2025-12-15  
**Priorité** : 🟡 Priorité 9  
**Catégorie** : Tests de Request  
**Statut** : ✅ **RÉSOLU** (5 tests passent)

---

## 📋 Informations Générales

- **Fichier test** : `spec/requests/attendances_spec.rb`
- **Lignes** : 10, 16, 22, 30, 37
- **Tests** : Routes PATCH pour toggle_reminder
- **Nombre de tests** : 5 (tous passent maintenant)

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/requests/attendances_spec.rb
  ```

---

## 🔴 Erreurs Initiales

### Erreur 1 : Ligne 10 - `requires authentication`
```
Failure/Error: let(:user) { create(:user, role: role, confirmed_at: Time.current) }

ActiveRecord::RecordInvalid:
  L'enregistrement est invalide
```

### Erreur 2 : Ligne 52 - `toggles reminder preference for authenticated user`
```
Failure/Error: let(:attendance) { create(:attendance, user: user, event: initiation, wants_reminder: false) }

ActiveRecord::RecordInvalid:
  L'enregistrement est invalide
```

---

## 🔍 Analyse

### Constats

1. **Erreur 1** : `create(:user, role: role, ...)` échoue car la factory `:user` a des problèmes avec les rôles. Il faut utiliser le helper `create_user`.

2. **Erreur 2** : `create(:attendance, ...)` échoue car les validations de `Attendance` nécessitent des données spécifiques (adhésions actives pour les initiations). Il faut utiliser le helper `create_attendance`.

3. **Erreur 3** : `create(:event, ...)` et `create(:event_initiation, ...)` échouent car ils nécessitent des attributs spécifiques. Il faut utiliser `build_event` et `create_event`.

---

## 💡 Solutions Appliquées

### Solution 1 : Utilisation du helper `create_user`

**Problème** : `create(:user, role: role, ...)` échoue.

**Solution** : Utiliser `create_user(role: role, ...)` qui gère correctement tous les attributs requis.

**Code appliqué** :
```ruby
# Avant
let(:user) { create(:user, role: role, confirmed_at: Time.current) }

# Après
let(:user) { create_user(role: role, confirmed_at: Time.current) }
```

**Fichier modifié** : `spec/requests/attendances_spec.rb`
- Ligne 10 : Remplacement de `create(:user, ...)` par `create_user(...)`

### Solution 2 : Utilisation du helper `create_attendance`

**Problème** : `create(:attendance, ...)` échoue car les validations sont complexes.

**Solution** : Utiliser `create_attendance(...)` qui gère correctement toutes les validations.

**Code appliqué** :
```ruby
# Avant
let(:attendance) { create(:attendance, user: user, event: event, wants_reminder: false) }

# Après
let(:attendance) { create_attendance(user: user, event: event, wants_reminder: false) }
```

**Fichier modifié** : `spec/requests/attendances_spec.rb`
- Lignes 28, 60 : Remplacement de `create(:attendance, ...)` par `create_attendance(...)`

### Solution 3 : Utilisation de `build_event` et `create_event`

**Problème** : `create(:event, ...)` et `create(:event_initiation, ...)` échouent.

**Solution** : Utiliser `build_event(...)` suivi de `save!` pour les événements normaux, et `FactoryBot.create(:event_initiation, ...)` pour les initiations.

**Code appliqué** :
```ruby
# Avant
let(:event) { create(:event, :published, :upcoming) }
let(:initiation) { create(:event_initiation, :published, :upcoming) }

# Après
let(:event) do
  e = build_event(status: 'published', start_at: 1.week.from_now)
  e.save!
  e
end
let(:initiation) do
  FactoryBot.create(:event_initiation, :published, :upcoming)
end
```

**Fichier modifié** : `spec/requests/attendances_spec.rb`
- Lignes 11-15, 16-19 : Utilisation de `build_event` et `FactoryBot.create(:event_initiation, ...)`

### Solution 4 : Ajout d'adhésion active pour l'utilisateur

**Problème** : Les initiations nécessitent une adhésion active pour créer des attendances.

**Solution** : Créer une adhésion active pour l'utilisateur dans le `let(:user)`.

**Code appliqué** :
```ruby
let(:user) do
  u = create_user(role: role, confirmed_at: Time.current)
  # Créer une adhésion active pour l'utilisateur
  create(:membership, user: u, status: :active, season: '2025-2026', start_date: Date.today.beginning_of_year, end_date: Date.today.end_of_year)
  u
end
```

**Fichier modifié** : `spec/requests/attendances_spec.rb`
- Lignes 10-14 : Ajout de la création d'adhésion active

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** :
- Utilisation de factories qui ne gèrent pas correctement les validations complexes
- Manque d'adhésions actives pour les tests d'initiations

---

## 📊 Résultat

✅ **TOUS LES TESTS PASSENT** (5/5)

```
Attendances
  PATCH /events/:event_id/attendances/toggle_reminder
    requires authentication
    toggles reminder preference for authenticated user
    toggles reminder from true to false
  PATCH /initiations/:initiation_id/attendances/toggle_reminder
    requires authentication
    toggles reminder preference for authenticated user

Finished in 5.64 seconds (files took 1.67 seconds to load)
5 examples, 0 failures
```

---

## ✅ Actions Effectuées

1. [x] Exécuter les tests pour voir les erreurs exactes
2. [x] Analyser chaque erreur et documenter
3. [x] Identifier le type de problème (test ou logique)
4. [x] Proposer des solutions
5. [x] Appliquer les corrections
6. [x] Vérifier que tous les tests passent
7. [x] Mettre à jour le statut dans [README.md](../README.md)

---

## 📝 Notes

- Les corrections suivent le même pattern que pour les autres tests corrigés précédemment
- L'utilisation des helpers garantit que tous les attributs requis sont fournis
- L'ajout d'adhésions actives est nécessaire pour les tests d'initiations
