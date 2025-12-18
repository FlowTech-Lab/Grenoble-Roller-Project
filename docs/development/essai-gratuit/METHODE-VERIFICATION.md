# Méthode de Vérification de la Documentation Essai Gratuit

**Version** : 2.0  
**Dernière mise à jour** : 2025-01-20  
**Statut** : ✅ Validée à 100%  
**Approche** : QA (Quality Assurance) - Anti-Dette de Documentation

## Objectif

Vérifier que chaque fichier de documentation est :
1. **Complet** : Contient toutes les informations nécessaires
2. **Cohérent** : Correspond au code réel de l'application
3. **À jour** : Reflète l'état actuel de l'implémentation
4. **Précis** : Les exemples de code sont corrects et fonctionnels

**Approche QA (Quality Assurance)** : Cette méthode ne se contente pas de relire le texte, elle force à comparer la documentation avec la réalité du code. C'est le seul moyen d'éviter la **"dette de documentation"** (quand la doc dit A et le code fait B).

## Processus de Vérification

### Étape 1 : Vérification Structurelle (Plus Profonde)

Pour chaque fichier :
- [ ] Le fichier existe et est lisible
- [ ] Le titre principal (H1) est présent et correct
- [ ] Le lien vers l'index est présent
- [ ] La navigation (précédent/suivant) est fonctionnelle
- [ ] Le contenu est bien formaté (Markdown valide)

**✅ Métadonnées Requises** :
- [ ] **Version** : Numéro de version documenté (ex: v3.3)
- [ ] **Date** : Date de dernière mise à jour présente
- [ ] **Responsable** : Nom de la personne qui a créé/modifié le fichier
- [ ] **Statut** : État actuel (✅ Validé, ⚠️ À vérifier, ❌ Non conforme)

