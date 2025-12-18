# 9. Clarification Parent/Enfant

[← Retour à l'index](index.md)

### 9.1. Indépendance Totale

**Règle** : Chaque personne (parent ou enfant) a son propre essai gratuit, indépendamment des autres.

### 9.2. Matrice de Possibilités

| Situation | Parent Essai | Enfant A Essai | Enfant B Essai | Résultat |
|-----------|--------------|----------------|----------------|----------|
| Tous disponibles | ✅ | ✅ | ✅ | Tous peuvent utiliser leur essai |
| Parent utilisé | ❌ | ✅ | ✅ | Enfants peuvent utiliser le leur |
| Enfant A utilisé | ✅ | ❌ | ✅ | Parent et Enfant B peuvent utiliser le leur |
| Tous utilisés | ❌ | ❌ | ❌ | Aucun essai disponible, adhésion requise |

### 9.3. Exemples Concrets

#### Exemple 1 : Parent Utilise son Essai, Enfant Non

**Timeline** :
```
T0: Parent crée enfant
    BD: memberships = [child (status: "pending")]
    BD: attendances = []

T1: Parent s'inscrit lui-même à Initiation A (utilise son essai)
    BD: attendances = [attendance_parent (free_trial_used: true, child_membership_id: nil)]

T2: Enfant peut toujours utiliser son essai gratuit
    BD: attendances.active.where(free_trial_used: true, child_membership_id: child.id) → [] (vide)
    Enfant peut s'inscrire à Initiation B avec essai gratuit
```

**Résultat** : Deux attendances distinctes, deux essais gratuits utilisés indépendamment

#### Exemple 2 : Enfant Utilise son Essai, Parent Non

**Timeline** :
```
T0: Parent crée enfant
    BD: memberships = [child (status: "pending")]
    BD: attendances = []

T1: Enfant s'inscrit à Initiation A (utilise son essai)
    BD: attendances = [attendance_enfant (free_trial_used: true, child_membership_id: child.id)]

T2: Parent peut toujours utiliser son essai gratuit
    BD: attendances.active.where(free_trial_used: true, child_membership_id: nil) → [] (vide)
    Parent peut s'inscrire à Initiation B avec essai gratuit
```

**Résultat** : Deux attendances distinctes, deux essais gratuits utilisés indépendamment

### 9.4. Distinction Technique

La distinction se fait via `child_membership_id` :
- `child_membership_id = nil` → Essai gratuit du **parent**
- `child_membership_id = X` → Essai gratuit de l'**enfant X**

```ruby
# Vérification parent
user.attendances.active.where(free_trial_used: true, child_membership_id: nil).exists?

# Vérification enfant
user.attendances.active.where(free_trial_used: true, child_membership_id: child.id).exists?
```

---

---

**Navigation** :
- [← Section précédente](08-tests-integration.md)
- [← Retour à l'index](index.md)
- [→ Section suivante](10-javascript-serveur.md)
