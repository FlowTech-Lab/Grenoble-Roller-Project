# 5. Cas Limites Complets

[← Retour à l'index](index.md)

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

---

**Navigation** :
- [← Section précédente](04-validations-serveur.md)
- [← Retour à l'index](index.md)
- [→ Section suivante](06-enfants-multiples.md)
