# 📋 Clarification Documentation - Étapes par Étapes

**Objectif** : Clarifier chaque point de la documentation, valider les besoins, et obtenir les meilleures solutions via Perplexity.

**Méthode** : Un point à la fois avec un prompt structuré pour Perplexity → Analyse → Documentation → Validation → Point suivant.

---

## ✅ Étape 1 : Architecture Produits & Boutique ⭐ **TERMINÉE**

**Statut** : ✅ Solution complète obtenue et documentée

**Fichiers** :
- `PROMPT_ARCHITECTURE_PRODUITS_BOUTIQUE.md` : Prompt envoyé à Perplexity
- `decisions/architecture-panel-admin.md` : Solution complète (1449 lignes)
- `decisions/RESUME_ARCHITECTURE_PANEL_ADMIN.md` : Résumé avec points clés

### Points Clarifiés

1. ✅ **Contexte projet analysé** : Modèles, Active Admin existant, nouveau panel admin
2. ✅ **Besoin documenté** : Gestion produits, variantes, commandes, catégories
3. ✅ **Prompt structuré créé** : 10 questions précises avec contraintes techniques
4. ✅ **Solution obtenue** : Architecture complète avec exemples de code
5. ✅ **Documentation complétée** : Guide complet + résumé créés
6. ⏳ **À faire** : Valider avec l'équipe avant implémentation

### Résumé de la Solution

**Architecture recommandée** :
- Controllers avec scopes et filtres
- Formulaires avec tabs Bootstrap (Informations/Variantes/Images)
- Gestion variantes : Nested forms (MVP) ou Modal Stimulus (production)
- Stock agrégé via helpers
- Validation hybride (Stimulus + Rails)
- Workflow commandes avec Stimulus
- Performance : Eager loading + Pagy

**Voir** : `decisions/RESUME_ARCHITECTURE_PANEL_ADMIN.md` pour résumé complet

### Prochaine Action

**Valider l'architecture** avec l'équipe puis passer à l'implémentation ou à l'Étape 2 (Événements & Initiations).

---

## ⏳ Étape 2 : Architecture Événements & Initiations

**Statut** : À créer après validation Étape 1

**Objectif** : Définir l'architecture pour gérer les événements et initiations dans le panel admin

### Points à Analyser

- Modèles `Event`, `Initiation`, `Attendance`
- Formulaires existants pour créer/modifier événements
- Gestion des présences (attendance)
- Workflow validation événements
- Relations avec routes, utilisateurs, paiements

### Prompt à Créer

**Fichier** : `PROMPT_ARCHITECTURE_EVENEMENTS_INITIATIONS.md`

**Questions clés** :
- Comment gérer les formulaires événements complexes (date, lieu, route, boucles) ?
- Architecture pour la gestion des présences (formulaires batch) ?
- Workflow de validation (draft → published) ?
- Gestion des listes d'attente (waitlist) ?
- Relations avec paiements et adhésions ?

---

## ⏳ Étape 3 : Architecture Adhésions & Paiements

**Statut** : À créer après validation Étape 2

**Objectif** : Définir l'architecture pour gérer les adhésions et paiements

### Points à Analyser

- Modèle `Membership` avec catégories (enfant, adulte, etc.)
- Workflow adhésion (création → paiement → validation)
- Gestion des certificats médicaux
- Intégration HelloAsso/Stripe
- Paiements et remboursements

### Prompt à Créer

**Fichier** : `PROMPT_ARCHITECTURE_ADHESIONS_PAIEMENTS.md`

---

## ⏳ Étape 4 : Architecture Utilisateurs & Rôles

**Statut** : À créer après validation Étape 3

**Objectif** : Définir l'architecture pour gérer les utilisateurs et les rôles

### Points à Analyser

- Modèle `User` avec Devise
- Système de rôles (7 niveaux)
- Profils utilisateurs
- Permissions Pundit
- Gestion bénévoles

### Prompt à Créer

**Fichier** : `PROMPT_ARCHITECTURE_UTILISATEURS_ROLES.md`

---

## ⏳ Étape 5 : Vérification Formulaires Existants

**Statut** : À créer après validation Étape 4

**Objectif** : Identifier tous les formulaires existants dans l'application et valider leur pertinence pour le panel admin

### Points à Analyser

- Formulaires frontend existants (`app/views/*/`)
- Formulaires Active Admin (`app/admin/*.rb`)
- Composants réutilisables
- Validations existantes
- Helpers disponibles

### Actions

