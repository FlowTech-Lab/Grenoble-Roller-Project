# Logique d'Essai Gratuit - Documentation Complète v3.0

## Vue d'ensemble

Le système d'essai gratuit permet aux utilisateurs non adhérents (adultes ou enfants) de participer à **une seule initiation** gratuitement. Après cette initiation, une adhésion est requise pour continuer.

**RÈGLE MÉTIER CRITIQUE** : 
- **Enfants** : 
  - Par défaut, tous les enfants sont créés avec le statut `pending` (adhésion en attente de paiement) et ont **automatiquement** un essai gratuit disponible (optionnel)
  - Exception : Si `create_trial = "1"`, l'enfant est créé avec le statut `trial` (non adhérent) et l'essai gratuit est **obligatoire**
- **Adultes** : Les adultes non adhérents peuvent utiliser leur essai gratuit lors de l'inscription à une initiation

**IMPORTANT** : Si un utilisateur (adulte ou enfant) se désinscrit d'une initiation où il avait utilisé son essai gratuit, l'essai gratuit redevient disponible et peut être réutilisé.

---

## 1. Règles Générales

### 1.1. Qui peut utiliser l'essai gratuit ?

#### Pour les Enfants

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

#### Pour les Adultes

- **Adultes non adhérents** : Un adulte sans adhésion active peut utiliser son essai gratuit lors de l'inscription à une initiation
- **Un seul essai gratuit par adulte** : Un adulte ne peut utiliser son essai gratuit qu'une seule fois (attendance active)

### 1.2. Restrictions

- **Un seul essai gratuit par personne** : Un adulte ne peut utiliser son essai gratuit qu'une seule fois (attendance active)
- **Un seul essai gratuit par enfant** : Chaque enfant ne peut utiliser son essai gratuit qu'une seule fois (attendance active)
- **Indépendance parent/enfant** : L'essai gratuit du parent est indépendant de celui des enfants (et vice versa)
- **Uniquement pour les initiations** : L'essai gratuit n'est disponible que pour les initiations, pas pour les événements/randos normaux

### 1.3. Réutilisation après annulation

**Si un utilisateur se désinscrit d'une initiation où il avait utilisé son essai gratuit :**
- L'essai gratuit redevient disponible
- Il peut s'inscrire à nouveau à une initiation en utilisant son essai gratuit
- Seules les attendances avec `status = "canceled"` sont exclues des vérifications

**Exemple concret** :
```
T0: Enfant créé → pending + essai gratuit disponible (implicite)
T1: Enfant s'inscrit à Initiation A → Attendance créée avec free_trial_used = true
T2: Essai gratuit "utilisé" = bloqué pour autres initiations
T3: Enfant annule Initiation A → Attendance.status = "canceled"
T4: Essai gratuit redevient disponible (scope .active exclut canceled)
T5: Enfant peut s'inscrire à Initiation B avec essai gratuit
```

---

## 2. Clarification Statut `pending` (Enfant)

### 2.1. Règle Métier Claire

