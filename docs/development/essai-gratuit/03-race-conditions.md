# 3. Protection contre les Race Conditions

[← Retour à l'index](index.md)

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

---

**Navigation** :
- [← Section précédente](02-statut-pending.md)
- [← Retour à l'index](index.md)
- [→ Section suivante](04-validations-serveur.md)
