# 16. Peut-on Réutiliser l'Essai Après Annulation ?

[← Retour à l'index](index.md)

### 16.1. Règle

✅ **OUI** : Si un utilisateur annule une initiation où il avait utilisé son essai gratuit, l'essai gratuit redevient disponible.

### 16.2. Exemple Concret

**Timeline** :
```
T0: Enfant créé en pending + essai gratuit disponible (implicite)
    BD: memberships = [child (status: "pending")]
    BD: attendances = []

T1: Enfant s'inscrit à Initiation A (essai gratuit utilisé)
    Controller: Crée Attendance avec free_trial_used = true
    BD: attendances = [attendance_A (free_trial_used: true, status: "registered")]

T2: Essai gratuit "utilisé" = bloqué pour autres initiations
    BD: attendances.active.where(free_trial_used: true) → [attendance_A]

T3: Enfant annule Initiation A
    Controller: Met à jour attendance_A.status = "canceled"
    BD: attendances = [attendance_A (free_trial_used: true, status: "canceled")]

T4: Essai gratuit redevient disponible
    BD: attendances.active.where(free_trial_used: true) → [] (vide, car .active exclut canceled)

T5: Enfant peut s'inscrire à Initiation B avec essai gratuit
    Controller: Vérifie .active → aucun résultat → autorise l'inscription
    Controller: Crée Attendance avec free_trial_used = true
    BD: attendances = [
      attendance_A (free_trial_used: true, status: "canceled"),
      attendance_B (free_trial_used: true, status: "registered")
    ]
```

**Checkbox réapparaît ?**
- ✅ **OUI** : La checkbox réapparaît dans le formulaire d'inscription
- Le système calcule `can_use_trial = true` car le scope `.active` exclut l'attendance annulée

**Peut réutiliser essai ?**
- ✅ **OUI** : L'enfant peut réutiliser son essai gratuit après annulation

### 16.3. Code Réel

```ruby
# app/controllers/initiations/attendances_controller.rb
def destroy
  # ...
  attendance = current_user.attendances.find_by!(
    event: @initiation,
    child_membership_id: child_membership_id
  )
  
  # Annuler l'attendance
  attendance.update!(status: :canceled)
  
  # L'essai gratuit redevient automatiquement disponible
  # car le scope .active exclut les attendances canceled
end
```

---

---

**Navigation** :
- [← Section précédente](15-quand-essai-utilise.md)
- [← Retour à l'index](index.md)
- [→ Section suivante](17-resume-corrections-v3.md)
