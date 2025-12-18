# 13. Flux de Création Enfant

[← Retour à l'index](index.md)

### 13.1. Formulaire de Création

**Quel formulaire ?**
- Route : `/memberships/new?child=true`
- Vue : `app/views/memberships/child_form.html.erb`
- Contrôleur : `MembershipsController#new` (action `new`)

**Validations ?**
- Nom, prénom, date de naissance : Obligatoires
- Questionnaire de santé : 9 questions obligatoires
- RGPD, autorisation parentale : Obligatoires si enfant < 16 ans
- Certificat médical : Obligatoire pour FFRS si réponses OUI ou nouvelle licence

**L'enfant est créé en pending automatiquement ?**
- ✅ **OUI** : Par défaut, tous les enfants sont créés avec `status = "pending"`
- ⚠️ **Exception** : Si `create_trial = "1"`, l'enfant est créé avec `status = "trial"`

**Quand `create_trial = "1"` ? Qui le définit ?**
- Le **parent** peut cocher une option dans le formulaire pour créer l'enfant avec le statut `trial`
- Cette option est affichée dans le formulaire si l'enfant n'a pas encore utilisé son essai gratuit
- Si `create_trial = "1"` : L'enfant est créé en `trial` (essai gratuit obligatoire)
- Si `create_trial` n'est pas coché : L'enfant est créé en `pending` (essai gratuit optionnel)

**Formulaire parent pour créer enfant en trial vs pending** :
- Route : `/memberships/new?child=true`
- Vue : `app/views/memberships/child_form.html.erb`
- Le formulaire contient une checkbox optionnelle "Créer avec essai gratuit obligatoire" qui définit `create_trial = "1"`
- Si la checkbox n'est pas cochée, l'enfant est créé en `pending` par défaut

**Essai gratuit attribué d'office ?**
- ✅ **OUI** : Tous les enfants créés ont automatiquement un essai gratuit disponible (implicite)
- L'essai gratuit n'est pas stocké dans la DB, c'est un droit automatique
- L'essai gratuit est "utilisé" lorsqu'une `Attendance` est créée avec `free_trial_used = true`

### 13.2. Code Réel de Création

```ruby
# app/controllers/memberships_controller.rb
def create_child_membership_from_params(child_params, index)
  # ...
  # Vérifier si c'est un essai gratuit (statut trial)
  create_trial = params[:create_trial] == "1" || child_params[:create_trial] == "1"
  
  if create_trial
    membership_status = :trial  # Statut trial = essai gratuit explicite
  else
    membership_status = :pending  # Statut pending = adhésion en attente + essai gratuit implicite
  end
  
  # Créer l'adhésion enfant
  membership = Membership.create!(
    user: current_user, # Le parent
    status: membership_status,
    is_child_membership: true,
    child_first_name: child_first_name,
    child_last_name: child_last_name,
    child_date_of_birth: child_date_of_birth,
    # ... autres champs
  )
  
  # L'essai gratuit est automatiquement disponible (implicite, pas de champ DB)
  # Il sera "utilisé" lors de la création d'une Attendance avec free_trial_used = true
end
```

---

---

**Navigation** :
- [← Section précédente](12-implementation-technique.md)
- [← Retour à l'index](index.md)
- [→ Section suivante](14-flux-inscription.md)