**✅ Table of Contents (TOC)** :
- [ ] Les sections principales sont listées dans l'index
- [ ] Les sous-sections (###) sont présentes et numérotées
- [ ] Les liens internes fonctionnent (ancres markdown)

**✅ Fichier de Suivi** :
- [ ] Créer/mettre à jour `_VERIFICATION_STATUS.md` avec l'historique de vérification
- [ ] Enregistrer : Date, Vérificateur, Statut, Commentaires

### Étape 2 : Vérification du Contenu (Mesurable)

Pour chaque section :
- [ ] Les règles métier sont clairement énoncées
- [ ] Les exemples de code sont complets et fonctionnels
- [ ] Les timelines sont précises et cohérentes
- [ ] Les références aux fichiers de code sont correctes

**✅ Matrice de Conformité par Type** :
- [ ] **Règles métier** : Présentes, claires, sans ambiguïté
- [ ] **Code** : Extrait complet, syntaxe correcte, correspond au fichier réel
- [ ] **Timelines** : Tous les timestamps T0-Tn sont présents et cohérents
- [ ] **Cas limites** : Tous nommés (5.1, 5.2, 5.3...) et documentés

**✅ Vérification Timestamps** :
- [ ] Tous les timestamps T0, T1, T2... Tn sont présents dans les timelines
- [ ] L'ordre chronologique est respecté
- [ ] Aucun saut de numéro (T0 → T1 → T2, pas T0 → T3)

**✅ Vérification Cas Limites** :
- [ ] Chaque cas limite a un numéro (5.1, 5.2, 5.3...)
- [ ] Chaque cas limite a un titre descriptif
- [ ] Les cas limites sont listés dans l'index ou le TOC

**✅ Fichier de Suivi** :
- [ ] Créer/mettre à jour `_CONTENT_MATRIX.md` avec la matrice de conformité
- [ ] Pour chaque fichier : % règles métier, % code, % timelines, % cas limites

### Étape 3 : Vérification de Cohérence avec le Code (100% Garanti)

Pour chaque référence de code :
- [ ] Le fichier référencé existe (`app/models/`, `app/controllers/`, etc.)
- [ ] Le code cité correspond au code réel
- [ ] Les méthodes/fonctions mentionnées existent
- [ ] Les validations décrites sont présentes dans le code
- [ ] Les migrations mentionnées existent et sont correctes

**✅ Vérification Automatique par Scripts** :
- [ ] **Variables définies avant utilisation** : Script bash/ruby vérifie que `child_membership` est défini avant utilisation
  ```bash
  # Script à créer : scripts/verify_variable_order.sh
  # Vérifie que child_membership = ... apparaît avant child_membership&.
  ```
- [ ] **Ordre des lignes** : Si numéro de ligne cité (ex: ligne 81), vérifier que le code correspond
  ```bash
  # Script à créer : scripts/verify_line_numbers.sh
  # Vérifie que le code à la ligne X correspond à la documentation
  ```
- [ ] **Scopes corrects** : Script vérifie que `.active` est utilisé pour Attendance, `.active_now` pour Membership
  ```bash
  # Script à créer : scripts/verify_scopes.sh
  # Vérifie que les scopes sont corrects selon le modèle
  ```
- [ ] **Messages d'erreur** : Script vérifie que chaque message d'erreur cité existe vraiment en code
  ```bash
  # Script à créer : scripts/verify_error_messages.sh
  # Vérifie que les messages d'erreur existent dans le code
  ```

**⚠️ Vérifications Critiques des Variables (Anti-Dette de Documentation)** :
- [ ] **Variables d'objet vs ID** : Vérifier que `child_membership` (objet) vs `child_membership_id` (ID) sont utilisés correctement dans le contrôleur
  - `child_membership_id` = paramètre HTTP (ID numérique)
  - `child_membership` = objet récupéré via `find_by(id: child_membership_id)`
  - La documentation doit refléter cette distinction
- [ ] **Scopes** : Vérifier que le scope utilisé est correct selon le modèle
  - `Attendance.active` = `where.not(status: "canceled")` ✅
  - `Membership.active_now` = adhésions actives pour la saison courante ✅
  - Ne pas confondre `.active` (Attendance) avec `.active_now` (Membership)
- [ ] **Définition avant utilisation** : Vérifier que `child_membership` est défini AVANT son utilisation dans le contrôleur
  - Pattern correct : `child_membership = current_user.memberships.find_by(id: child_membership_id)` puis utilisation

**✅ Fichier de Suivi** :
- [ ] Créer/mettre à jour `_CODE_COHERENCE_REPORT.md` avec les résultats des scripts
- [ ] Pour chaque fichier : Variables OK, Scopes OK, Messages OK, Lignes OK

### Étape 4 : Vérification des Cas Limites (Testables)

- [ ] Tous les cas limites documentés sont testables
- [ ] Les scénarios d'erreur sont réalistes
- [ ] Les protections décrites sont implémentées

**✅ Structure Requise pour Chaque Cas Limite** :
- [ ] **Scénario** : Description claire du cas limite
- [ ] **Timeline** : Timeline précise avec timestamps T0-Tn
- [ ] **Protections** : Liste des protections implémentées (Modèle, Contrôleur, DB)
- [ ] **Résultats** : Résultat attendu documenté

**✅ Vérification Automatique** :
- [ ] Script vérifie que chaque cas limite (5.1, 5.2, 5.3...) a :
  - Un scénario
  - Une timeline
  - Des protections listées
  - Un résultat attendu
- [ ] Script vérifie que les protections mentionnées existent vraiment en code
  ```bash
  # Script à créer : scripts/verify_case_limits.sh
  # Vérifie que chaque cas limite est complet et que les protections existent
  ```

**✅ Exemple de Structure Complète** :
```markdown
### 5.1. Double Inscription Avant Annulation

**Scénario** : [Description]

**Timeline** :
```
T0: ...
T1: ...
```

**Protections** :
- ✅ Validation modèle : ...
- ✅ Validation contrôleur : ...
- ✅ Contrainte unique : ...

**Résultat** : ...
```

### Étape 5 : Vérification des Tests (Couverture Garantie)

- [ ] Les tests recommandés sont faisables
- [ ] Les fichiers de test mentionnés existent
- [ ] Les exemples de tests sont syntaxiquement corrects

**✅ Exécution des Tests** :
- [ ] Les tests exécutent sans erreur de syntaxe
- [ ] Les tests exécutent sans erreur d'exécution
- [ ] Les tests couvrent les cas limites documentés

**✅ Couverture** :
- [ ] Calculer le % de couverture pour chaque section documentée
- [ ] Identifier les gaps (sections documentées sans tests)
- [ ] Prioriser les tests manquants

**✅ Fichier de Suivi** :
- [ ] Créer/mettre à jour `_TEST_COVERAGE.md` avec :
  - Liste des tests existants
  - Liste des tests manquants
  - % de couverture globale
  - Gaps identifiés

## Fichiers à Vérifier

### Modèles
- `app/models/attendance.rb` - Validations essai gratuit
- `app/models/membership.rb` - Statuts pending/trial
- `app/models/event/initiation.rb` - Logique initiation

### Contrôleurs
- `app/controllers/initiations/attendances_controller.rb` - Logique inscription
- `app/controllers/memberships_controller.rb` - Création enfant
- `app/controllers/events/attendances_controller.rb` - Inscription événement

### Vues
- `app/views/shared/_registration_form_fields.html.erb` - Formulaire inscription
- `app/views/memberships/child_form.html.erb` - Formulaire création enfant

### Migrations
- `db/migrate/20250117120000_add_unique_constraint_free_trial_active.rb` - Contrainte unique

### Tests
- `spec/models/attendance_spec.rb` - Tests modèle
- `spec/models/membership_spec.rb` - Tests création enfant
- `spec/requests/initiations/attendances_spec.rb` - Tests requête

## Checklist de Vérification par Fichier

### 01-regles-generales.md
- [ ] Code `create_child_membership_from_params` correspond au contrôleur réel
- [ ] Timeline T0-T5 est cohérente
- [ ] Restrictions sont correctes

### 02-statut-pending.md
- [ ] Différence pending vs trial est claire
- [ ] Logique d'affichage correspond à la vue
- [ ] Timeline création enfant est correcte

### 03-race-conditions.md
- [ ] Migration existe et correspond au code
- [ ] Index unique est correctement documenté
- [ ] Timeline T0-T5 est précise
- [ ] Code contrôleur correspond
- [ ] **Commentaire `disable_ddl_transaction!`** : Vérifier que le commentaire expliquant pourquoi `disable_ddl_transaction!` n'est pas utilisé en développement est présent (important pour production)
- [ ] **Index composite enfant** : Vérifier que l'index pour les enfants inclut bien `[:user_id, :child_membership_id]` et non seulement `:user_id`
  - Index parent : `[:user_id]` uniquement ✅
  - Index enfant : `[:user_id, :child_membership_id]` ✅ (composite nécessaire pour distinguer les enfants)

### 04-validations-serveur.md
- [ ] Validations modèle existent dans `attendance.rb`
- [ ] Validations contrôleur correspondent
- [ ] Messages d'erreur sont exacts
- [ ] Principe défense en profondeur est clair

### 05-cas-limites.md
- [ ] Tous les scénarios sont testables
- [ ] Protections décrites sont implémentées
- [ ] Timelines sont cohérentes

### 06-enfants-multiples.md
- [ ] Code ERB correspond à la vue réelle
- [ ] JavaScript correspond au code réel
- [ ] Calcul disponibilité est correct

### 07-cycle-vie-statuts.md
- [ ] Transitions de statut sont correctes
- [ ] Impact sur essai gratuit est précis
- [ ] Flux pending et trial sont documentés

### 08-tests-integration.md
- [ ] Fichiers de test mentionnés existent
- [ ] Syntaxe des tests est correcte
- [ ] Scénarios sont réalistes

### 09-parent-enfant.md
- [ ] Indépendance est claire
- [ ] Exemples sont cohérents
- [ ] Distinction technique est correcte

### 10-javascript-serveur.md
- [ ] Passage données JS correspond au code
- [ ] Comportement sans JS est documenté
- [ ] Garanties sont claires

### 11-metriques-kpis.md
- [ ] Requêtes SQL sont syntaxiquement correctes
- [ ] Champs DB mentionnés existent
- [ ] KPIs sont calculables

### 12-implementation-technique.md
- [ ] Scope `.active` est défini dans le modèle
- [ ] Échappement JS correspond au code
- [ ] Cohérence M/V/C est vérifiée
- [ ] **Scope correct** : Vérifier que la documentation utilise `.active` pour `Attendance` et `.active_now` pour `Membership` (pas de confusion)

### 13-flux-creation-enfant.md
- [ ] Route `/memberships/new?child=true` existe
- [ ] Formulaire correspond à la vue
- [ ] Code création correspond au contrôleur

### 14-flux-inscription.md
- [ ] Code contrôleur complet correspond
- [ ] Logique is_member est correcte
- [ ] Gestion pending/trial est précise
- [ ] **Variable child_membership** : Vérifier que `child_membership` est défini AVANT son utilisation (ligne ~81 du contrôleur)
- [ ] **Distinction child_membership_id vs child_membership** : Vérifier que la documentation distingue bien :
  - `child_membership_id` = paramètre HTTP (ID)
  - `child_membership` = objet récupéré via `find_by`

### 15-quand-essai-utilise.md
- [ ] Timeline est précise
- [ ] Code correspond au contrôleur

### 16-reutilisation-annulation.md
- [ ] Exemple concret est cohérent
- [ ] Code destroy correspond
- [ ] Scope .active est utilisé

### 17-21 (Résumés et Checklist)
- [ ] Points vérifiés sont toujours valides
- [ ] Corrections mentionnées sont appliquées

## Outils de Vérification

### Commandes utiles

```bash
# Vérifier existence fichiers
find app/models app/controllers app/views -name "*.rb" -o -name "*.erb" | grep -E "(attendance|membership|initiation)"

# Vérifier migrations
ls -la db/migrate/*free_trial*

# Vérifier tests
find spec -name "*attendance*" -o -name "*membership*" -o -name "*initiation*"

# Compter lignes documentation
wc -l docs/development/essai-gratuit/*.md
```

### Scripts de Vérification Automatique

**Scripts à créer** :

1. **`scripts/verify_variable_order.sh`** : Vérifie que les variables sont définies avant utilisation
   ```bash
   # Vérifie que child_membership = ... apparaît avant child_membership&.
   ```

2. **`scripts/verify_line_numbers.sh`** : Vérifie que les numéros de ligne cités correspondent
   ```bash
   # Vérifie que le code à la ligne X correspond à la documentation
   ```

3. **`scripts/verify_scopes.sh`** : Vérifie que les scopes sont corrects selon le modèle
   ```bash
   # Vérifie que .active est utilisé pour Attendance, .active_now pour Membership
   ```

4. **`scripts/verify_error_messages.sh`** : Vérifie que les messages d'erreur existent
   ```bash
   # Vérifie que chaque message d'erreur cité existe dans le code
   ```

5. **`scripts/verify_case_limits.sh`** : Vérifie que les cas limites sont complets
   ```bash
   # Vérifie que chaque cas limite a scénario + timeline + protections + résultats
   ```

6. **`scripts/verify_timestamps.sh`** : Vérifie que les timestamps T0-Tn sont présents
   ```bash
   # Vérifie que tous les timestamps sont présents et dans l'ordre
   ```

## Tableau Maître - Pilotage Complet

**✅ Fichier Centralisé** : `_MASTER_CHECKLIST.md`

Ce fichier centralise toutes les vérifications et permet un pilotage complet :

### Structure du Tableau Maître

| Fichier | Statut | Responsable | Date Vérif | Priorité | Commentaires |
|---------|--------|-------------|------------|----------|--------------|
| 01-regles-generales.md | ✅ | Nom | 2025-01-20 | - | - |
| 02-statut-pending.md | ⚠️ | Nom | 2025-01-20 | 🟡 | À vérifier scopes |
| ... | ... | ... | ... | ... | ... |

### Statuts Possibles
- ✅ **Validé** : Toutes les vérifications passent
- ⚠️ **À vérifier** : Quelques points à corriger
- ❌ **Non conforme** : Problèmes majeurs
- 🔄 **En cours** : Vérification en cours

### Priorités
- 🔴 **BLOQUANT** : Bloque la validation à 100%
- 🟡 **À CORRIGER** : Doit être corrigé avant validation finale
- 🟢 **OPTIONNEL** : Amélioration suggérée

### Vue Globale

**Statistiques** :
- Total fichiers : 21
- Validés : X
- À vérifier : Y
- Non conformes : Z
- **% Complétude** : XX%

## Rapport de Vérification

Après chaque vérification, créer un rapport avec :
- Date de vérification
- Vérificateur
- Fichiers vérifiés
- Problèmes trouvés
- Corrections apportées
- État final (✅/⚠️/❌)
- **Mise à jour du `_MASTER_CHECKLIST.md`**

## Fichiers de Suivi

Cette méthode utilise 5 fichiers de suivi pour un pilotage complet :

1. **`_MASTER_CHECKLIST.md`** : Tableau maître centralisé avec vue globale
2. **`_VERIFICATION_STATUS.md`** : Historique complet de toutes les vérifications
3. **`_CONTENT_MATRIX.md`** : Matrice de conformité du contenu (règles, code, timelines, cas limites)
4. **`_CODE_COHERENCE_REPORT.md`** : Résultats des vérifications automatiques de cohérence
5. **`_TEST_COVERAGE.md`** : Rapport de couverture des tests

**Workflow recommandé** :
1. Exécuter les scripts de vérification automatique
2. Mettre à jour `_CODE_COHERENCE_REPORT.md`
3. Compléter `_CONTENT_MATRIX.md` avec les mesures
4. Mettre à jour `_TEST_COVERAGE.md` avec les résultats tests
5. Enregistrer dans `_VERIFICATION_STATUS.md`
6. Mettre à jour `_MASTER_CHECKLIST.md` avec le statut global

## Maintenance

- Vérifier après chaque modification du code
- Mettre à jour la documentation si le code change
- Archiver les anciennes versions si nécessaire
- **Exécuter les scripts automatiques régulièrement**
- **Mettre à jour les fichiers de suivi après chaque vérification**

## Pièges Courants à Éviter (Basés sur v3.2)

### Variables qui changent souvent

1. **`child_membership` vs `child_membership_id`**
   - ❌ **Erreur** : Utiliser `child_membership` avant de l'avoir défini
   - ✅ **Correct** : Définir `child_membership = current_user.memberships.find_by(id: child_membership_id)` puis utiliser
   - 📍 **Où vérifier** : `14-flux-inscription.md`, contrôleur ligne ~81

2. **Scope `.active` vs `.active_now`**
   - ❌ **Erreur** : Utiliser `Attendance.active_now` (n'existe pas)
   - ✅ **Correct** : `Attendance.active` = `where.not(status: "canceled")`
   - ✅ **Correct** : `Membership.active_now` = adhésions actives saison courante
   - 📍 **Où vérifier** : `12-implementation-technique.md`, tous les fichiers mentionnant les scopes

3. **Index composite oublié**
   - ❌ **Erreur** : Index enfant avec seulement `:user_id`
   - ✅ **Correct** : Index enfant avec `[:user_id, :child_membership_id]` (composite nécessaire)
   - 📍 **Où vérifier** : `03-race-conditions.md`, migration ligne ~21

### Commentaires techniques manquants

1. **`disable_ddl_transaction!`**
   - ⚠️ **Important** : Le commentaire expliquant pourquoi ce n'est pas utilisé en dev mais recommandé en prod doit être présent
   - 📍 **Où vérifier** : `03-race-conditions.md`, migration ligne ~7-9

## Validation Finale

Avant de valider une documentation à 100%, s'assurer que :
- [ ] Toutes les variables sont définies avant utilisation
- [ ] Les scopes sont corrects selon le modèle
- [ ] Les index composites sont complets
- [ ] Les commentaires techniques sont présents
- [ ] Aucune confusion entre objets et IDs

## Checklist Rapide Anti-Dette de Documentation

**Avant chaque validation, vérifier ces 5 points critiques** :

1. ✅ **Variables définies** : `child_membership` défini avant utilisation ?
2. ✅ **Scopes corrects** : `.active` pour Attendance, `.active_now` pour Membership ?
3. ✅ **Index composite** : `[:user_id, :child_membership_id]` pour enfants ?
4. ✅ **Commentaire prod** : `disable_ddl_transaction!` expliqué ?
5. ✅ **Objets vs IDs** : Distinction `child_membership` (objet) vs `child_membership_id` (ID) claire ?

**Si tous ces points sont ✅, la documentation est prête pour validation à 100%.**

---

## Résumé de la Méthode v2.0

### 🎯 Objectif Principal

**Éviter la dette de documentation** en comparant systématiquement la documentation avec le code réel.

### 📊 Structure Complète

1. **5 Étapes de Vérification** :
   - Étape 1 : Structurelle (métadonnées, TOC, historique)
   - Étape 2 : Contenu (matrice mesurable, timestamps, cas limites)
   - Étape 3 : Cohérence Code (scripts automatiques, variables, scopes)
   - Étape 4 : Cas Limites (structure complète, protections vérifiées)
   - Étape 5 : Tests (exécution, couverture, gaps)

2. **5 Fichiers de Suivi** :
   - `_MASTER_CHECKLIST.md` : Vue globale, pilotage complet
   - `_VERIFICATION_STATUS.md` : Historique complet
   - `_CONTENT_MATRIX.md` : Matrice de conformité mesurable
   - `_CODE_COHERENCE_REPORT.md` : Résultats vérifications automatiques
   - `_TEST_COVERAGE.md` : Couverture tests et gaps

3. **6 Scripts Automatiques** (à créer) :
   - `verify_variable_order.sh` : Variables définies avant utilisation
   - `verify_line_numbers.sh` : Numéros de ligne corrects
   - `verify_scopes.sh` : Scopes corrects selon modèle
   - `verify_error_messages.sh` : Messages d'erreur existent
   - `verify_case_limits.sh` : Cas limites complets
   - `verify_timestamps.sh` : Timestamps T0-Tn présents

### ✅ Points Forts

- **Mesurable** : Matrices de conformité avec pourcentages
- **Automatisable** : Scripts bash/ruby pour vérifications répétables
- **Traçable** : Historique complet de toutes les vérifications
- **Pilotable** : Tableau maître centralisé avec priorités
- **Garanti** : 100% de cohérence code/documentation

### 🚀 Utilisation

1. Exécuter les scripts automatiques
2. Compléter les fichiers de suivi
3. Mettre à jour `_MASTER_CHECKLIST.md`
4. Traiter les priorités 🔴 puis 🟡
5. Valider à 100% quand tous les points sont ✅
