# 1. Règles Générales

**Version** : 3.3  
**Dernière mise à jour** : 2025-01-20  
**Responsable** : Assistant IA  
**Statut** : ✅ Validé

[← Retour à l'index](index.md)

## 1.1. Qui peut utiliser l'essai gratuit ?

### Pour les Enfants

**Règle métier** : 
- Par défaut, tous les enfants sont créés avec le statut `pending` et ont automatiquement un essai gratuit disponible (optionnel)
- Exception : Si le parent coche "Créer avec essai gratuit obligatoire" (`create_trial = "1"`), l'enfant est créé avec le statut `trial` et l'essai gratuit est obligatoire

**Qui crée l'enfant ?**
- Le **parent** crée le profil enfant via le formulaire `/memberships/new?child=true`
- Par défaut, l'enfant est créé **automatiquement** en statut `pending` (adhésion en attente de paiement)
- Si `create_trial = "1"`, l'enfant est créé en statut `trial` (non adhérent)
- L'essai gratuit est **automatiquement attribué** lors de la création (pas de champ explicite dans la DB, c'est implicite)

**À quelle étape ?**
- **T0** : Parent remplit le formulaire d'inscription enfant
- **T1** : Parent soumet le formulaire
- **T2** : Système crée `Membership` avec `status = "pending"` et `is_child_membership = true`
- **T3** : L'enfant a maintenant un essai gratuit disponible (implicite, pas de champ DB)

**Est-ce qu'un enfant peut avoir un profil SANS essai gratuit ?**
- ❌ **NON** : Tous les enfants créés via le formulaire parent ont automatiquement un essai gratuit disponible
- ⚠️ **Exception** : Si l'enfant a déjà utilisé son essai gratuit (attendance active avec `free_trial_used = true`), l'essai n'est plus disponible

**Code réel de création** :
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
    # ... autres champs
  )
end
```

### Pour les Adultes

- **Adultes non adhérents** : Un adulte sans adhésion active peut utiliser son essai gratuit lors de l'inscription à une initiation
- **Un seul essai gratuit par adulte** : Un adulte ne peut utiliser son essai gratuit qu'une seule fois (attendance active)

## 1.2. Restrictions

- **Un seul essai gratuit par personne** : Un adulte ne peut utiliser son essai gratuit qu'une seule fois (attendance active)
- **Un seul essai gratuit par enfant** : Chaque enfant ne peut utiliser son essai gratuit qu'une seule fois (attendance active)
- **Indépendance parent/enfant** : L'essai gratuit du parent est indépendant de celui des enfants (et vice versa)
- **Uniquement pour les initiations** : L'essai gratuit n'est disponible que pour les initiations, pas pour les événements/randos normaux

## 1.3. Réutilisation après annulation

**Si un utilisateur se désinscrit d'une initiation où il avait utilisé son essai gratuit :**
- L'essai gratuit redevient disponible
- Il peut s'inscrire à nouveau à une initiation en utilisant son essai gratuit
- Seules les attendances avec `status = "canceled"` sont exclues des vérifications

**Cas limites détaillés** :
- **Cas limite 5.3** : [Annulation puis Double Inscription](05-cas-limites.md#53-annulation-puis-double-inscription) - Protection contre les race conditions lors de réinscriptions parallèles après annulation
- **Cas limite 5.6** : [Réinscription à la Même Initiation Après Annulation](05-cas-limites.md#56-réinscription-à-la-même-initiation-après-annulation) - Réutilisation de l'essai gratuit pour la même initiation après annulation

**Exemple concret** :
```
T0: Enfant créé → pending + essai gratuit disponible (implicite)
T1: Enfant s'inscrit à Initiation A → Attendance créée avec free_trial_used = true
T2: Essai gratuit "utilisé" = bloqué pour autres initiations
T3: Enfant annule Initiation A → Attendance.status = "canceled"
T4: Essai gratuit redevient disponible (scope .active exclut canceled)
T5: Enfant peut s'inscrire à Initiation B avec essai gratuit
```

**Voir aussi** :
- [Section détaillée : Réutilisation après annulation](16-reutilisation-annulation.md) - Exemple complet avec code
- [Cas limites complets](05-cas-limites.md) - Tous les cas limites documentés (5.1 à 5.6)

---

**Navigation** :
- [← Retour à l'index](index.md)
- [→ Section suivante : Clarification Statut `pending`](02-statut-pending.md)