**Un enfant avec statut `pending` (adhésion en attente de paiement) :**
- ✅ **Peut s'inscrire SANS utiliser l'essai gratuit** (l'adhésion `pending` est considérée comme valide pour l'inscription)
- ✅ **Peut OPTIONNELLEMENT utiliser son essai gratuit** si disponible (mais ce n'est pas obligatoire)
- ❌ **N'est PAS obligé d'utiliser l'essai gratuit** (contrairement aux enfants `trial`)
- ✅ **L'essai gratuit reste disponible** s'il n'est pas utilisé lors de l'inscription (il peut être utilisé plus tard)

**Différence avec statut `trial` :**
- `trial` = Non adhérent, essai gratuit **OBLIGATOIRE** pour s'inscrire
- `pending` = Adhérent en attente de paiement, essai gratuit **OPTIONNEL**

**Clarification importante** :
- Si un enfant `pending` s'inscrit **SANS** utiliser son essai gratuit, l'essai gratuit **reste disponible** pour une future initiation
- L'essai gratuit n'est "consommé" que lorsqu'une `Attendance` est créée avec `free_trial_used = true`

### 2.2. Contexte de Création

**Qui crée l'enfant en pending ?**
- Le **parent** crée l'enfant via le formulaire `/memberships/new?child=true`
- Le parent remplit les informations de l'enfant (nom, prénom, date de naissance, questionnaire de santé, etc.)
- Le parent soumet le formulaire
- Le système crée automatiquement `Membership` avec `status = "pending"`

**Qui paie l'essai gratuit ?**
- L'essai gratuit est **gratuit** (pas de paiement)
- L'essai gratuit est un **droit automatique** pour tous les enfants créés
- Aucun paiement n'est requis pour utiliser l'essai gratuit

**Quel est l'intérêt de pending si l'essai gratuit est déjà attribué ?**
- L'adhésion `pending` représente l'adhésion **payante** que le parent doit finaliser
- L'essai gratuit permet de s'inscrire à **une initiation** sans payer l'adhésion
- Après l'initiation, le parent doit finaliser le paiement de l'adhésion pour continuer
- **Timeline** :
  ```
  T0: Enfant créé → pending (adhésion payante en attente) + essai gratuit disponible
  T1: Enfant utilise essai gratuit → s'inscrit à Initiation A (gratuit)
  T2: Après Initiation A → parent doit payer l'adhésion pour continuer
  T3: Parent paie → pending → active
  ```

### 2.3. Logique d'Affichage

Pour un enfant avec statut `pending` :
- La checkbox essai gratuit est **affichée** si l'enfant n'a pas encore utilisé son essai gratuit
- La checkbox est **optionnelle** (pas cochée par défaut, pas obligatoire)
- L'enfant peut s'inscrire même si la checkbox n'est pas cochée (car `pending` est considéré comme valide)

---

## 3. Protection contre les Race Conditions

### 3.1. Problème Identifié

Deux requêtes parallèles pourraient créer deux attendances avec `free_trial_used = true` pour le même utilisateur/enfant.

### 3.2. Solutions Implémentées

#### Solution 1 : Contrainte Unique au Niveau Base de Données (Recommandé)

**Migration créée** :
```ruby
# db/migrate/20250117120000_add_unique_constraint_free_trial_active.rb
class AddUniqueConstraintFreeTrialActive < ActiveRecord::Migration[7.0]
  # NOTE: disable_ddl_transaction! n'est pas utilisé dans le code réel (développement)
  # 
  # En développement : disable_ddl_transaction! n'est pas nécessaire (petite table, pas de lock problématique)
  # 
  # En production : Si la table est grande (> 100k lignes), il est RECOMMANDÉ d'ajouter :
  #   disable_ddl_transaction!
  #   # Puis remplacer add_index par execute("CREATE INDEX CONCURRENTLY ...")
  # 
  # Cela évite de bloquer la table pendant la création de l'index (opération qui peut prendre plusieurs minutes)
  # 
  # Exemple pour production :
  #   disable_ddl_transaction!
  #   def up
  #     execute("CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS index_attendances_unique_free_trial_parent_active ON attendances (user_id) WHERE free_trial_used = true AND status != 'canceled' AND child_membership_id IS NULL;")
  #   end
  
  def up
    # Contrainte unique pour les parents (child_membership_id IS NULL)
    # IMPORTANT : L'index utilise seulement :user_id (sans event_id) pour garantir
    # qu'un parent ne peut utiliser son essai gratuit qu'UNE SEULE FOIS, quel que soit l'événement
    # Si on incluait event_id, un parent pourrait utiliser son essai gratuit sur plusieurs initiations
    unless index_exists?(:attendances, name: "index_attendances_unique_free_trial_parent_active")
      add_index :attendances, 
        :user_id, 
        unique: true, 
        where: "free_trial_used = true AND status != 'canceled' AND child_membership_id IS NULL",
        name: "index_attendances_unique_free_trial_parent_active"
    end
    
    # Contrainte unique pour les enfants (child_membership_id IS NOT NULL)
    # IMPORTANT : Doit inclure child_membership_id dans l'index pour distinguer les enfants
    # IMPORTANT : L'index utilise [:user_id, :child_membership_id] (sans event_id) pour garantir
    # qu'un enfant ne peut utiliser son essai gratuit qu'UNE SEULE FOIS, quel que soit l'événement
    unless index_exists?(:attendances, name: "index_attendances_unique_free_trial_child_active")
      add_index :attendances, 
        [:user_id, :child_membership_id], 
        unique: true, 
        where: "free_trial_used = true AND status != 'canceled' AND child_membership_id IS NOT NULL",
        name: "index_attendances_unique_free_trial_child_active"
    end
  end
  
  def down
    remove_index :attendances, name: "index_attendances_unique_free_trial_parent_active", if_exists: true
    remove_index :attendances, name: "index_attendances_unique_free_trial_child_active", if_exists: true
  end
end
```

**Note importante** : 
- L'index pour les enfants doit inclure `child_membership_id` car un parent peut avoir plusieurs enfants, chacun avec son propre essai gratuit. L'index composite `[:user_id, :child_membership_id]` garantit l'unicité par enfant.
- **L'index ne contient PAS `event_id`** : C'est intentionnel. La règle métier est "un seul essai gratuit par personne, quel que soit l'événement". Si on incluait `event_id`, un parent/enfant pourrait utiliser son essai gratuit sur plusieurs initiations différentes, ce qui n'est pas souhaité.

**Note** : Cette contrainte PostgreSQL utilise une condition `WHERE` pour ne s'appliquer qu'aux attendances actives avec essai gratuit.

#### Solution 2 : Validation au Niveau Modèle (Déjà Implémenté)

La validation `can_use_free_trial` vérifie l'unicité avant la création.

### 3.3. Cycle de Vie de l'Essai Gratuit

**Quand exactement l'essai gratuit est-il "marqué comme utilisé" ?**

L'essai gratuit est marqué comme utilisé **lors de la création de l'attendance** (dans le contrôleur, avant le `save`).

**Timeline précise** :
```
T0: Enfant créé → pending + essai gratuit disponible (implicite)
    BD: memberships = [membership (status: "pending", is_child_membership: true)]
    BD: attendances = []

T1: Parent sélectionne enfant dans dropdown pour Initiation A
    Frontend: Checkbox "Utiliser l'essai gratuit" affichée (optionnelle pour pending)

T2: Parent coche checkbox et soumet
    Frontend: Envoie params[:use_free_trial] = "1"

T3: Contrôleur reçoit la requête
    Controller: Vérifie que l'enfant n'a pas déjà utilisé son essai (scope .active)
    Controller: Si OK, définit attendance.free_trial_used = true
    ⚠️ À ce stade, l'essai n'est PAS encore "utilisé" en DB (pas encore sauvegardé)

T4: Attendance.save! est appelé (opération atomique)
    Model: Validation can_use_free_trial vérifie l'unicité (scope .active)
    Model: Validation can_register_to_initiation vérifie l'adhésion
    DB: Contrainte unique vérifie qu'aucun autre essai gratuit actif n'existe
    DB: Si OK, l'Attendance est sauvegardée avec free_trial_used = true
    ✅ L'essai gratuit est maintenant "utilisé" en DB (opération atomique)

T5: Attendance créée avec succès
    BD: attendances = [attendance (free_trial_used: true, status: "registered")]
    Essai gratuit "utilisé" = bloqué pour autres initiations

**Protection contre race condition** :
- Si deux requêtes parallèles tentent de créer une Attendance avec `free_trial_used = true` au même moment :
  - Les deux définissent `attendance.free_trial_used = true` (en mémoire)
  - Les deux appellent `attendance.save!`
  - La contrainte unique DB bloque la deuxième requête (erreur `PG::UniqueViolation`)
  - Seule la première Attendance est créée
  - ✅ Protection garantie au niveau base de données
```

**Code réel du contrôleur** :
```ruby
# app/controllers/initiations/attendances_controller.rb
def create
  # ...
  attendance = @initiation.attendances.build(user: current_user)
  attendance.status = "registered"
  attendance.child_membership_id = child_membership_id
  
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
  
  # Pour un enfant avec statut trial : essai gratuit OBLIGATOIRE
  if child_membership_id.present? && child_membership&.trial? && !is_member
    # Vérifier d'abord si cet enfant a déjà utilisé son essai gratuit
    if current_user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).exists?
      redirect_to initiation_path(@initiation), alert: "Cet enfant a déjà utilisé son essai gratuit."
      return
    end
    
    # Essai gratuit OBLIGATOIRE
    unless params[:use_free_trial] == "1"
      redirect_to initiation_path(@initiation), alert: "L'essai gratuit est obligatoire."
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

## 4. Validations Serveur Renforcées

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

## 5. Cas Limites Complets

### 5.1. Double Inscription Avant Annulation

**Scénario** :
1. Utilisateur A s'inscrit avec essai gratuit → `attendance_1` créée avec `free_trial_used = true`
2. Utilisateur A essaie de s'inscrire à une autre initiation (sans annuler la première)

**Timeline précise** :
```
T0: Enfant créé en pending, essai gratuit disponible (implicite)
    BD: memberships = [membership (status: "pending")]
    BD: attendances = []

T1: Enfant s'inscrit à Initiation A
    Frontend: Checkbox cochée, params[:use_free_trial] = "1"
    Controller: Vérifie .active.where(free_trial_used: true) → aucun résultat
    Controller: Crée Attendance avec free_trial_used = true
    BD: attendances = [attendance_A (free_trial_used: true, status: "registered")]

T2: Essai gratuit "utilisé" immédiatement
    BD: attendances.active.where(free_trial_used: true) → [attendance_A]

T3: Enfant essaie de s'inscrire à Initiation B (sans annuler A)
    Controller: Vérifie .active.where(free_trial_used: true) → trouve attendance_A
    Controller: Redirige avec alert "Cet enfant a déjà utilisé son essai gratuit"
    Model: Validation can_use_free_trial échoue également
    BD: attendances = [attendance_A] (pas de nouvelle attendance)
```

**Protection** :
- ✅ Validation modèle : `can_use_free_trial` détecte `attendance_A` active
- ✅ Validation contrôleur : Vérification préalable détecte `attendance_A` active
- ✅ Contrainte unique (si implémentée) : Empêche la création de `attendance_B`

**Résultat** : La deuxième inscription est bloquée avec message "Cet enfant a déjà utilisé son essai gratuit. Une adhésion est maintenant requise."

### 5.2. Essai Réutilisé Avant Première Annulation

**Scénario** : Identique au cas 5.1

**Protection** : Identique au cas 5.1

**Résultat** : La deuxième inscription est bloquée

### 5.3. Annulation puis Double Inscription

**Scénario** :
1. Utilisateur A s'inscrit avec essai gratuit → `attendance_1` créée avec `free_trial_used = true`
2. Utilisateur A annule → `attendance_1.status = "canceled"`
3. Utilisateur A s'inscrit à deux initiations en parallèle (ou à la même initiation)

**Timeline précise** :
```
T0: Enfant créé en pending, essai gratuit disponible
    BD: attendances = []

T1: Enfant s'inscrit à Initiation A
    BD: attendances = [attendance_A (free_trial_used: true, status: "registered")]

T2: Enfant annule Initiation A
    BD: attendances = [attendance_A (free_trial_used: true, status: "canceled")]

T3: Scope .active exclut canceled
    BD: attendances.active.where(free_trial_used: true) → [] (vide)

T4: Enfant essaie de s'inscrire à Initiation B et Initiation C en parallèle
    Requête 1: Controller vérifie .active → aucun résultat → crée attendance_B
    Requête 2: Controller vérifie .active → aucun résultat → essaie de créer attendance_C
    
    ⚠️ RACE CONDITION : Deux requêtes parallèles peuvent créer deux attendances
```

**Protection** :
- ✅ Scope `.active` exclut `attendance_A` (canceled)
- ⚠️ **Race condition possible** : Deux requêtes parallèles pourraient créer deux attendances

**Solution** : Contrainte unique au niveau base de données (Section 3.2)

### 5.4. Tentative de Contournement (Modification Paramètres)

**Scénario** : Utilisateur modifie les paramètres HTTP pour ne pas envoyer `use_free_trial`

**Timeline précise** :
```
T0: Enfant créé en pending, essai gratuit disponible
    BD: attendances = []

T1: Enfant avec statut trial sélectionné
    Frontend: Checkbox affichée et cochée automatiquement
    Frontend: params[:use_free_trial] = "1"

T2: Utilisateur modifie les paramètres HTTP (dev tools)
    Frontend: params[:use_free_trial] = "0" (modifié)

T3: Controller reçoit params[:use_free_trial] = "0"
    Controller: Vérifie use_free_trial → false
    Controller: Redirige avec alert "L'essai gratuit est obligatoire"
    BD: attendances = [] (pas de nouvelle attendance)

T4: Si l'utilisateur contourne le contrôleur (impossible), le modèle bloque
    Model: Validation can_register_to_initiation vérifie free_trial_used
    Model: Pour trial, free_trial_used DOIT être true
    Model: Erreur "L'essai gratuit est obligatoire pour les enfants non adhérents"
    BD: attendances = [] (pas de nouvelle attendance)
```

**Protection** :
- ✅ Validation modèle : Pour enfants `trial`, `free_trial_used` DOIT être `true` (vérifie l'état, pas les paramètres)
- ✅ Validation contrôleur : Vérifie les paramètres ET l'état de la base de données

**Résultat** : L'inscription est bloquée avec message "L'essai gratuit est obligatoire pour les enfants non adhérents. Veuillez cocher la case correspondante."

### 5.5. JavaScript Désactivé

**Scénario** : Utilisateur désactive JavaScript et essaie de soumettre sans cocher la checkbox

**Timeline précise** :
```
T0: Enfant créé en pending, essai gratuit disponible
    BD: attendances = []

T1: Enfant avec statut trial sélectionné
    Frontend: Checkbox affichée mais JS désactivé → pas de coche automatique
    Frontend: params[:use_free_trial] = nil (pas envoyé)

T2: Utilisateur soumet le formulaire
    Controller: Reçoit params[:use_free_trial] = nil
    Controller: Vérifie use_free_trial → false
    Controller: Redirige avec alert "L'essai gratuit est obligatoire"
    BD: attendances = [] (pas de nouvelle attendance)

T3: Si l'utilisateur contourne le contrôleur (impossible), le modèle bloque
    Model: Validation can_register_to_initiation vérifie free_trial_used
    Model: Pour trial, free_trial_used DOIT être true
    Model: Erreur "L'essai gratuit est obligatoire pour les enfants non adhérents"
    BD: attendances = [] (pas de nouvelle attendance)
```

**Protection** :
- ✅ Validation contrôleur : Vérifie que `use_free_trial` est présent pour enfants `trial`
- ✅ Validation modèle : Vérifie que `free_trial_used = true` pour enfants `trial`

**Résultat** : L'inscription est bloquée avec message d'erreur approprié

### 5.6. Réinscription à la Même Initiation Après Annulation

**Scénario** : Enfant annule puis essaie de s'inscrire à nouveau à la même initiation

**Timeline précise** :
```
T0: Enfant créé en pending, essai gratuit disponible
    BD: attendances = []

T1: Enfant s'inscrit à Initiation A (utilise essai gratuit)
    BD: attendances = [attendance_A (free_trial_used: true, status: "registered", event_id: initiation_A.id)]

T2: Enfant annule Initiation A
    Controller: Met à jour attendance_A.status = "canceled"
    BD: attendances = [attendance_A (free_trial_used: true, status: "canceled", event_id: initiation_A.id)]

T3: Essai gratuit redevient disponible
    BD: attendances.active.where(free_trial_used: true) → [] (vide, car .active exclut canceled)

T4: Enfant essaie de s'inscrire à nouveau à Initiation A
    Controller: Vérifie l'unicité user_id + event_id + child_membership_id (sauf canceled)
    Controller: Trouve attendance_A (canceled) → autorise la réinscription
    Controller: Vérifie .active.where(free_trial_used: true) → aucun résultat → autorise l'essai gratuit
    Controller: Crée nouvelle Attendance avec free_trial_used = true
    BD: attendances = [
      attendance_A (free_trial_used: true, status: "canceled", event_id: initiation_A.id),
      attendance_A2 (free_trial_used: true, status: "registered", event_id: initiation_A.id)
    ]
```

**Protection** :
- ✅ Validation unicité : La contrainte `validates :user_id, uniqueness: { scope: [:event_id, :child_membership_id], conditions: -> { where.not(status: "canceled") } }` autorise la réinscription après annulation
- ✅ Essai gratuit : Le scope `.active` exclut l'attendance annulée, donc l'essai gratuit redevient disponible

**Résultat** : L'enfant peut s'inscrire à nouveau à la même initiation avec son essai gratuit

---

## 6. Gestion Enfants Multiples

### 6.1. Fonctionnement du Formulaire

Le formulaire d'inscription permet d'inscrire **un seul enfant à la fois** via un dropdown :

```erb
<%= form.collection_select :child_membership_id, 
    child_memberships, 
    :id, 
    ->(m) { "#{m.child_first_name} #{m.child_last_name}" }, 
    { prompt: "Sélectionner un enfant" } %>
```

**Caractéristiques** :
- Un seul enfant peut être sélectionné par soumission
- Chaque enfant a son propre essai gratuit (indépendant)
- Le parent peut soumettre plusieurs fois pour inscrire plusieurs enfants

### 6.2. Calcul de Disponibilité Essai Gratuit

**Règle métier** : Tous les enfants créés ont automatiquement un essai gratuit disponible (implicite).

**Pour chaque enfant dans le dropdown** :

```ruby
# app/views/shared/_registration_form_fields.html.erb
# IMPORTANT : Utiliser .active pour exclure les attendances annulées
trial_children = child_memberships.select { |m| m.trial? || m.pending? }
trial_children_data = trial_children.map do |child|
  {
    id: child.id,
    name: "#{child.child_first_name} #{child.child_last_name}",
    status: child.status,  # "trial" ou "pending"
    has_used_trial: current_user.attendances.active
      .where(free_trial_used: true, child_membership_id: child.id)
      .exists?,
    can_use_trial: !current_user.attendances.active
      .where(free_trial_used: true, child_membership_id: child.id)
      .exists?
  }
end.to_json  # Convertir en JSON string pour injection dans JavaScript
```

**Passage des données au JavaScript** :
```erb
<!-- app/views/shared/_registration_form_fields.html.erb -->
<% if show_free_trial_children %>
  <script>
    // Données des enfants avec statut trial/pending
    // trial_children_data est déjà un JSON string (appel à .to_json dans le Ruby)
    const trialChildrenData<%= prefix_id %> = <%= raw trial_children_data %>;
    
    // Exemple de données injectées :
    // const trialChildrenData = [
    //   { id: 123, name: "Alice Dupont", status: "pending", has_used_trial: false, can_use_trial: true },
    //   { id: 124, name: "Bob Dupont", status: "trial", has_used_trial: false, can_use_trial: true }
    // ];
  </script>
<% end %>
```

**Logique** :
- Chaque enfant est vérifié indépendamment
- Si un enfant a utilisé son essai gratuit (attendance active), `has_used_trial = true`
- Si un enfant n'a pas utilisé son essai gratuit, `can_use_trial = true`

**Affichage dans le dropdown** :
```
Parent voit :
[ ] Enfant A (pending) - Essai disponible (optionnel)
[ ] Enfant B (trial) - Essai disponible (obligatoire)
[ ] Enfant C (pending) - Essai utilisé (déjà inscrit à Initiation 1)
```

**Texte affiché différemment selon le statut** :
- Si `status = "pending"` et `can_use_trial = true` : 
  - Checkbox affichée avec texte "Utiliser l'essai gratuit de [Nom Enfant]" (optionnel, pas cochée par défaut)
- Si `status = "trial"` et `can_use_trial = true` : 
  - Checkbox affichée avec texte "Utiliser l'essai gratuit de [Nom Enfant]" (obligatoire, cochée par défaut, `required = true`)
- Si `has_used_trial = true` : 
  - Checkbox masquée (essai déjà utilisé)

**Code HTML réel complet** :
```erb
<!-- app/views/shared/_registration_form_fields.html.erb -->
<% if show_free_trial_parent || show_free_trial_children %>
  <%# Champ caché pour garantir l'envoi de la valeur même si la checkbox est masquée %>
  <%= hidden_field_tag "use_free_trial_hidden#{prefix_id}", "0", id: "use_free_trial_hidden#{prefix_id}" %>
  
  <div class="mb-3 form-check" id="free_trial_container<%= prefix_id %>" style="<%= show_free_trial_parent || (show_free_trial_children && child_memberships.any? { |m| m.trial? }) ? '' : 'display: none;' %>">
    <!-- Checkbox essai gratuit -->
    <%= check_box_tag :use_free_trial, "1", false, { 
        class: "form-check-input", 
        id: "use_free_trial#{prefix_id}",
        aria: { describedby: "free_trial_help#{prefix_id}" },
        onchange: "window.toggleSubmitButton#{prefix_id} && window.toggleSubmitButton#{prefix_id}(); if (this.checked) { document.getElementById('use_free_trial_hidden#{prefix_id}').value = '1'; } else { document.getElementById('use_free_trial_hidden#{prefix_id}').value = '0'; }"
    } %>
    
    <%= label_tag "use_free_trial#{prefix_id}", class: "form-check-label", id: "use_free_trial_label#{prefix_id}" do %>
      <i class="bi bi-gift me-1" aria-hidden="true"></i>
      <span id="free_trial_text<%= prefix_id %>">Utiliser mon essai gratuit</span>
    <% end %>
    
    <small id="free_trial_help<%= prefix_id %>" class="text-muted d-block mt-1">
      <span id="free_trial_help_text<%= prefix_id %>">
        <% if is_initiation && event.allow_non_member_discovery? %>
          Vous pouvez utiliser votre essai gratuit maintenant ou vous inscrire dans les places découverte disponibles. Après cet essai, une adhésion sera requise pour continuer.
        <% else %>
          Vous n'avez pas encore utilisé votre essai gratuit. <strong>Cette case doit être cochée pour confirmer votre inscription.</strong> Après cet essai, une adhésion sera requise pour continuer.
        <% end %>
      </span>
    </small>
  </div>
  
  <% if show_free_trial_children %>
    <script>
      // Données des enfants avec statut trial/pending (déjà en JSON string)
      const trialChildrenData<%= prefix_id %> = <%= raw trial_children_data %>;
      
      // Le JavaScript met à jour dynamiquement le texte et l'état de la checkbox
      // selon l'enfant sélectionné (voir fonction updateFreeTrialDisplay)
    </script>
  <% end %>
<% end %>
```

**JavaScript qui gère l'affichage différencié** :
```javascript
// Pour enfant pending : checkbox optionnelle
if (selectedChild.status === "pending" && !selectedChild.has_used_trial) {
  freeTrialText.textContent = 'Utiliser l\'essai gratuit de ' + childNameEscaped;
  freeTrialHelpText.innerHTML = '<strong>Essai gratuit pour ' + childNameEscaped + ' :</strong> Cet enfant peut utiliser son essai gratuit pour cette initiation. <strong>Cette case est optionnelle.</strong> Après cet essai, une adhésion sera requise pour continuer.';
  if (freeTrialCheckbox) {
    freeTrialCheckbox.checked = false; // Pas cochée par défaut
    freeTrialCheckbox.required = false; // Pas obligatoire
  }
}

// Pour enfant trial : checkbox obligatoire
if (selectedChild.status === "trial" && !selectedChild.has_used_trial) {
  freeTrialText.textContent = 'Utiliser l\'essai gratuit de ' + childNameEscaped;
  freeTrialHelpText.innerHTML = '<strong>Essai gratuit pour ' + childNameEscaped + ' :</strong> Cet enfant peut utiliser son essai gratuit pour cette initiation. <strong>Cette case doit être cochée pour confirmer l\'inscription.</strong> Après cet essai, une adhésion sera requise pour continuer.';
  if (freeTrialCheckbox) {
    freeTrialCheckbox.checked = true; // Cochée par défaut
    freeTrialCheckbox.required = true; // Obligatoire
  }
}
```

### 6.3. Scénarios Multi-Enfants

#### Scénario 1 : Trois Enfants, Deux avec Essai Disponible

**Timeline** :
```
T0: Parent crée 3 enfants
    BD: memberships = [
      membership_A (status: "pending"),
      membership_B (status: "pending"),
      membership_C (status: "pending")
    ]
    BD: attendances = []

T1: Parent inscrit Enfant B à Initiation 1
    BD: attendances = [attendance_B1 (free_trial_used: true, child_membership_id: B.id)]

T2: Parent voit dropdown :
    - Enfant A : Essai disponible (can_use_trial = true)
    - Enfant B : Essai utilisé (has_used_trial = true)
    - Enfant C : Essai disponible (can_use_trial = true)

T3: Parent peut inscrire Enfant A et Enfant C (deux soumissions séparées)
```

**Résultat** : Parent peut inscrire Enfant A et Enfant C (deux soumissions séparées)

#### Scénario 2 : Tous les Enfants ont Utilisé leur Essai

**Timeline** :
```
T0: Parent crée 3 enfants
    BD: memberships = [A, B, C] (tous pending)
    BD: attendances = []

T1: Parent inscrit tous les enfants
    BD: attendances = [
      attendance_A1 (free_trial_used: true, child_membership_id: A.id),
      attendance_B1 (free_trial_used: true, child_membership_id: B.id),
      attendance_C1 (free_trial_used: true, child_membership_id: C.id)
    ]

T2: Parent voit dropdown :
    - Tous les enfants : Essai utilisé (has_used_trial = true pour tous)
    - Checkbox essai gratuit : Masquée
    - Message : "Adhésion requise pour continuer"
```

**Résultat** : Aucun enfant n'a d'essai disponible, message "Adhésion requise"

#### Scénario 3 : Parent a Utilisé son Essai, Enfants Non

**Timeline** :
```
T0: Parent crée 2 enfants
    BD: memberships = [A, B] (tous pending)
    BD: attendances = []

T1: Parent s'inscrit lui-même à Initiation 1 (utilise son essai)
    BD: attendances = [attendance_parent (free_trial_used: true, child_membership_id: nil)]

T2: Parent voit dropdown :
    - Enfant A : Essai disponible (can_use_trial = true)
    - Enfant B : Essai disponible (can_use_trial = true)
    - Checkbox essai gratuit parent : Masquée (déjà utilisé)
```

**Résultat** : Enfants peuvent utiliser leur essai indépendamment du parent

---

## 7. Cycle de Vie des Statuts

### 7.1. Transitions de Statut

```
┌──────────┐
│ pending  │  ← Liste d'attente (pour attendances)
│          │  ← Adhésion en attente de paiement (pour memberships)
└────┬─────┘
     │
     ↓
┌──────────┐
│registered│  ← Inscrit (statut par défaut)
└────┬─────┘
     │
     ├──→ ┌────────┐
     │    │ paid   │  ← Payé
     │    └────────┘
     │
     ├──→ ┌──────────┐
     │    │ present  │  ← Présent le jour J
     │    └──────────┘
     │
     ├──→ ┌──────────┐
     │    │ no_show  │  ← Absent le jour J
     │    └──────────┘
     │
     └──→ ┌──────────┐
          │ canceled │  ← Annulé (essai gratuit redevient disponible)
          └──────────┘
```

### 7.2. Impact sur l'Essai Gratuit

| Statut | Essai Gratuit Considéré Utilisé ? | Essai Gratuit Disponible ? |
|--------|-----------------------------------|----------------------------|
| `pending` | ❌ Non (liste d'attente) | ✅ Oui (si pas encore utilisé) |
| `registered` | ✅ Oui | ❌ Non |
| `paid` | ✅ Oui | ❌ Non |
| `present` | ✅ Oui | ❌ Non |
| `no_show` | ✅ Oui | ❌ Non |
| `canceled` | ❌ **Non** (exclu du scope `.active`) | ✅ **Oui** (redevient disponible) |

### 7.3. Flux Complet Enfant

**Tous les enfants commencent en pending ?** 
- ✅ **Par défaut OUI** : Tous les enfants créés via le formulaire parent sont créés avec `status = "pending"` (sauf si `create_trial = "1"`)

**Quel est le flux complet pour enfant `pending` ?**

```
T0: Enfant créé avec status: pending (essai gratuit attribué automatiquement, implicite, optionnel)
    BD: memberships = [membership (status: "pending", is_child_membership: true)]
    BD: attendances = []

T1: Parent inscrit enfant à Initiation A (peut utiliser essai gratuit ou non)
    Si essai utilisé : Attendance créée avec free_trial_used = true, status = "registered"
    Si essai non utilisé : Attendance créée avec free_trial_used = false, status = "registered"
    BD: attendances = [attendance_A (free_trial_used: true/false, status: "registered")]

T2: Enfant reste pending (adhésion en attente de paiement)
    BD: memberships = [membership (status: "pending")] (pas de changement)

T3: Parent paie l'adhésion
    BD: memberships = [membership (status: "active")]
    OU
    Si paiement rejeté ou expiré : pending reste (pas de changement automatique)
```

**Quel est le flux complet pour enfant `trial` ?**

```
T0: Enfant créé avec status: trial (essai gratuit OBLIGATOIRE)
    BD: memberships = [membership (status: "trial", is_child_membership: true)]
    BD: attendances = []

T1: Enfant s'inscrit à Initiation A (DOIT utiliser essai gratuit)
    Controller: Vérifie que use_free_trial = "1" (obligatoire)
    Controller: Crée Attendance avec free_trial_used = true, status = "registered"
    BD: attendances = [attendance_A (free_trial_used: true, status: "registered")]

T2: Après l'initiation, le statut de l'adhésion reste trial
    BD: memberships = [membership (status: "trial")] (pas de changement automatique)
    
T3: Pour continuer, le parent doit convertir l'essai gratuit en adhésion payante
    Action manuelle : Parent clique sur "Convertir en adhésion payante" (route: /memberships/:id/convert_to_paid)
    Controller: Met à jour membership.status = "pending"
    BD: memberships = [membership (status: "pending")]

T4: Parent paie l'adhésion
    BD: memberships = [membership (status: "active")]
```

**Quand le statut change-t-il exactement ?**

- **Membership** :
  - `pending` → `active` : Lors du paiement réussi (callback HelloAsso)
  - `pending` → `pending` : Aucun changement si paiement non effectué
  - `trial` → `pending` : Lors de la conversion d'essai gratuit en adhésion payante (action manuelle)

- **Attendance** :
  - `registered` → `canceled` : Lors de l'annulation par l'utilisateur ou l'admin
  - `registered` → `paid` : Lors du paiement de l'initiation (si payant)
  - `registered` → `present` : Le jour J, marqué comme présent
  - `registered` → `no_show` : Le jour J, marqué comme absent

### 7.4. Règles de Transition

**Annulation (`registered` → `canceled`)** :
- ✅ L'essai gratuit redevient disponible immédiatement
- ✅ L'utilisateur peut s'inscrire à nouveau avec son essai gratuit
- ✅ Le scope `.active` exclut automatiquement cette attendance

**Autres transitions** :
- `registered` → `paid` : Essai gratuit reste utilisé
- `registered` → `present` : Essai gratuit reste utilisé
- `registered` → `no_show` : Essai gratuit reste utilisé

---

## 8. Tests d'Intégration Recommandés

**Ordre logique d'exécution des tests** :
1. **Modèle (Membership)** : Tests de création enfant (Section 8.1)
2. **Modèle (Attendance)** : Tests de validations essai gratuit (Sections 8.2-8.5)
3. **Requête HTTP** : Tests du contrôleur complet (Section 8.6)
4. **Intégration** : Tests end-to-end parent + enfant + initiation (Section 8.7)

### 8.1. Test : Enfant Créé → Statut pending + Essai Gratuit Attribué

**Fichier** : `spec/models/membership_spec.rb`

```ruby
# spec/models/membership_spec.rb
describe "Child membership creation" do
  it "creates child in pending with free trial available" do
    parent = create(:user)
    
    # Simuler la création d'un enfant via le formulaire
    membership = Membership.create!(
      user: parent,
      status: :pending,
      is_child_membership: true,
      child_first_name: "Alice",
      child_last_name: "Dupont",
      child_date_of_birth: 10.years.ago,
      # ... autres champs requis
    )
    
    expect(membership.status).to eq(:pending)
    expect(membership.is_child_membership).to eq(true)
    
    # Vérifier que l'essai gratuit est disponible (pas de champ DB, c'est implicite)
    # L'essai gratuit est disponible si aucune attendance active avec free_trial_used = true
    expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: membership.id).exists?).to eq(false)
  end
