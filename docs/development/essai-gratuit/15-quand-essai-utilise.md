# 15. Quand l'Essai Gratuit est "Utilisé" ?

[← Retour à l'index](index.md)

### 15.1. Timeline Précise

**À la création de l'attendance ?**
- ✅ **OUI** : L'essai gratuit est marqué comme utilisé lors de la création de l'`Attendance` avec `free_trial_used = true`
- Cela se fait dans le contrôleur, avant le `save`

**Ou à la validation de l'attendance ?**
- ❌ **NON** : La validation vérifie que l'essai n'a pas déjà été utilisé, mais ne le marque pas comme utilisé
- Le marquage se fait dans le contrôleur avant le `save`

**Ou quand l'enfant participe effectivement ?**
- ❌ **NON** : L'essai gratuit est utilisé dès la création de l'`Attendance`, pas lors de la participation

### 15.2. Code Réel

```ruby
# app/controllers/initiations/attendances_controller.rb
def create
  # ...
  attendance = @initiation.attendances.build(user: current_user)
  attendance.status = "registered"
  
  # Marquer l'essai gratuit comme utilisé (AVANT le save)
  if params[:use_free_trial] == "1"
    attendance.free_trial_used = true  # ← ICI : Essai gratuit marqué comme utilisé
  end
  
  # Le save déclenche les validations
  if attendance.save  # ← ICI : Validations s'exécutent (vérifient l'unicité)
    # Succès
  end
end
```

---

---

**Navigation** :
- [← Section précédente](14-flux-inscription.md)
- [← Retour à l'index](index.md)
- [→ Section suivante](16-reutilisation-annulation.md)
