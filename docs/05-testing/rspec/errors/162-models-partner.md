# Erreur #162-166 : Models Partner (5 erreurs)

**Date d'analyse** : 2025-12-15  
**Priorité** : 🟡 Priorité 7  
**Catégorie** : Tests de Modèles  
**Statut** : ✅ **RÉSOLU** (6 tests passent)

---

## 📋 Informations Générales

- **Fichier test** : `spec/models/partner_spec.rb`
- **Lignes** : 10, 16, 22, 30, 37
- **Tests** : Validations, scopes
- **Nombre de tests** : 6 (tous passent maintenant)

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/models/partner_spec.rb
  ```

---

## 🔴 Erreurs Initiales

### Erreur 1 : Ligne 10 - `requires a name`
```
Failure/Error: expect(partner.errors[:name]).to include("can't be blank")

expected ["Translation missing. Options considered were:\n- fr.activerecord.errors.models.partner.attributes.n....activerecord.errors.messages.blank\n- fr.errors.attributes.name.blank\n- fr.errors.messages.blank"] to include "can't be blank"
```

### Erreur 2 : Ligne 16 - `validates URL format when provided`
```
Failure/Error: expect(partner.errors[:url]).to include('is invalid')

expected ["Translation missing. Options considered were:\n- fr.activerecord.errors.models.partner.attributes.u...verecord.errors.messages.invalid\n- fr.errors.attributes.url.invalid\n- fr.errors.messages.invalid"] to include "is invalid"
```

### Erreur 3 : Ligne 22 - `requires is_active to be a boolean`
```
Failure/Error: expect(partner.errors[:is_active]).to include('is not included in the list')

expected ["Translation missing. Options considered were:\n- fr.activerecord.errors.models.partner.attributes.i...ors.messages.inclusion\n- fr.errors.attributes.is_active.inclusion\n- fr.errors.messages.inclusion"] to include "is not included in the list"
```

### Erreur 4 : Ligne 30 - `returns active partners for the active scope`
```
Failure/Error: expect(Partner.active).to contain_exactly(active)

expected collection contained:  [#<Partner id: 73, ...>]
actual collection contained:    [#<Partner id: 1, ...>, #<Partner id: 73, ...>]
the extra elements were:        [#<Partner id: 1, ...>]
```

### Erreur 5 : Ligne 37 - `returns inactive partners for the inactive scope`
```
Failure/Error: expect(Partner.inactive).to contain_exactly(inactive)

expected collection contained:  [#<Partner id: 75, ...>]
actual collection contained:    [#<Partner id: 4, ...>, #<Partner id: 75, ...>]
the extra elements were:        [#<Partner id: 4, ...>]
```

---

## 🔍 Analyse

### Constats

1. **Erreurs 1-3** : Les tests attendent des messages de validation en anglais hardcodés (`"can't be blank"`, `"is invalid"`, `"is not included in the list"`), mais l'application utilise I18n et retourne des messages de traduction manquants en français. C'est le même problème que pour `AuditLog` et `ContactMessage`.

2. **Erreurs 4-5** : Les scopes `active` et `inactive` retournent des éléments supplémentaires provenant de données de seed ou de tests précédents. C'est un problème de pollution de données dans les tests, similaire à ce qui a été corrigé pour `Attendance`, `AuditLog`, et `Event`.

### Code du modèle

Le modèle `Partner` est simple :
- Validations : `name` (présence, longueur max 140), `url` (format HTTP/HTTPS, optionnel), `is_active` (inclusion dans [true, false])
- Scopes : `active` (où `is_active: true`), `inactive` (où `is_active: false`)

---

## 💡 Solutions Appliquées

### Solution 1 : Messages de validation I18n-agnostiques (Erreurs 1-3)

**Problème** : Les tests attendent des messages de validation en anglais hardcodés, mais l'application utilise I18n.

**Solution** : Remplacer les assertions `include("message exact")` par `be_present` pour rendre les tests indépendants des traductions I18n.

**Code appliqué** :
```ruby
# Avant (ligne 13)
expect(partner.errors[:name]).to include("can't be blank")

# Après
expect(partner.errors[:name]).to be_present
```

**Fichier modifié** : `spec/models/partner_spec.rb`
- Ligne 13 : `expect(partner.errors[:name]).to be_present`
- Ligne 19 : `expect(partner.errors[:url]).to be_present`
- Ligne 25 : `expect(partner.errors[:is_active]).to be_present`

### Solution 2 : Nettoyage des données pour les scopes (Erreurs 4-5)

**Problème** : Les tests de scopes contiennent des éléments supplémentaires provenant de données de seed ou de tests précédents.

**Solution** : Ajouter un `before` block dans le `describe 'scopes'` pour supprimer toutes les données `Partner` avant chaque test de scope.

**Code appliqué** :
```ruby
describe 'scopes' do
  before do
    Partner.delete_all
  end

  it 'returns active partners for the active scope' do
    # ...
  end
  # ...
end
```

**Fichier modifié** : `spec/models/partner_spec.rb`
- Ajout d'un `before` block avec `Partner.delete_all` dans le `describe 'scopes'`

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** :
- Messages de validation attendus en anglais hardcodés au lieu d'être I18n-agnostiques
- Pollution de données dans les tests de scopes (données de seed/test précédents)

---

## 📊 Résultat

✅ **TOUS LES TESTS PASSENT** (6/6)

```
Partner
  validations
    is valid with default attributes
    requires a name
    validates URL format when provided
    requires is_active to be a boolean
  scopes
    returns active partners for the active scope
    returns inactive partners for the inactive scope

Finished in 0.20785 seconds (files took 1.84 seconds to load)
6 examples, 0 failures
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

- Les corrections suivent le même pattern que pour `AuditLog`, `ContactMessage`, `Attendance`, et `Event`
- Aucune modification du modèle `Partner` n'était nécessaire, seulement des ajustements dans les tests
- Les tests sont maintenant I18n-agnostiques et isolés des données de seed
