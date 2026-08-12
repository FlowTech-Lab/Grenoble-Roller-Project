<div align="center">
  <img src="./app/assets/images/logo/logo_grenobleroller_color.png" alt="Grenoble Roller" width="220">

  # Grenoble Roller

  **Plateforme communautaire de l'association de roller de Grenoble : boutique, randonnées, initiations et adhésions dans un seul outil.**

  *Grenoble, France*

  [Français](#fr) · [English](#en)

  [![Site](https://img.shields.io/badge/Site-grenoble-roller.org-6285A4?style=for-the-badge&logo=googlechrome&logoColor=white)](https://grenoble-roller.org/)
  [![GitHub](https://img.shields.io/badge/GitHub-Grenoble-roller-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Grenoble-roller/Grenoble-Roller-Website)
</div>

---

<a id="fr"></a>

# Français

## À propos

Grenoble Roller est la plateforme communautaire de l'association de roller de Grenoble. Développée en Ruby on Rails 8.1, elle regroupe toute la vie de l'association dans un seul outil : boutique de goodies, randonnées et événements, sessions d'initiation, adhésions en ligne et panneau d'administration pour les bénévoles.

L'application est en production sur [grenoble-roller.org](https://grenoble-roller.org/) et remplace la gestion précédente, éclatée entre tableaux Excel et formulaires dispersés.

## Fonctionnalités

**Boutique & paiements**
- Catalogue : Rollers, Protections, Accessoires, avec variantes (taille, couleur) et gestion des stocks
- Panier session + compte, commandes avec 7 emails de suivi (confirmation, payé, annulé, préparation, expédié, remboursement)
- Paiements HelloAsso intégrés : checkout + polling automatique

**Randonnées, événements & initiations**
- Événements hebdomadaires et ponctuels, routes avec GPX
- Inscriptions avec compteurs, liste d'attente et désinscription
- Sessions d'initiation : essai gratuit (1 par personne), réservation de rollers par taille
- Rappels email optionnels, export iCal par événement

**Adhésions**
- Adhésions adultes et enfants (FFRS + Association)
- Paiement HelloAsso et suivi automatique des statuts (pending, active, expired, cancelled)
- Validité d'un an calculée depuis la date d'adhésion

**Administration**
- Panneau d'administration custom (`/admin-panel`) : CRUD, exports CSV, actions rapides, journalisation
- 7 niveaux de rôles (USER → SUPERADMIN), autorisations Pundit
- Suivi des goodies distribués, logs des emails sortants

**Conformité & qualité**
- Accessibilité WCAG 2.1 AA (audit + Pa11y, 6/6 pages conformes)
- RGPD : gestion des cookies, pages légales, conformité ePrivacy
- 166 tests RSpec, RuboCop, Brakeman

## Stack

![Ruby on Rails](https://img.shields.io/badge/Ruby_on_Rails-8.1.1-D30001?style=flat-square&logo=rubyonrails&logoColor=white)
![Ruby](https://img.shields.io/badge/Ruby-3.4.2-CC342D?style=flat-square&logo=ruby&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=flat-square&logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat-square&logo=docker&logoColor=white)

`Devise` · `Pundit` · `Bootstrap 5.3` · `Stimulus` · `Turbo` · `Solid Queue` · `MinIO (Active Storage)` · `RSpec` · `RuboCop` · `Brakeman`

## Démarrage rapide (Docker)

Prérequis : Docker et Docker Compose.

```bash
git clone https://github.com/Grenoble-roller/Grenoble-Roller-Website.git
cd Grenoble-Roller-Website

docker compose -f ops/dev/docker-compose.yml up -d --build
docker exec grenoble-roller-dev bin/rails db:migrate
docker exec grenoble-roller-dev bin/rails db:seed
```

- Application : <http://localhost:3000>
- Base de données : `localhost:5434` (postgres / postgres)

> Les comptes de démonstration sont créés par le seed : voir `docs/04-rails/setup/local-development.md`.

## Tests

```bash
docker exec grenoble-roller-dev bin/rspec
```

166 tests (models, policies, requests), 0 échec.

## Documentation

La documentation complète est dans [`docs/`](docs/00-overview/README.md) : ~100 fichiers markdown organisés en 11 sections (00-overview → 11-templates), couvrant architecture, conventions Rails, administration, runbooks de déploiement, sécurité et vie privée.

## En production

L'application tourne sur un VPS via Docker Compose, avec sauvegardes automatisées et runbooks de déploiement et de rollback. Voir [`docs/07-ops/README.md`](docs/07-ops/README.md).

<div align="center">
  <a href="https://grenoble-roller.org/"><strong>grenoble-roller.org</strong></a>
</div>

---

<a id="en"></a>

# English

## About

Grenoble Roller is the community platform for the Grenoble rollerblading association. Built with Ruby on Rails 8.1, it brings the whole association into one tool: a goodies shop, weekly rides and events, initiation sessions, online memberships and an admin panel for volunteers.

The app runs in production at [grenoble-roller.org](https://grenoble-roller.org/) and replaces the previous setup, scattered across spreadsheets and disconnected forms.

## Features

**Shop & payments**
- Catalogue: Rollers, Protections, Accessories, with variants (size, color) and stock management
- Session + account cart, orders with 7 follow-up emails (confirmation, paid, cancelled, preparation, shipped, refund)
- HelloAsso payments: checkout + automatic polling

**Rides, events & initiations**
- Weekly and one-off events, routes with GPX
- Sign-ups with counters, waitlist and cancellation
- Initiation sessions: free trial (1 per person), roller rental by size
- Optional email reminders, iCal export per event

**Memberships**
- Adult and child memberships (FFRS + Association)
- HelloAsso payment with automatic status tracking (pending, active, expired, cancelled)
- One-year validity computed from the membership date

**Administration**
- Custom admin panel (`/admin-panel`): CRUD, CSV exports, quick actions, audit logs
- 7 role levels (USER → SUPERADMIN), Pundit authorization
- Distributed goodies tracking, outbound email logs

**Compliance & quality**
- WCAG 2.1 AA accessibility (audit + Pa11y, 6/6 pages compliant)
- GDPR: cookie management, legal pages, ePrivacy compliance
- 166 RSpec tests, RuboCop, Brakeman

## Stack

![Ruby on Rails](https://img.shields.io/badge/Ruby_on_Rails-8.1.1-D30001?style=flat-square&logo=rubyonrails&logoColor=white)
![Ruby](https://img.shields.io/badge/Ruby-3.4.2-CC342D?style=flat-square&logo=ruby&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?style=flat-square&logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat-square&logo=docker&logoColor=white)

`Devise` · `Pundit` · `Bootstrap 5.3` · `Stimulus` · `Turbo` · `Solid Queue` · `MinIO (Active Storage)` · `RSpec` · `RuboCop` · `Brakeman`

## Quick start (Docker)

Prerequisites: Docker and Docker Compose.

```bash
git clone https://github.com/Grenoble-roller/Grenoble-Roller-Website.git
cd Grenoble-Roller-Website

docker compose -f ops/dev/docker-compose.yml up -d --build
docker exec grenoble-roller-dev bin/rails db:migrate
docker exec grenoble-roller-dev bin/rails db:seed
```

- App: <http://localhost:3000>
- Database: `localhost:5434` (postgres / postgres)

> Demo accounts are created by the seed: see `docs/04-rails/setup/local-development.md`.

## Tests

```bash
docker exec grenoble-roller-dev bin/rspec
```

166 tests (models, policies, requests), 0 failures.

## Documentation

Full documentation lives in [`docs/`](docs/00-overview/README.md): ~100 markdown files in 11 numbered sections (00-overview → 11-templates) covering architecture, Rails conventions, admin panel, deployment runbooks, security and privacy.

## Production

The app runs on a VPS with Docker Compose, automated backups and deploy/rollback runbooks. See [`docs/07-ops/README.md`](docs/07-ops/README.md).

<div align="center">
  <a href="https://grenoble-roller.org/"><strong>grenoble-roller.org</strong></a>
</div>
