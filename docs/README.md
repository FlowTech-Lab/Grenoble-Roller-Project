# Documentation du projet (Rails)

Ce dossier structure la **documentation vivante** du monolithe Ruby on Rails. Elle suit Shape Up et les bonnes pratiques d’un projet collaboratif (4 devs).

## Sommaire
- 00-overview: vision, périmètre, glossaire, parties prenantes
- 01-ways-of-working: règles d’équipe (branches, PRs, revues, commits, rituels)
- 02-shape-up: cycles Shape Up (shaping, betting, building, cooldown)
- 03-architecture: vues C4, domaine, NFRs, ADRs
- 04-rails: conventions, structure app, setup, sécurité, perf, API
- 05-testing: stratégie de tests, RSpec, données de test, de bout en bout
- 06-infrastructure: déploiement, CI/CD, observabilité
- 07-ops: runbooks (setup local, backup/restore, incidents)
- 08-security-privacy: modèle de menace, checklist Rails, secrets, RGPD
- 09-product: personas, parcours, critères d’acceptation, wireframes
- 10-decisions-and-changelog: décisions et changelog
- 11-templates: gabarits (ADR, PR, issues, architectures)

## Contribuer à la doc
1. Créer/éditer dans la section adéquate (voir sommaire).
2. Petits PRs, titres clairs, utilisez les templates (`11-templates`).
3. Référencer les ADRs pour toute décision structurante (voir `03-architecture/adr`).
4. Lier depuis `README.md` principal si un document devient critique.

## Conventions
- Nommage fichiers: kebab-case, en anglais sauf sections produit.
- Cycles Shape Up: `cycle-01`, `cycle-02`, … dans `02-shape-up/*`.
- ADRs: `ADR-XXX-titre-court.md` (voir template). Numérotation séquentielle.
- Pas de docs obsolètes: si un doc est dépassé, soit le mettre à jour, soit le supprimer.

## Flux recommandé (nouveau dev)
1. Lire le `README.md` principal du projet pour une vue d'ensemble.
2. Suivre `04-rails/setup/local-development.md` pour configurer l'environnement local avec Docker.
3. Consulter `03-architecture/domain/models.md` pour comprendre la structure des données.
4. Lire `04-rails/setup/credentials.md` pour la gestion des secrets.
5. Lire `01-ways-of-working/` (branches, PR, revue).
6. Consulter `05-testing/strategy.md` pour les tests.

## Déploiement
- **Développement** : `04-rails/setup/local-development.md` ou `07-ops/runbooks/local-setup.md`
- **Staging** : `07-ops/runbooks/staging-setup.md`
- **Production** : À venir

## Qualité & sécurité
- CI: lint RuboCop, Brakeman, Bundler Audit, tests RSpec.
- Secrets: `04-rails/setup/credentials.md` + rotation régulière.
- Performances: traquer N+1, cache, jobs idempotents.

## Documentation actuelle (État du projet - Nov 2025)

### Setup & Configuration
- ✅ `04-rails/setup/local-development.md` - Guide de setup avec Docker (dev)
- ✅ `04-rails/setup/credentials.md` - Gestion des credentials Rails
- ✅ `07-ops/runbooks/staging-setup.md` - Guide d'installation staging

### Architecture
- ✅ `03-architecture/domain/models.md` - Modèles de domaine actuels (e-commerce)

### Operations
- ✅ `07-ops/runbooks/local-setup.md` - Runbook setup local

### À compléter
- `00-overview/project-vision.md` - Vision du projet
- `03-architecture/system-overview.md` - Vue d'ensemble système
- `07-ops/runbooks/production-setup.md` - Guide d'installation production

## Mise à jour continue
- À chaque PR significative: mettre à jour la section concernée.
- À chaque décision: créer/mettre à jour un ADR.
- À chaque cycle: renseigner `02-shape-up/building/cycle-XX-build-log.md` puis `cooldown`.