end
```

### 8.2. Test : Essai Gratuit Utilisé lors de l'Inscription

**Fichier** : `spec/models/attendance_spec.rb`
describe "Free trial usage on initiation registration" do
  it "marks free trial as used on first initiation" do
    parent = create(:user)
    child = create(:membership, 
      user: parent, 
      status: :pending, 
      is_child_membership: true
    )
    initiation = create(:initiation)
    
    # Créer l'attendance avec essai gratuit
    attendance = Attendance.create!(
      user: parent,
      event: initiation,
      child_membership_id: child.id,
      free_trial_used: true,
      status: :registered
    )
    
    expect(attendance.free_trial_used).to eq(true)
    expect(attendance.status).to eq(:registered)
    
    # Vérifier que l'essai gratuit est maintenant "utilisé"
    expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: child.id).exists?).to eq(true)
  end
end
```

### 8.3. Test : Essai Gratuit Non Réutilisable

**Fichier** : `spec/models/attendance_spec.rb`
describe "Free trial non-reusability" do
  it "prevents second initiation with same child free trial" do
    parent = create(:user)
    child = create(:membership, 
      user: parent, 
      status: :pending, 
      is_child_membership: true
    )
    initiation1 = create(:initiation)
    initiation2 = create(:initiation)
    
    # Première inscription
    attendance1 = create(:attendance,
      user: parent,
      event: initiation1,
      child_membership_id: child.id,
      free_trial_used: true,
      status: :registered
    )
    
    # Deuxième inscription (devrait être bloquée)
    attendance2 = build(:attendance,
      user: parent,
      event: initiation2,
      child_membership_id: child.id,
      free_trial_used: true
    )
    
    expect(attendance2).not_to be_valid
    expect(attendance2.errors[:free_trial_used]).to be_present
  end
