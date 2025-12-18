# 18. Clarifications Supplémentaires

[← Retour à l'index](index.md)

### 18.1. Essai Gratuit Parent Quand Adhésion Active

**Question** : Si le parent a une adhésion active, peut-il quand même utiliser son essai gratuit ?

**Réponse** :
- ❌ **NON** : Si le parent a une adhésion active, il n'a pas besoin d'utiliser son essai gratuit
- L'essai gratuit est uniquement pour les non-adhérents
- Si le parent est adhérent, il peut s'inscrire directement sans utiliser l'essai gratuit

**Code réel** :
```ruby
# app/controllers/initiations/attendances_controller.rb
is_member = current_user.memberships.active_now.exists? ||
            current_user.memberships.where(is_child_membership: true)
              .where(status: [Membership.statuses[:active], Membership.statuses[:trial], Membership.statuses[:pending]])
              .exists?

if is_member
  # Parent est adhérent → pas besoin d'essai gratuit
  # L'inscription est autorisée directement
else
  # Parent n'est pas adhérent → essai gratuit requis (si pas de places découverte)
  if params[:use_free_trial] == "1"
    attendance.free_trial_used = true
  end
end
```

### 18.2. Essai Gratuit Enfant Trial Quand Parent Adhérent

**Question** : Si le parent a une adhésion active, l'enfant avec statut `trial` doit-il quand même utiliser son essai gratuit ?

**Réponse** :
- ❌ **NON** : Si le parent a une adhésion active, l'enfant `trial` peut s'inscrire sans utiliser son essai gratuit
- La vérification `!user.memberships.active_now.exists?` dans la validation garantit que l'essai gratuit n'est obligatoire que si le parent n'est pas adhérent
- Si le parent est adhérent, l'adhésion parent compte pour l'enfant

**Code réel côté serveur** :
```ruby
# app/models/attendance.rb
def can_register_to_initiation
  # ...
  # Pour un enfant avec statut trial : essai gratuit OBLIGATOIRE seulement si parent non adhérent
  if for_child? && child_membership&.trial? && !user.memberships.active_now.exists?
    # Essai gratuit obligatoire
  end
end

# app/controllers/initiations/attendances_controller.rb
if child_membership_id.present? && child_membership&.trial? && !is_member
  # Essai gratuit obligatoire (seulement si parent non adhérent)
end
```

**Code JavaScript côté client** :
```javascript
// Le JavaScript ne peut PAS savoir si le parent est adhérent (information serveur uniquement)
// Le JavaScript affiche la checkbox pour tous les enfants trial, mais le serveur valide
if (selectedChild.status === "trial" && !selectedChild.has_used_trial) {
  // Affiche checkbox obligatoire
  freeTrialCheckbox.checked = true;
  freeTrialCheckbox.required = true;
}
```

**Protection multi-niveaux** :
- ✅ **JavaScript** : Affiche la checkbox obligatoire pour tous les enfants `trial` (UX)
- ✅ **Contrôleur** : Vérifie `!is_member` avant d'exiger l'essai gratuit (première ligne de défense)
- ✅ **Modèle** : Vérifie `!user.memberships.active_now.exists?` avant d'exiger l'essai gratuit (source de vérité)

**Résultat** : Si le parent est adhérent, l'enfant `trial` peut s'inscrire sans utiliser son essai gratuit, même si la checkbox est affichée côté JavaScript. Le serveur autorise l'inscription sans essai gratuit.

---

---

---

**Navigation** :
- [← Section précédente](17-resume-corrections-v3.md)
- [← Retour à l'index](index.md)
- [→ Section suivante](19-resume-corrections-v3-1.md)
