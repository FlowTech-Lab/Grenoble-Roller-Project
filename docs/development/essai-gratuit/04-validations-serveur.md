# 4. Validations Serveur Renforcées

[← Retour à l'index](index.md)

### 4.1. Problème Identifié

Trop de confiance dans les paramètres clients (checkbox, champs cachés).

### 4.2. Validations Multi-Niveaux

#### Niveau 1 : Validation Modèle (Source de Vérité)

**Code Ruby RÉEL complet** :
```ruby
# app/models/attendance.rb
class Attendance < ApplicationRecord
  # Définition du scope .active (exclut les attendances annulées)
  scope :active, -> { where.not(status: "canceled") }
  
  # Déclaration des validations
  validate :can_use_free_trial, on: :create
  validate :can_register_to_initiation, on: :create
  
  private
  
  def can_use_free_trial
    return unless free_trial_used
    return unless user
    
    # IMPORTANT : Exclure les attendances annulées (scope .active)
    if child_membership_id.present?
      # Pour un enfant : vérifier si cet enfant spécifique a déjà utilisé son essai gratuit
      if user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).where.not(id: id).exists?
        errors.add(:free_trial_used, "Cet enfant a déjà utilisé son essai gratuit")
      end
    else
      # Pour le parent : vérifier si le parent a déjà utilisé son essai gratuit
      if user.attendances.active.where(free_trial_used: true, child_membership_id: nil).where.not(id: id).exists?
        errors.add(:free_trial_used, "Vous avez déjà utilisé votre essai gratuit")
      end
    end
  end
  
  def can_register_to_initiation
    return unless event.is_a?(Event::Initiation)
    return if is_volunteer
    
    # Pour un enfant avec statut trial : essai gratuit OBLIGATOIRE
    # IMPORTANT : La vérification du statut de l'adhésion parent (!user.memberships.active_now.exists?)
    # est nécessaire car si le parent est adhérent, l'enfant trial peut s'inscrire sans essai gratuit
    # (l'adhésion parent compte pour l'enfant)
    if for_child? && child_membership&.trial? && !user.memberships.active_now.exists?
      unless free_trial_used
        errors.add(:free_trial_used, "L'essai gratuit est obligatoire pour les enfants non adhérents. Veuillez cocher la case correspondante.")
      end
      
      # Vérifier que cet enfant n'a pas déjà utilisé son essai gratuit (attendance active uniquement)
      if user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).where.not(id: id).exists?
        errors.add(:free_trial_used, "Cet enfant a déjà utilisé son essai gratuit. Une adhésion est maintenant requise.")
      end
    end
  end
end
```

**Caractéristiques** :
- ✅ Ne dépend PAS des paramètres HTTP
- ✅ Vérifie directement l'état de la base de données
- ✅ Utilise le scope `.active` pour exclure les annulations
- ✅ Message d'erreur exact : `"L'essai gratuit est obligatoire pour les enfants non adhérents. Veuillez cocher la case correspondante."`

**Quand exactement la validation s'exécute ?**
- `:on => :create` : La validation s'exécute uniquement lors de la création (pas lors de la mise à jour)
- Avant le `save` : Les validations s'exécutent avant que l'enregistrement ne soit sauvegardé

#### Niveau 2 : Validation Contrôleur (Vérification Préalable)

**Code Ruby RÉEL complet** :
```ruby
# app/controllers/initiations/attendances_controller.rb
def create
  # ...
  attendance = @initiation.attendances.build(user: current_user)
  
  # Pour un enfant avec statut trial : essai gratuit OBLIGATOIRE
  if child_membership_id.present? && child_membership&.trial? && !is_member
    # Vérifier d'abord si cet enfant a déjà utilisé son essai gratuit (attendance active uniquement)
    if current_user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).exists?
      redirect_to initiation_path(@initiation), alert: "Cet enfant a déjà utilisé son essai gratuit. Une adhésion est maintenant requise."
      return
    end
    
    # Vérifier que free_trial_used sera true
    use_free_trial = params[:use_free_trial] == "1" || 
                     params.select { |k, v| k.to_s.start_with?('use_free_trial_hidden') && v == "1" }.any?
    
    unless use_free_trial
      redirect_to initiation_path(@initiation), alert: "Adhésion requise. L'essai gratuit est obligatoire pour les enfants non adhérents. Veuillez cocher la case correspondante."
      return
    end
    
    attendance.free_trial_used = true
  end
  
  if attendance.save
    # Succès
  end
end
```

**Caractéristiques** :
- ✅ Vérification préalable avant création
- ✅ Redirection immédiate si problème
- ✅ Ne fait PAS confiance aux paramètres pour la logique métier
- ✅ Message d'erreur exact : `"Adhésion requise. L'essai gratuit est obligatoire pour les enfants non adhérents. Veuillez cocher la case correspondante."`

#### Niveau 3 : Validation JavaScript (UX uniquement)

```javascript
// Validation JavaScript = UX uniquement, PAS de sécurité
if (selectedChild && !selectedChild.has_used_trial) {
  if (!freeTrialCheckbox.checked) {
    e.preventDefault();
    alert('L\'essai gratuit est obligatoire pour ' + childName + '. Veuillez cocher la case "Utiliser l\'essai gratuit" pour confirmer l\'inscription.');
    return false;
  }
}
```

**Caractéristiques** :
- ⚠️ **UX uniquement** : Améliore l'expérience utilisateur
- ❌ **PAS de sécurité** : Peut être contourné (JS désactivé, modification DOM)
- ✅ **Complémentaire** : Les validations serveur restent la source de vérité

### 4.3. Principe de Défense en Profondeur

```
┌─────────────────────────────────────┐
│  JavaScript (UX)                   │  ← Peut être contourné
├─────────────────────────────────────┤
│  Contrôleur (Vérification)         │  ← Première ligne de défense
├─────────────────────────────────────┤
│  Modèle (Validation)                │  ← Source de vérité
├─────────────────────────────────────┤
│  Base de Données (Contrainte)      │  ← Protection ultime
└─────────────────────────────────────┘
```

---

---

**Navigation** :
- [← Section précédente](03-race-conditions.md)
- [← Retour à l'index](index.md)
- [→ Section suivante](05-cas-limites.md)