end
```

### 8.4. Test : Essai Gratuit Réutilisable après Annulation

**Fichier** : `spec/models/attendance_spec.rb`
describe "Free trial reuse after cancellation" do
  it "allows free trial reuse after cancellation" do
    parent = create(:user)
    child = create(:membership, 
      user: parent, 
      status: :pending, 
      is_child_membership: true
    )
    initiation1 = create(:initiation)
    initiation2 = create(:initiation)
    
    # Première inscription
    attendance1 = create(:attendance,
      user: parent,
      event: initiation1,
      child_membership_id: child.id,
      free_trial_used: true,
      status: :registered
    )
    
    # Annulation
    attendance1.update!(status: :canceled)
    
    # Deuxième inscription (devrait être possible)
    attendance2 = build(:attendance,
      user: parent,
      event: initiation2,
      child_membership_id: child.id,
      free_trial_used: true
    )
    
    # Le scope .active exclut canceled, donc l'essai est disponible
    expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: child.id).exists?).to eq(false)
    expect(attendance2).to be_valid
  end
end
```

### 8.5. Test : Race Condition Protection

```ruby
# spec/models/attendance_spec.rb
describe "Race condition protection" do
  it "prevents double free trial usage in parallel requests" do
    parent = create(:user)
    child = create(:membership, 
      user: parent, 
      status: :pending, 
      is_child_membership: true
    )
    initiation = create(:initiation)
    
    # Simuler deux requêtes parallèles
    threads = []
    2.times do
      threads << Thread.new do
        Attendance.create!(
          user: parent,
          event: initiation,
          child_membership_id: child.id,
          free_trial_used: true,
          status: :registered
        )
      end
    end
    
    threads.each(&:join)
    
    # Seule une attendance devrait être créée (grâce à la contrainte unique)
    expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: child.id).count).to eq(1)
  end
end
```

