# 14. Flux d'Inscription à Initiation

[← Retour à l'index](index.md)

### 14.1. Sélection Enfant

**Parent sélectionne enfant (pending avec essai)**
- Dropdown affiche tous les enfants avec statut `active`, `trial` ou `pending`
- Pour chaque enfant, le système calcule si l'essai gratuit est disponible

### 14.2. Affichage Checkbox Essai Gratuit

**Checkbox essai gratuit : affichée ? cochée ? obligatoire ?**

**Pour enfant `pending`** :
- ✅ **Affichée** : Si l'enfant n'a pas encore utilisé son essai gratuit
- ❌ **Pas cochée par défaut** : L'essai gratuit est optionnel (l'adhésion `pending` est valide)
- ❌ **Pas obligatoire** : L'enfant peut s'inscrire sans utiliser l'essai gratuit

**Pour enfant `trial`** :
- ✅ **Affichée** : Si l'enfant n'a pas encore utilisé son essai gratuit
- ✅ **Cochée par défaut** : L'essai gratuit est obligatoire
- ✅ **Obligatoire** : L'enfant DOIT utiliser son essai gratuit pour s'inscrire

### 14.3. Soumission et Utilisation Essai Gratuit

**Parent soumet**
- Le contrôleur reçoit `params[:use_free_trial]` (checkbox ou champ caché)
- Pour enfant `trial` : Le contrôleur vérifie que `use_free_trial` est présent
- Pour enfant `pending` : Le contrôleur utilise l'essai gratuit si `use_free_trial = "1"`, sinon l'enfant s'inscrit sans essai gratuit

**Serveur utilise essai gratuit**
- Le contrôleur crée `Attendance` avec `free_trial_used = true` si l'essai est utilisé
- Le modèle valide que l'essai n'a pas déjà été utilisé (scope `.active`)

**Enfant reste pending (en attente de paiement) ?**
- ✅ **OUI** : L'adhésion reste en `pending` même après l'utilisation de l'essai gratuit
- L'essai gratuit permet de s'inscrire à une initiation sans payer l'adhésion
- Après l'initiation, le parent doit finaliser le paiement de l'adhésion pour continuer

**Ou change de statut ?**
- ❌ **NON** : Le statut de l'adhésion ne change pas lors de l'inscription à une initiation
- Le statut change uniquement lors du paiement : `pending` → `active`

### 14.4. Code Réel d'Inscription

```ruby
# app/controllers/initiations/attendances_controller.rb
def create
  # ...
  child_membership_id = params[:child_membership_id].presence
  is_volunteer = params[:is_volunteer] == "1"
  
  # IMPORTANT : Définir child_membership AVANT son utilisation
  child_membership = child_membership_id.present? ? current_user.memberships.find_by(id: child_membership_id) : nil
  
  # Construction de l'attendance
  attendance = @initiation.attendances.build(user: current_user)
  attendance.status = "registered"
  attendance.child_membership_id = child_membership_id
  
  # Vérifier si l'utilisateur est adhérent (DÉFINITION DE is_member)
  is_member = if child_membership_id.present?
    # Pour un enfant : vérifier l'adhésion enfant (active, trial ou pending)
    unless child_membership&.active? || child_membership&.trial? || child_membership&.pending?
      redirect_to initiation_path(@initiation), alert: "L'adhésion de cet enfant n'est pas active."
      return
    end
    # L'enfant est considéré comme membre si l'adhésion est active ou pending (pas trial)
    child_membership.active? || child_membership.pending?
  else
    # Pour le parent : vérifier adhésion parent ou enfant
    current_user.memberships.active_now.exists? ||
      current_user.memberships.where(is_child_membership: true)
        .where(status: [Membership.statuses[:active], Membership.statuses[:trial], Membership.statuses[:pending]])
        .exists?
  end
  
  # Pour un enfant avec statut pending : essai gratuit optionnel
  if child_membership_id.present? && child_membership&.pending?
    # L'enfant peut s'inscrire sans utiliser l'essai gratuit (pending = valide)
    # Mais peut aussi utiliser son essai gratuit si disponible
    if params[:use_free_trial] == "1"
      # Vérifier que l'essai n'a pas déjà été utilisé (attendance active uniquement)
      unless current_user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).exists?
        attendance.free_trial_used = true
      end
    end
  end
  
  # Pour un enfant avec statut trial : essai gratuit OBLIGATOIRE (seulement si parent non adhérent)
  if child_membership_id.present? && child_membership&.trial? && !is_member
    # Vérifier d'abord si cet enfant a déjà utilisé son essai gratuit
    if current_user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).exists?
      redirect_to initiation_path(@initiation), alert: "Cet enfant a déjà utilisé son essai gratuit. Une adhésion est maintenant requise."
      return
    end
    
    # Essai gratuit OBLIGATOIRE
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

---

---

**Navigation** :
- [← Section précédente](13-flux-creation-enfant.md)
- [← Retour à l'index](index.md)
- [→ Section suivante](15-quand-essai-utilise.md)
