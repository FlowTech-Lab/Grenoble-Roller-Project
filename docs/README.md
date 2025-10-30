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
1. Lire `00-overview/project-vision.md` et `03-architecture/system-overview.md`.
2. Suivre `04-rails/setup/` puis `07-ops/runbooks/local-setup.md` pour l’environnement local.
3. Lire `01-ways-of-working/` (branches, PR, revue).
4. Consulter `05-testing/strategy.md` et `rspec-guidelines.md`.

## Qualité & sécurité
- CI: lint RuboCop, Brakeman, Bundler Audit, tests RSpec.
- Secrets: `04-rails/setup/credentials.md` + rotation régulière.
- Performances: traquer N+1, cache, jobs idempotents.

## Mise à jour continue
- À chaque PR significative: mettre à jour la section concernée.
- À chaque décision: créer/mettre à jour un ADR.
- À chaque cycle: renseigner `02-shape-up/building/cycle-XX-build-log.md` puis `cooldown`.