1. **Inventaire complet** des formulaires existants
2. **Analyse réutilisation** : Quels formulaires peuvent être réutilisés ?
3. **Gaps identifiés** : Quels formulaires doivent être créés/adaptés ?
4. **Documentation** : Liste des formulaires avec réutilisation recommandée

**Fichier** : `ANALYSE_FORMULAIRES_EXISTANTS.md`

---

## ⏳ Étape 6 : Dashboard & Statistiques

**Statut** : À créer après validation Étape 5

**Objectif** : Définir l'architecture du dashboard avec widgets personnalisables

### Points à Analyser

- Dashboard Active Admin existant (`app/admin/dashboard.rb`)
- Statistiques à afficher
- Widgets personnalisables (US-011)
- Charts et graphiques (bibliothèque à choisir)

### Prompt à Créer

**Fichier** : `PROMPT_ARCHITECTURE_DASHBOARD.md`

**Référence** : Guide existant `ressources/decisions/dashboard-widgets.md` (déjà fait pour US-011)

---

## ⏳ Étape 7 : Migration Active Admin → Nouveau Panel

**Statut** : À créer après toutes les étapes précédentes

**Objectif** : Plan de migration détaillé ressource par ressource

### Points à Analyser

- Mapping complet Active Admin → Nouveau panel
- Ordre de migration recommandé
- Tests de régression
- Documentation utilisateur
- Formation équipe

**Fichier** : `PLAN_MIGRATION_DETAILLE.md`

**Référence** : `ressources/planning/MIGRATION_RESSOURCES.md` (déjà créé, à enrichir)

---

## 📝 Template Prompt Perplexity

Pour chaque nouvelle étape, créer un prompt structuré suivant ce template :

```markdown
# 🎯 Prompt Perplexity : [Sujet]

## 📋 CONTEXTE PROJET
- Application, Stack, Migration

### Modèles Existants
- Liste des modèles concernés avec relations

### Code Existant
- Controllers, vues, Active Admin

### Nouveau Panel Admin
- État actuel

## 🎯 BESOINS IDENTIFIÉS
- Liste détaillée des besoins

## ❓ QUESTIONS POUR PERPLEXITY
- 8-10 questions précises avec contraintes

## 📝 CONTRAINTES TECHNIQUES
- Stack confirmée
- Patterns à suivre
- Bonnes pratiques

## 🎯 RÉSULTAT ATTENDU
- Livrable souhaité avec code d'exemple
```

---

## ✅ Checklist Progression

- [ ] **Étape 1** : Architecture Produits & Boutique
  - [x] Analyse contexte
  - [x] Documentation besoins
  - [x] Prompt créé
  - [ ] Envoyé à Perplexity
  - [ ] Solution documentée
  - [ ] Validé avec équipe

- [ ] **Étape 2** : Architecture Événements & Initiations
  - [ ] Analyse contexte
  - [ ] Prompt créé
  - [ ] Solution obtenue
  - [ ] Documenté
  - [ ] Validé

- [ ] **Étape 3** : Architecture Adhésions & Paiements
  - [ ] Analyse contexte
  - [ ] Prompt créé
  - [ ] Solution obtenue
  - [ ] Documenté
  - [ ] Validé

- [ ] **Étape 4** : Architecture Utilisateurs & Rôles
  - [ ] Analyse contexte
  - [ ] Prompt créé
  - [ ] Solution obtenue
  - [ ] Documenté
  - [ ] Validé

- [ ] **Étape 5** : Vérification Formulaires Existants
  - [ ] Inventaire complet
  - [ ] Analyse réutilisation
  - [ ] Gaps identifiés
  - [ ] Documenté

- [ ] **Étape 6** : Dashboard & Statistiques
  - [ ] Analyse besoins
  - [ ] Prompt créé (si nécessaire)
  - [ ] Architecture définie
  - [ ] Documenté

- [ ] **Étape 7** : Plan Migration Détaillé
  - [ ] Mapping complet
  - [ ] Ordre migration
  - [ ] Tests définis
  - [ ] Documenté

---

## 🚀 Prochaine Action

**IMMÉDIAT** : Envoyer le prompt `PROMPT_ARCHITECTURE_PRODUITS_BOUTIQUE.md` à Perplexity et obtenir la solution complète.

Une fois la solution obtenue, la documenter dans `ressources/decisions/architecture-produits-boutique.md` et valider avec l'équipe avant de passer à l'étape suivante.

---

**Dernière mise à jour** : 2025-01-27  
**Statut** : Étape 1 en cours
