# 12. Implémentation Technique - Vues

[← Retour à l'index](index.md)

### 12.1. Utilisation du Scope `.active`

**Définition du scope `.active`** :
```ruby
# app/models/attendance.rb
class Attendance < ApplicationRecord
  # Scope qui exclut les attendances annulées
  # Utilisé pour toutes les vérifications d'essai gratuit
  scope :active, -> { where.not(status: "canceled") }
  # ...
end
```

**RÈGLE CRITIQUE** : Toutes les vérifications d'essai gratuit dans les vues (`_registration_form_fields.html.erb`) doivent utiliser le scope `.active` pour exclure les attendances annulées.

**Pourquoi ce scope est important** :
- Les attendances avec `status = "canceled"` ne doivent pas être comptées comme "essai gratuit utilisé"
- Si un utilisateur annule une initiation où il avait utilisé son essai gratuit, l'essai redevient disponible
- Le scope `.active` garantit que seules les attendances actives (non annulées) sont prises en compte

**Exemples corrects** :
```ruby
# ✅ CORRECT : Utilise .active
parent_can_use_trial = !current_user.memberships.active_now.exists? && 
                       !current_user.attendances.active.where(free_trial_used: true, child_membership_id: nil).exists?

any_child_has_trial = trial_children.any? { |child| 
  !current_user.attendances.active.where(free_trial_used: true, child_membership_id: child.id).exists?
}

trial_children_data = trial_children.map do |child|
  {
    has_used_trial: current_user.attendances.active.where(free_trial_used: true, child_membership_id: child.id).exists?,
    can_use_trial: !current_user.attendances.active.where(free_trial_used: true, child_membership_id: child.id).exists?
  }
end
```

**Exemples incorrects** :
```ruby
# ❌ INCORRECT : N'utilise pas .active (inclut les attendances annulées)
parent_can_use_trial = !current_user.attendances.where(free_trial_used: true, child_membership_id: nil).exists?
```

### 12.2. Échappement JavaScript

**RÈGLE** : Les noms d'enfants dans les template literals JavaScript doivent être échappés pour éviter les erreurs de syntaxe.

**Exemple correct** :
```javascript
// ✅ CORRECT : Échappement des caractères spéciaux
const childNameEscaped = String(selectedChild.name || '').replace(/&/g, '&amp;').replace(/'/g, '&#39;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
freeTrialHelpText.innerHTML = '<strong>Essai gratuit pour ' + childNameEscaped + ' :</strong> ...';
```

**Exemple incorrect** :
```javascript
// ❌ INCORRECT : Template literal avec interpolation non échappée
freeTrialHelpText.innerHTML = `<strong>Essai gratuit pour ${selectedChild.name} :</strong> ...`;
```

### 12.3. Cohérence Modèle/Vue/Contrôleur

**Règle** : Les vérifications d'essai gratuit doivent être cohérentes entre :
- **Modèle** (`Attendance`) : Utilise `.active.where()` ✅
- **Contrôleur** (`Initiations::AttendancesController`) : Utilise `.active.where()` ✅
- **Vue** (`_registration_form_fields.html.erb`) : Doit utiliser `.active.where()` ✅

**Vérification** : Tous les fichiers doivent utiliser le même pattern :
```ruby
current_user.attendances.active.where(free_trial_used: true, child_membership_id: ...)
```

---

---

**Navigation** :
- [← Section précédente](11-metriques-kpis.md)
- [← Retour à l'index](index.md)
- [→ Section suivante](13-flux-creation-enfant.md)
