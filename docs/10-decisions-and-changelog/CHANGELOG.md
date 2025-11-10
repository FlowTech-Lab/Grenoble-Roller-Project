# Changelog

Ce fichier documente les changements significatifs du projet Grenoble Roller.

## [2025-11-10] - Upgrade Rails 8.1.1 + Ruby 3.4.2

### Ajouté
- **Tests RSpec complets** :
  - Factories FactoryBot pour tous les modèles (Role, User, Route, Event, Attendance)
  - Tests requests pour EventsController et AttendancesController
  - Tests policies pour EventPolicy (permissions, scopes)
  - **106 exemples, 0 échec** (75 models + 12 policies + 19 requests)

- **Documentation** :
  - Procédures de rebuild complet Docker
  - Gestion des assets Bootstrap et Bootstrap Icons
  - Documentation des factories FactoryBot

### Modifié
- **Upgrade Rails** : 8.0.4 → 8.1.1
- **Upgrade Ruby** : 3.4.1 → 3.4.2
- **Docker Compose** : Ajout de `BUNDLE_PATH=/rails/vendor/bundle` pour gestion correcte des gems
- **Documentation setup** : Commandes docker-compose mises à jour avec BUNDLE_PATH
- **Documentation testing** : Couverture mise à jour (106 exemples)

### Corrigé
- **Assets Bootstrap** : Restauration de `vendor/javascript/bootstrap.bundle.min.js` après rebuild
- **Fonts Bootstrap Icons** : Copie des fonts dans `app/assets/builds/fonts/` après rebuild
- **Tests** : Résolution des problèmes de frozen paths avec Rails 8.1.1

### Notes techniques
- Rails 8.1.1 résout les problèmes de compatibilité avec Ruby 3.4 (FrozenError)
- Support officiel Ruby 3.4.2 comme version recommandée
- Plus besoin de workarounds (Bootsnap, duplication paths)
- Warnings Sass dépréciés (`@import` → `@use`) : à migrer ultérieurement

## [2025-11-08] - Phase 2 : Events Public CRUD + Inscriptions

### Ajouté
- **CRUD Events public** :
  - Liste des événements (`/events`)
  - Détail événement (`/events/:id`)
  - Création/édition événement (organizers)
  - Suppression événement (créateur ou admin)
  - UI/UX conforme UI-Kit (cards, hero, auth-form, mobile-first)

- **Inscriptions** :
  - Route `POST /events/:id/attend` (inscription)
  - Route `DELETE /events/:id/cancel_attendance` (désinscription)
  - Page "Mes sorties" (`/attendances`)
  - Compteur de participants sur les cartes événements
  - Badge "Inscrit" pour les utilisateurs inscrits

- **Policies Pundit** :
  - EventPolicy (show, create, update, destroy, attend, cancel_attendance)
  - Scopes par rôle (guest, member, organizer, admin)

- **Navigation** :
  - Lien "Événements" dans la navbar
  - Lien "Mes sorties" dans le menu utilisateur

### Modifié
- **ActiveAdmin** : Installation et configuration avec Pundit
- **Routes** : Ajout des routes events et attendances
- **Helpers** : `event_cover_image_url` pour gestion des images événements

## [2025-01-XX] - Phase 1 : E-commerce

### Ajouté
- E-commerce complet (produits, panier, commandes, paiements)
- Authentification Devise
- Rôles et permissions (visitor, member, organizer, admin, superadmin)
- ActiveAdmin pour back-office
- Seeds complets (Phase 1 + Phase 2)

---

## Format

Les entrées suivent le format [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/).

### Types de changements
- **Ajouté** : Nouvelles fonctionnalités
- **Modifié** : Changements dans les fonctionnalités existantes
- **Déprécié** : Fonctionnalités qui seront supprimées
- **Supprimé** : Fonctionnalités supprimées
- **Corrigé** : Corrections de bugs
- **Sécurité** : Vulnérabilités corrigées