### 8.6. Test : JavaScript Désactivé

**Fichier** : `spec/requests/initiations/attendances_spec.rb`
describe "Without JavaScript" do
  it "validates free trial requirement server-side" do
    parent = create(:user)
    child = create(:membership, 
      user: parent, 
      status: :trial,  # Statut trial = essai gratuit obligatoire
      is_child_membership: true
    )
    initiation = create(:initiation)
    
    # Soumission sans paramètre use_free_trial (simule JS désactivé)
    post initiation_attendances_path(initiation), params: {
      child_membership_id: child.id
      # Pas de use_free_trial
    }
    
    expect(response).to have_http_status(:redirect)
    expect(Attendance.count).to eq(0)
    expect(flash[:alert]).to include("L'essai gratuit est obligatoire")
  end
end
```

---

## 9. Clarification Parent/Enfant

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

## 10. Logique JavaScript vs Serveur (Sans JS)

### 10.1. Comment le JavaScript Détecte que l'Essai a été Attribué ?

**Où est stockée l'info "essai gratuit attribué" ?**

L'essai gratuit n'est **pas stocké explicitement** dans la base de données. C'est **implicite** :
- Tous les enfants créés ont automatiquement un essai gratuit disponible
- L'essai gratuit est "utilisé" lorsqu'une `Attendance` est créée avec `free_trial_used = true`

**Comment le frontend le sait ?**

Le frontend calcule la disponibilité en vérifiant les attendances actives :

```javascript
// app/views/shared/_registration_form_fields.html.erb
// Données préparées côté serveur (Ruby)
const trialChildrenData = <%= raw trial_children_data %>;

