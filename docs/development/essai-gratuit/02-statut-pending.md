# 2. Clarification Statut `pending` (Enfant)

**Version** : 3.3  
**Dernière mise à jour** : 2025-01-20  
**Responsable** : Assistant IA  
**Statut** : ✅ Validé

[← Retour à l'index](index.md)

## 2.1. Règle Métier Claire

**Un enfant avec statut `pending` (adhésion en attente de paiement) :**
- ✅ **Peut s'inscrire SANS utiliser l'essai gratuit** (l'adhésion `pending` est considérée comme valide pour l'inscription)
- ✅ **Peut OPTIONNELLEMENT utiliser son essai gratuit** si disponible (mais ce n'est pas obligatoire)
- ❌ **N'est PAS obligé d'utiliser l'essai gratuit** (contrairement aux enfants `trial`)
- ✅ **L'essai gratuit reste disponible** s'il n'est pas utilisé lors de l'inscription (il peut être utilisé plus tard)

**Différence avec statut `trial` :**
- `trial` = Non adhérent, essai gratuit **OBLIGATOIRE** pour s'inscrire
- `pending` = Adhérent en attente de paiement, essai gratuit **OPTIONNEL**

**⚠️ NOTE IMPORTANTE - Essai Gratuit Optionnel pour Pending** :
- Si un enfant `pending` s'inscrit **SANS** utiliser son essai gratuit (checkbox non cochée), l'essai gratuit **reste disponible** pour une future initiation
- Si un enfant `pending` s'inscrit **AVEC** son essai gratuit (checkbox cochée), l'essai gratuit est **consommé** et l'enfant **ne pourra plus s'inscrire** sans adhésion active
- L'essai gratuit n'est "consommé" que lorsqu'une `Attendance` est créée avec `free_trial_used = true`
- **Exemple concret** :
  - T0: Enfant créé en `pending` → essai gratuit disponible (implicite)
  - T1: Enfant s'inscrit à Initiation A **SANS** cocher la checkbox essai gratuit → `Attendance` créée avec `free_trial_used = false`
  - T2: L'essai gratuit est **toujours disponible** (car `free_trial_used = false`)
  - T3: Enfant peut s'inscrire à Initiation B **AVEC** essai gratuit → `Attendance` créée avec `free_trial_used = true`
  - T4: L'essai gratuit est maintenant **consommé** (car `free_trial_used = true`)
  - T5: Enfant essaie de s'inscrire à Initiation C **SANS** essai gratuit → **BLOQUÉ** (essai déjà utilisé, adhésion non payée)
- **Voir aussi** : [Section détaillée sur la réutilisation](16-reutilisation-annulation.md) et [Cas limite 5.6](05-cas-limites.md#56-réinscription-à-la-même-initiation-après-annulation)

## 2.2. Contexte de Création

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

## 2.3. Logique d'Affichage

Pour un enfant avec statut `pending` :
- La checkbox essai gratuit est **affichée** si l'enfant n'a pas encore utilisé son essai gratuit
- La checkbox est **optionnelle** (pas cochée par défaut, pas obligatoire)
- L'enfant peut s'inscrire même si la checkbox n'est pas cochée (car `pending` est considéré comme valide)

---

**Navigation** :
- [← Section précédente : Règles Générales](01-regles-generales.md)
- [← Retour à l'index](index.md)
- [→ Section suivante : Protection contre les Race Conditions](03-race-conditions.md)
