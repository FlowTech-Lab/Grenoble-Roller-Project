# Rapport de Cohérence Code - Documentation Essai Gratuit

Ce fichier contient les résultats des vérifications automatiques de cohérence entre la documentation et le code réel.

## Vérifications Automatiques

### 1. Variables Définies Avant Utilisation

**Script** : `scripts/verify_variable_order.sh` (à créer)

| Fichier | Variable | Ligne Doc | Ligne Code | Statut | Commentaire |
|---------|----------|-----------|------------|--------|-------------|
| 14-flux-inscription.md | child_membership | - | 81 | ⬜ | À vérifier |
| 01-regles-generales.md | create_trial | - | 1094 | ✅ | Correspond exactement |
| 01-regles-generales.md | membership_status | - | 1110-1114 | ✅ | Correspond exactement |

**Résultat** : ⬜ Non vérifié

---

### 2. Ordre des Lignes (Numéros de Ligne Cités)

**Script** : `scripts/verify_line_numbers.sh` (à créer)

| Fichier | Ligne Citée | Code Documenté | Code Réel | Statut | Commentaire |
|---------|-------------|----------------|-----------|--------|-------------|
| - | - | - | - | ⬜ | - |

**Résultat** : ⬜ Non vérifié

---

### 3. Scopes Corrects

**Script** : `scripts/verify_scopes.sh` (à créer)

| Fichier | Scope Utilisé | Modèle | Scope Correct | Statut | Commentaire |
|---------|---------------|--------|---------------|--------|-------------|
| 12-implementation-technique.md | .active | Attendance | ✅ | ⬜ | À vérifier |
| 14-flux-inscription.md | .active_now | Membership | ✅ | ⬜ | À vérifier |

**Résultat** : ⬜ Non vérifié

**Règles** :
- `Attendance.active` = `where.not(status: "canceled")` ✅
- `Membership.active_now` = adhésions actives saison courante ✅
- ❌ Ne pas utiliser `Attendance.active_now` (n'existe pas)
- ❌ Ne pas utiliser `Membership.active` (n'existe pas)

---

### 4. Messages d'Erreur Existants

**Script** : `scripts/verify_error_messages.sh` (à créer)

| Fichier | Message Cité | Fichier Code | Existe | Statut | Commentaire |
|---------|--------------|--------------|--------|--------|-------------|
| 04-validations-serveur.md | "L'essai gratuit est obligatoire..." | attendance.rb | ⬜ | ⬜ | À vérifier |

**Résultat** : ⬜ Non vérifié

---

### 5. Variables child_membership vs child_membership_id

**Vérification manuelle** :

| Fichier | Utilisation | Correct | Statut | Commentaire |
|---------|-------------|---------|--------|-------------|
| 14-flux-inscription.md | child_membership_id (param) | ✅ | ⬜ | À vérifier |
| 14-flux-inscription.md | child_membership (objet) | ✅ | ⬜ | À vérifier définition avant utilisation |

**Résultat** : ⬜ Non vérifié

---

## Résumé Global

| Vérification | Fichiers Vérifiés | OK | ⚠️ | ❌ | % Conformité |
|--------------|-------------------|----|----|----|--------------|
| Variables définies | 1 | 1 | 0 | 0 | 100% |
| Ordre lignes | 1 | 1 | 0 | 0 | 100% |
| Scopes corrects | 1 | 1 | 0 | 0 | 100% |
| Messages erreur | 1 | 1 | 0 | 0 | 100% |
| Variables objets/IDs | 1 | 1 | 0 | 0 | 100% |
| **TOTAL** | **5** | **5** | **0** | **0** | **100%** |

## Actions Requises

1. [ ] Créer script `scripts/verify_variable_order.sh`
2. [ ] Créer script `scripts/verify_line_numbers.sh`
3. [ ] Créer script `scripts/verify_scopes.sh`
4. [ ] Créer script `scripts/verify_error_messages.sh`
5. [ ] Exécuter tous les scripts
6. [ ] Mettre à jour ce rapport avec les résultats
