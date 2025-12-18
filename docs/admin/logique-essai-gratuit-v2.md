# Logique d'Essai Gratuit - Documentation Complète v2.0

## Vue d'ensemble

Le système d'essai gratuit permet aux utilisateurs non adhérents (adultes ou enfants) de participer à **une seule initiation** gratuitement. Après cette initiation, une adhésion est requise pour continuer.

**IMPORTANT** : Si un utilisateur (adulte ou enfant) se désinscrit d'une initiation où il avait utilisé son essai gratuit, l'essai gratuit redevient disponible et peut être réutilisé.

---

## 1. Règles Générales

### 1.1. Qui peut utiliser l'essai gratuit ?

- **Adultes non adhérents** : Un adulte sans adhésion active peut utiliser son essai gratuit
- **Enfants non adhérents (statut `trial`)** : Un enfant avec une adhésion au statut `trial` (non adhérent) **DOIT** utiliser son essai gratuit pour s'inscrire
- **Enfants avec adhésion `pending`** : Un enfant avec une adhésion en attente de paiement peut s'inscrire **SANS** utiliser l'essai gratuit (l'adhésion `pending` est acceptée comme valide)

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

---

## 2. Clarification Statut `pending` (Enfant)

### 2.1. Règle Métier Claire

**Un enfant avec statut `pending` (adhésion en attente de paiement) :**
- ✅ **Peut s'inscrire SANS utiliser l'essai gratuit** (l'adhésion `pending` est considérée comme valide pour l'inscription)
- ✅ **Peut OPTIONNELLEMENT utiliser son essai gratuit** si disponible (mais ce n'est pas obligatoire)
- ❌ **N'est PAS obligé d'utiliser l'essai gratuit** (contrairement aux enfants `trial`)

**Différence avec statut `trial` :**
- `trial` = Non adhérent, essai gratuit **OBLIGATOIRE**
- `pending` = Adhérent en attente de paiement, essai gratuit **OPTIONNEL**

### 2.2. Logique d'Affichage

Pour un enfant avec statut `pending` :
- La checkbox essai gratuit est **affichée** si l'enfant n'a pas encore utilisé son essai gratuit
- La checkbox est **optionnelle** (pas cochée par défaut, pas obligatoire)
- L'enfant peut s'inscrire même si la checkbox n'est pas cochée

---

## 3. Protection contre les Race Conditions

### 3.1. Problème Identifié

Deux requêtes parallèles pourraient créer deux attendances avec `free_trial_used = true` pour le même utilisateur/enfant.

### 3.2. Solutions Implémentées

#### Solution 1 : Contrainte Unique au Niveau Base de Données (Recommandé)

**Migration à créer :**
```ruby
# db/migrate/YYYYMMDDHHMMSS_add_unique_constraint_free_trial.rb
class AddUniqueConstraintFreeTrial < ActiveRecord::Migration[7.0]
  def change
    # Contrainte unique : un seul essai gratuit actif par utilisateur/enfant
    add_index :attendances, 
      [:user_id, :child_membership_id], 
      unique: true, 
      where: "free_trial_used = true AND status != 'canceled'",
      name: "index_attendances_unique_free_trial_active"
  end
end
```

**Note** : Cette contrainte PostgreSQL utilise une condition `WHERE` pour ne s'appliquer qu'aux attendances actives avec essai gratuit.

#### Solution 2 : Transaction avec Lock Pessimiste (Actuel)

Dans le contrôleur, utilisation d'une transaction avec lock :

```ruby
Attendance.transaction do
  # Vérifier et créer avec lock
  if current_user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).lock.exists?
    # Erreur
  else
    attendance.save!
  end
end
```

#### Solution 3 : Validation au Niveau Modèle (Déjà Implémenté)

La validation `can_use_free_trial` vérifie l'unicité avant la création.

### 3.3. Recommandation

**Implémenter la Solution 1 (contrainte unique)** pour une protection maximale au niveau base de données, en complément des validations applicatives.

---

## 4. Validations Serveur Renforcées

### 4.1. Problème Identifié

Trop de confiance dans les paramètres clients (checkbox, champs cachés).

### 4.2. Validations Multi-Niveaux

#### Niveau 1 : Validation Modèle (Source de Vérité)

```ruby
# app/models/attendance.rb
validate :can_use_free_trial, on: :create
validate :can_register_to_initiation, on: :create

def can_register_to_initiation
  # Pour les enfants trial : free_trial_used DOIT être true
  if child_membership&.trial? && !user.memberships.active_now.exists?
    unless free_trial_used
      errors.add(:free_trial_used, "L'essai gratuit est obligatoire")
    end
    # Vérifier unicité (attendance active)
    if user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).where.not(id: id).exists?
      errors.add(:free_trial_used, "Essai gratuit déjà utilisé")
    end
  end
end
```

**Caractéristiques** :
- ✅ Ne dépend PAS des paramètres HTTP
- ✅ Vérifie directement l'état de la base de données
- ✅ Utilise le scope `.active` pour exclure les annulations

#### Niveau 2 : Validation Contrôleur (Vérification Préalable)

```ruby
# app/controllers/initiations/attendances_controller.rb
# Vérification AVANT la création
if child_membership&.trial? && !is_member
  if current_user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).exists?
    redirect_to initiation_path(@initiation), alert: "Essai gratuit déjà utilisé"
    return
  end
  # Vérifier que free_trial_used sera true
  unless params[:use_free_trial] == "1" || params["use_free_trial_hidden#{prefix_id}"] == "1"
    redirect_to initiation_path(@initiation), alert: "Essai gratuit obligatoire"
    return
  end
end
```

**Caractéristiques** :
- ✅ Vérification préalable avant création
- ✅ Redirection immédiate si problème
- ✅ Ne fait PAS confiance aux paramètres pour la logique métier

#### Niveau 3 : Validation JavaScript (UX uniquement)

```javascript
// Validation JavaScript = UX uniquement, PAS de sécurité
if (selectedChild && !selectedChild.has_used_trial) {
  if (!freeTrialCheckbox.checked) {
    e.preventDefault();
    alert('Essai gratuit obligatoire');
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

**Protection** :
- ✅ Validation modèle : `can_use_free_trial` détecte `attendance_1` active
- ✅ Validation contrôleur : Vérification préalable détecte `attendance_1` active
- ✅ Contrainte unique (si implémentée) : Empêche la création de `attendance_2`

**Résultat** : La deuxième inscription est bloquée avec message "Essai gratuit déjà utilisé"

### 5.2. Essai Réutilisé Avant Première Annulation

**Scénario** :
1. Utilisateur A s'inscrit avec essai gratuit → `attendance_1` créée avec `free_trial_used = true`, `status = "registered"`
2. Utilisateur A essaie de s'inscrire à une autre initiation (sans annuler `attendance_1`)

**Protection** : Identique au cas 5.1

**Résultat** : La deuxième inscription est bloquée

### 5.3. Annulation puis Double Inscription

**Scénario** :
1. Utilisateur A s'inscrit avec essai gratuit → `attendance_1` créée avec `free_trial_used = true`
2. Utilisateur A annule → `attendance_1.status = "canceled"`
3. Utilisateur A s'inscrit à deux initiations en parallèle

**Protection** :
- ✅ Scope `.active` exclut `attendance_1` (canceled)
- ⚠️ **Race condition possible** : Deux requêtes parallèles pourraient créer deux attendances

**Solution** : Contrainte unique au niveau base de données (Section 3.2)

### 5.4. Tentative de Contournement (Modification Paramètres)

**Scénario** : Utilisateur modifie les paramètres HTTP pour ne pas envoyer `use_free_trial`

**Protection** :
- ✅ Validation modèle : Pour enfants `trial`, `free_trial_used` DOIT être `true` (vérifie l'état, pas les paramètres)
- ✅ Validation contrôleur : Vérifie les paramètres ET l'état de la base de données

**Résultat** : L'inscription est bloquée avec message "Essai gratuit obligatoire"

### 5.5. JavaScript Désactivé

**Scénario** : Utilisateur désactive JavaScript et essaie de soumettre sans cocher la checkbox

**Protection** :
- ✅ Validation contrôleur : Vérifie que `use_free_trial` est présent pour enfants `trial`
- ✅ Validation modèle : Vérifie que `free_trial_used = true` pour enfants `trial`

**Résultat** : L'inscription est bloquée avec message d'erreur approprié

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

Pour chaque enfant dans le dropdown :

```ruby
# IMPORTANT : Utiliser .active pour exclure les attendances annulées
# Si une attendance est annulée, l'essai gratuit redevient disponible
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
end
```

**IMPORTANT** : Toutes les vérifications d'essai gratuit dans les vues doivent utiliser `.active.where()` et non `.where()` pour exclure les attendances annulées.

**Logique** :
- Chaque enfant est vérifié indépendamment
- Si un enfant a utilisé son essai gratuit, il n'apparaît pas dans le dropdown (ou avec message)
- Si un enfant n'a pas utilisé son essai gratuit, la checkbox s'affiche pour lui

### 6.3. Scénarios Multi-Enfants

#### Scénario 1 : Trois Enfants, Deux avec Essai Disponible

- Enfant A : Essai utilisé (attendance active) → Non affiché dans dropdown
- Enfant B : Essai disponible → Affiché, checkbox obligatoire
- Enfant C : Essai disponible → Affiché, checkbox obligatoire

**Résultat** : Parent peut inscrire Enfant B et Enfant C (deux soumissions séparées)

#### Scénario 2 : Tous les Enfants ont Utilisé leur Essai

- Enfant A : Essai utilisé
- Enfant B : Essai utilisé
- Enfant C : Essai utilisé

**Résultat** : Aucun enfant n'apparaît dans le dropdown, message "Adhésion requise"

#### Scénario 3 : Parent a Utilisé son Essai, Enfants Non

- Parent : Essai utilisé
- Enfant A : Essai disponible
- Enfant B : Essai disponible

**Résultat** : Enfants peuvent utiliser leur essai indépendamment du parent

---

## 7. Cycle de Vie des Statuts

### 7.1. Transitions de Statut

```
┌──────────┐
│ pending  │  ← Liste d'attente
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

### 7.3. Règles de Transition

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

### 8.1. Tests de Race Condition

```ruby
# spec/models/attendance_spec.rb
describe "Race condition protection" do
  it "prevents double free trial usage in parallel requests" do
    user = create(:user)
    child_membership = create(:membership, user: user, is_child_membership: true, status: :trial)
    initiation = create(:initiation)
    
    # Simuler deux requêtes parallèles
    threads = []
    2.times do
      threads << Thread.new do
        Attendance.create!(
          user: user,
          event: initiation,
          child_membership_id: child_membership.id,
          free_trial_used: true,
          status: :registered
        )
      end
    end
    
    threads.each(&:join)
    
    # Seule une attendance devrait être créée
    expect(user.attendances.active.where(free_trial_used: true).count).to eq(1)
  end
end
```

### 8.2. Tests de Validation Serveur

```ruby
# spec/models/attendance_spec.rb
describe "Server-side validation" do
  it "requires free_trial_used for trial children regardless of params" do
    user = create(:user)
    child_membership = create(:membership, user: user, is_child_membership: true, status: :trial)
    initiation = create(:initiation)
    
    attendance = Attendance.new(
      user: user,
      event: initiation,
      child_membership_id: child_membership.id,
      free_trial_used: false  # Pas de paramètre use_free_trial
    )
    
    expect(attendance).not_to be_valid
    expect(attendance.errors[:free_trial_used]).to include("L'essai gratuit est obligatoire")
  end
end
```

### 8.3. Tests de Cas Limites

```ruby
# spec/models/attendance_spec.rb
describe "Edge cases" do
  it "allows free trial reuse after cancellation" do
    user = create(:user)
    child_membership = create(:membership, user: user, is_child_membership: true, status: :trial)
    initiation1 = create(:initiation)
    initiation2 = create(:initiation)
    
    # Première inscription
    attendance1 = create(:attendance, 
      user: user, 
      event: initiation1, 
      child_membership_id: child_membership.id,
      free_trial_used: true,
      status: :registered
    )
    
    # Annulation
    attendance1.update!(status: :canceled)
    
    # Deuxième inscription (devrait être possible)
    attendance2 = build(:attendance,
      user: user,
      event: initiation2,
      child_membership_id: child_membership.id,
      free_trial_used: true
    )
    
    expect(attendance2).to be_valid
  end
  
  it "prevents double registration before cancellation" do
    user = create(:user)
    child_membership = create(:membership, user: user, is_child_membership: true, status: :trial)
    initiation1 = create(:initiation)
    initiation2 = create(:initiation)
    
    # Première inscription
    create(:attendance,
      user: user,
      event: initiation1,
      child_membership_id: child_membership.id,
      free_trial_used: true,
      status: :registered
    )
    
    # Deuxième inscription (devrait être bloquée)
    attendance2 = build(:attendance,
      user: user,
      event: initiation2,
      child_membership_id: child_membership.id,
      free_trial_used: true
    )
    
    expect(attendance2).not_to be_valid
    expect(attendance2.errors[:free_trial_used]).to be_present
  end
end
```

### 8.4. Tests JavaScript Désactivé

```ruby
# spec/requests/initiations/attendances_spec.rb
describe "Without JavaScript" do
  it "validates free trial requirement server-side" do
    user = create(:user)
    child_membership = create(:membership, user: user, is_child_membership: true, status: :trial)
    initiation = create(:initiation)
    
    # Soumission sans paramètre use_free_trial (simule JS désactivé)
    post initiation_attendances_path(initiation), params: {
      attendance: {
        child_membership_id: child_membership.id
        # Pas de use_free_trial
      }
    }
    
    expect(response).to have_http_status(:unprocessable_entity)
    expect(Attendance.count).to eq(0)
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

- Parent s'inscrit avec essai gratuit → `attendance_parent` avec `free_trial_used = true`, `child_membership_id = nil`
- Enfant peut toujours utiliser son essai gratuit → `attendance_enfant` avec `free_trial_used = true`, `child_membership_id = enfant.id`

**Résultat** : Deux attendances distinctes, deux essais gratuits utilisés indépendamment

#### Exemple 2 : Enfant Utilise son Essai, Parent Non

- Enfant s'inscrit avec essai gratuit → `attendance_enfant` avec `free_trial_used = true`
- Parent peut toujours utiliser son essai gratuit → `attendance_parent` avec `free_trial_used = true`

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

### 10.1. Comportement avec JavaScript

**Avec JavaScript activé** :
- ✅ Checkbox cochée automatiquement pour enfants `trial`
- ✅ Validation avant soumission (empêche soumission si non cochée)
- ✅ Mise à jour du champ caché automatique
- ✅ Meilleure UX (feedback immédiat)

### 10.2. Comportement sans JavaScript

**Sans JavaScript (ou JS désactivé)** :
- ⚠️ Checkbox peut ne pas être cochée automatiquement
- ✅ **Validation serveur prend le relais** :
  - Contrôleur vérifie que `use_free_trial` est présent pour enfants `trial`
  - Modèle vérifie que `free_trial_used = true` pour enfants `trial`
- ✅ L'inscription est bloquée avec message d'erreur approprié

### 10.3. Garantie de Fonctionnement

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
5. Redirection avec message "Essai gratuit obligatoire"
6. Utilisateur coche manuellement et resoumet
7. Validation réussie
```

---

## 11. Métriques Métier et KPIs

### 11.1. Métriques à Suivre

#### Taux d'Utilisation Essai Gratuit

```ruby
# Nombre d'essais gratuits utilisés / Nombre d'utilisateurs non adhérents
free_trials_used = Attendance.active.where(free_trial_used: true).count
non_members = User.joins(:memberships)
  .where.not(memberships: { status: :active })
  .distinct
  .count
usage_rate = (free_trials_used.to_f / non_members) * 100
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
| Taux d'utilisation essai gratuit | % non-adhérents utilisant l'essai | > 60% | Mensuel |
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

---

## 12. Résumé des Corrections v2.0

### 12.1. Problèmes Critiques Résolus

✅ **Statut pending clarifié** : Règle métier claire (optionnel pour `pending`, obligatoire pour `trial`)
✅ **Race condition** : Contrainte unique recommandée + transaction avec lock
✅ **Validation serveur** : Multi-niveaux (modèle = source de vérité, contrôleur = vérification, JS = UX)

### 12.2. Manques Complétés

✅ **Cas limites documentés** : Double inscription, réutilisation avant annulation, etc.
✅ **Enfants multiples** : Fonctionnement du formulaire expliqué
✅ **Cycle de vie statuts** : Diagramme de transitions + impact sur essai gratuit
✅ **Tests d'intégration** : Exemples de tests recommandés
✅ **Clarification parent/enfant** : Matrice de possibilités + exemples

### 12.3. Imprécisions Clarifiées

✅ **JavaScript vs serveur** : Comportement avec/sans JS documenté
✅ **Métriques métier** : KPIs et formules de calcul ajoutés

---

---

## 13. Implémentation Technique - Vues

### 13.1. Utilisation du Scope `.active`

**RÈGLE CRITIQUE** : Toutes les vérifications d'essai gratuit dans les vues (`_registration_form_fields.html.erb`) doivent utiliser le scope `.active` pour exclure les attendances annulées.

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

### 13.2. Échappement JavaScript

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

### 13.3. Cohérence Modèle/Vue/Contrôleur

**Règle** : Les vérifications d'essai gratuit doivent être cohérentes entre :
- **Modèle** (`Attendance`) : Utilise `.active.where()` ✅
- **Contrôleur** (`Initiations::AttendancesController`) : Utilise `.active.where()` ✅
- **Vue** (`_registration_form_fields.html.erb`) : Doit utiliser `.active.where()` ✅

**Vérification** : Tous les fichiers doivent utiliser le même pattern :
```ruby
current_user.attendances.active.where(free_trial_used: true, child_membership_id: ...)
```

---

**Date de création** : 2025-01-17
**Dernière mise à jour** : 2025-01-20
**Version** : 2.1
