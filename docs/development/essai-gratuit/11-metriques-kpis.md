# 11. Métriques Métier et KPIs

[← Retour à l'index](index.md)

### 11.1. Métriques à Suivre

#### Taux d'Utilisation Essai Gratuit

```ruby
# Nombre d'essais gratuits utilisés / Nombre d'enfants créés
free_trials_used = Attendance.active.where(free_trial_used: true).count
children_created = Membership.where(is_child_membership: true).count
usage_rate = (free_trials_used.to_f / children_created) * 100
```

#### Taux de Conversion Essai → Adhésion

```ruby
# Utilisateurs ayant utilisé essai gratuit ET créé une adhésion après
users_with_trial = User.joins(:attendances)
  .where(attendances: { free_trial_used: true })
  .distinct

users_converted = users_with_trial.joins(:memberships)
  .where("memberships.created_at > attendances.created_at")
  .where(memberships: { status: :active })
  .distinct
  .count

conversion_rate = (users_converted.to_f / users_with_trial.count) * 100
```

#### Taux de Réutilisation après Annulation

```ruby
# Utilisateurs ayant annulé puis réutilisé leur essai
canceled_with_trial = Attendance.where(free_trial_used: true, status: :canceled)
  .joins(:user)
  .distinct

reused = canceled_with_trial.joins("INNER JOIN attendances a2 ON a2.user_id = attendances.user_id")
  .where("a2.free_trial_used = true")
  .where("a2.created_at > attendances.updated_at")
  .where("a2.status != 'canceled'")
  .distinct
  .count

reuse_rate = (reused.to_f / canceled_with_trial.count) * 100
```

### 11.2. KPIs Recommandés

| KPI | Description | Cible | Fréquence |
|-----|-------------|-------|-----------|
| Taux d'utilisation essai gratuit | % enfants utilisant leur essai | > 60% | Mensuel |
| Taux de conversion | % essais → adhésions | > 40% | Mensuel |
| Taux de réutilisation | % annulations → réinscriptions | < 20% | Mensuel |
| Nombre d'essais utilisés | Total essais utilisés | - | Hebdomadaire |
| Nombre d'essais annulés | Total essais annulés | - | Hebdomadaire |

### 11.3. Dashboard Recommandé

**Métriques à afficher** :
- Graphique : Essais gratuits utilisés par mois
- Graphique : Taux de conversion essai → adhésion
- Tableau : Top 10 utilisateurs ayant utilisé leur essai
- Alerte : Si taux de réutilisation > 30% (possible abus)

### 11.4. Champs de Base de Données

**Champs existants** :
- `attendances.free_trial_used` : Boolean (existe déjà)
- `attendances.status` : Enum (existe déjà, permet de tracker canceled)

**Champs optionnels (pour tracking avancé)** :
- `attendances.free_trial_used_at` : Timestamp (NEW, optionnel)
- `memberships.free_trial_assigned_at` : Timestamp (NEW, optionnel, pour tracker quand l'essai a été attribué)

**Note** : Ces champs ne sont pas nécessaires pour le fonctionnement, mais peuvent être utiles pour les métriques avancées.

---

---

**Navigation** :
- [← Section précédente](10-javascript-serveur.md)
- [← Retour à l'index](index.md)
- [→ Section suivante](12-implementation-technique.md)