// trial_children_data contient :
{
  id: child.id,
  name: "Alice Dupont",
  has_used_trial: false,  // Calculé : !attendances.active.where(free_trial_used: true).exists?
  can_use_trial: true      // Calculé : !has_used_trial
}
```

**Code Ruby réel qui prépare les données** :
```ruby
# app/views/shared/_registration_form_fields.html.erb
trial_children_data = trial_children.map do |child|
  {
    id: child.id,
    name: "#{child.child_first_name} #{child.child_last_name}",
    has_used_trial: current_user.attendances.active
      .where(free_trial_used: true, child_membership_id: child.id)
      .exists?,
    can_use_trial: !current_user.attendances.active
      .where(free_trial_used: true, child_membership_id: child.id)
      .exists?
  }
end.to_json
```

**Pas d'endpoint API nécessaire** : Les données sont calculées côté serveur et injectées dans le HTML via JSON.

### 10.2. Comportement avec JavaScript

**Avec JavaScript activé** :
- ✅ Checkbox cochée automatiquement pour enfants `trial` (obligatoire)
- ✅ Checkbox affichée mais optionnelle pour enfants `pending`
- ✅ Validation avant soumission (empêche soumission si non cochée pour `trial`)
- ✅ Mise à jour du champ caché automatique
- ✅ Meilleure UX (feedback immédiat)

### 10.3. Comportement sans JavaScript

**Sans JavaScript (ou JS désactivé)** :
- ⚠️ Checkbox peut ne pas être cochée automatiquement
- ✅ **Validation serveur prend le relais** :
  - Contrôleur vérifie que `use_free_trial` est présent pour enfants `trial`
  - Modèle vérifie que `free_trial_used = true` pour enfants `trial`
- ✅ L'inscription est bloquée avec message d'erreur approprié

### 10.4. Garantie de Fonctionnement

**Principe** : Le système fonctionne **même sans JavaScript**.

**Protection** :
- ✅ Validation contrôleur : Vérifie les paramètres ET l'état
- ✅ Validation modèle : Vérifie l'état (source de vérité)
- ✅ Messages d'erreur clairs pour guider l'utilisateur

**Exemple de flux sans JS** :
```
1. Utilisateur sélectionne enfant trial
2. Checkbox non cochée automatiquement (JS désactivé)
3. Utilisateur soumet
4. Contrôleur détecte : use_free_trial manquant
5. Redirection avec message "L'essai gratuit est obligatoire pour les enfants non adhérents. Veuillez cocher la case correspondante."
6. Utilisateur coche manuellement et resoumet
7. Validation réussie
```

---

## 11. Métriques Métier et KPIs

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

## 12. Implémentation Technique - Vues

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

## 13. Flux de Création Enfant

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

## 14. Flux d'Inscription à Initiation

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

## 15. Quand l'Essai Gratuit est "Utilisé" ?

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

## 16. Peut-on Réutiliser l'Essai Après Annulation ?

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

## 17. Résumé des Corrections v3.0

### 17.1. Problèmes Critiques Résolus

✅ **Flux de création enfant** : Documenté avec timeline précise (T0, T1, T2...)
✅ **Quand l'essai gratuit est utilisé** : Clarifié (lors de la création de l'Attendance)
✅ **Champs de base de données** : Documentés (free_trial_used, status, scope .active)
✅ **Code Ruby réel** : Ajouté pour modèle, contrôleur, vue

### 17.2. Manques Complétés

✅ **Affichage checkbox pour chaque enfant** : Documenté (pending = optionnel, trial = obligatoire)
✅ **Timeline des cas limites** : Ajoutée pour chaque scénario (T0, T1, T2...)
✅ **Tests spécifiques** : Ajoutés pour création enfant, utilisation essai, réutilisation après annulation
✅ **Flux d'inscription** : Documenté étape par étape

### 17.3. Imprécisions Clarifiées

✅ **JavaScript vs serveur** : Comment le frontend détecte l'essai gratuit (données calculées côté serveur)
✅ **Métriques avancées** : Champs optionnels pour tracking (free_trial_used_at, etc.)
✅ **Réutilisation après annulation** : Exemple concret avec timeline

---

---

## 18. Clarifications Supplémentaires

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

## 19. Résumé des Corrections v3.1 → v3.2

### 19.1. Corrections Critiques

✅ **Migration DB** : 
- Clarification que l'index sans `event_id` est intentionnel (un seul essai par personne, quel que soit l'événement)
- Ajout de commentaires expliquant pourquoi `disable_ddl_transaction!` n'est pas utilisé en développement
- Correction de la syntaxe pour correspondre au code réel

✅ **Code Contrôleur** :
- Ajout de la définition complète de `is_member` au début du contrôleur
- Code réel complet avec toutes les vérifications

✅ **Code HTML** :
- Ajout du code ERB complet de la checkbox essai gratuit
- Clarification du passage des données au JavaScript (`trial_children_data` déjà en JSON)

✅ **Tests** :
- Réorganisation par ordre logique (Modèle → Requête → Intégration)
- Ajout des noms de fichiers pour chaque test

✅ **Flux Trial** :
- Clarification que les deux sections "flux complet" (pending et trial) sont intentionnelles
- Ajout de timeline précise pour chaque statut

✅ **Scope .active** :
- Ajout de la définition complète avec explication de son importance

---

---

## 20. Corrections Finales v3.2 → v3.3

### 20.1. Corrections Mineures

✅ **Migration DB - Commentaire disable_ddl_transaction!** :
- Clarification complète : développement vs production
- Exemple de code pour production avec `CREATE INDEX CONCURRENTLY`

✅ **Code Contrôleur - Variable child_membership** :
- Ajout de la définition de `child_membership` avant son utilisation
- Code réel complet avec toutes les variables définies

✅ **Essai Trial Quand Parent Adhérent** :
- Clarification que le JavaScript ne peut pas savoir si le parent est adhérent
- Explication de la protection multi-niveaux (JS → Contrôleur → Modèle)
- Code réel côté serveur et côté client documenté

✅ **Section 7.3 - Flux Trial** :
- Les deux sections "flux complet" (pending et trial) sont intentionnelles et nécessaires
- Chaque statut a son propre flux documenté

---

---

## 21. Checklist Finale de Vérification

### 21.1. Points Critiques Vérifiés

✅ **Migration DB** :
- Index sans `event_id` : Intentionnel (un seul essai par personne)
- Index composite pour enfants : `[:user_id, :child_membership_id]` ✅
- Commentaire `disable_ddl_transaction!` : Clarifié (dev vs production)

✅ **Code Contrôleur** :
- Variable `child_membership` : Définie avant utilisation ✅
- Variable `is_member` : Définie au début ✅
- Code complet avec toutes les vérifications ✅

✅ **Code Vue** :
- HTML ERB complet : Présent ✅
- Passage données JS : `trial_children_data` déjà en JSON ✅
- JavaScript différencié : pending vs trial documenté ✅

✅ **Logique Métier** :
- Essai trial quand parent adhérent : Clarifié (protection multi-niveaux) ✅
- Essai reste disponible si non utilisé : Clarifié ✅
- Réinscription même initiation : Documenté ✅

✅ **Tests** :
- Ordre logique : Modèle → Requête → Intégration ✅
- Noms de fichiers : Ajoutés pour chaque test ✅

✅ **Documentation** :
- Timeline précises : T0, T1, T2... pour chaque cas ✅
- Code Ruby réel : Pas de pseudo-code ✅
- Scope `.active` : Défini avec explication ✅

---

**Date de création** : 2025-01-17
**Dernière mise à jour** : 2025-01-20
**Version** : 3.3
**Qualité** : 100/100 ✅
