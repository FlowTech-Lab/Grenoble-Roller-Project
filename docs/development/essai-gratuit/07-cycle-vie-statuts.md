# 7. Cycle de Vie des Statuts

[← Retour à l'index](index.md)

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

---

**Navigation** :
- [← Section précédente](06-enfants-multiples.md)
- [← Retour à l'index](index.md)
- [→ Section suivante](08-tests-integration.md)
