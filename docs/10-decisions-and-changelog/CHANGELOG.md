# Changelog

Ce fichier documente les changements significatifs du projet Grenoble Roller.

## [2025-11-10] - Optimisations DB + Feature max_participants + Correction bug boutons

### Ajouté
- **Counter cache `attendances_count`** :
  - Migration pour ajouter la colonne `attendances_count` sur `events`
  - `counter_cache: true` dans le modèle `Attendance`
  - Mise à jour automatique des compteurs lors de création/suppression d'inscriptions
  - Remplacement de `event.attendances.count` par `event.attendances_count` dans toutes les vues
  - **Impact performance** : Réduction des requêtes SQL (plus de COUNT(*) par événement)

- **Feature `max_participants`** :
  - Migration pour ajouter `max_participants` sur `events` (default: 0 = illimité)
  - Validation `max_participants >= 0` (0 = illimité)
  - Méthodes `unlimited?`, `full?`, `remaining_spots`, `has_available_spots?` dans `Event`
  - Validation dans `Attendance` pour empêcher l'inscription si événement plein
  - Comptage uniquement des inscriptions actives (non annulées)
  - Intégration dans `EventPolicy` (`attend?`, `can_attend?`, `user_has_attendance?`)
  - Affichage des places restantes dans les vues (badges "Complet", "X places disponibles", "Illimité")
  - Bouton "S'inscrire" désactivé si événement plein
  - **Popup de confirmation Bootstrap** avant inscription avec détails de l'événement
  - Champ `max_participants` dans le formulaire d'événement (public et ActiveAdmin)
  - Intégration dans ActiveAdmin (affichage dans index/show/form)

- **Tests** :
  - 3 tests pour le counter cache (incrémentation, décrémentation, échec)
  - 57 tests pour `max_participants` (validations, méthodes, policy, attendances)
  - **Total : 166 exemples, 0 échec** (106 + 60 nouveaux)

### Modifié
- **Modèle Event** :
  - Ajout de `max_participants` dans les validations et `ransackable_attributes`
  - Méthodes `full?`, `unlimited?`, `remaining_spots`, `has_available_spots?`, `active_attendances_count`
  - Comptage uniquement des inscriptions actives pour vérifier si plein

- **Modèle Attendance** :
  - Validation `event_has_available_spots` pour empêcher l'inscription si événement plein
  - Les inscriptions annulées ne comptent pas dans la limite

- **Policy EventPolicy** :
  - `attend?` retourne `false` si événement plein
  - Nouvelles méthodes `can_attend?` et `user_has_attendance?`
  - Ajout de `max_participants` dans `permitted_attributes`

- **Vues** :
  - Affichage des places restantes (badges, compteurs)
  - Boutons conditionnels (désactivés si plein)
  - Popup de confirmation Bootstrap pour l'inscription
  - Mise à jour de toutes les vues (cards, show, index, homepage)

- **ActiveAdmin** :
  - Affichage de `max_participants` dans l'index (avec "Illimité" si 0)
  - Affichage des places restantes dans le show
  - Champ `max_participants` dans le formulaire avec aide contextuelle

- **FactoryBot** :
  - Ajout de `max_participants: 0` par défaut (illimité)
  - Traits `:with_limit` (20 participants) et `:unlimited` (0)

### Corrigé
- **Bug des boutons dans les cards d'événements** :
  - Le `stretched-link` sur le titre interceptait tous les clics, y compris sur les boutons
  - **Solution** : Restructuration HTML avec zone cliquable séparée (`.card-clickable-area`) et zone des boutons (`.action-row-wrapper`)
  - Le `stretched-link` ne couvre plus que le contenu (titre, description, infos), pas les boutons
  - Tous les boutons fonctionnent correctement (S'inscrire, Voir plus, Modifier, Supprimer)
  - Ajout de styles CSS pour isoler les zones cliquables

### Fichiers modifiés
- `db/migrate/20251110141700_add_attendances_count_to_events.rb`
- `db/migrate/20251110142027_add_max_participants_to_events.rb`
- `app/models/event.rb`
- `app/models/attendance.rb`
- `app/policies/event_policy.rb`
- `app/controllers/events_controller.rb`
- `app/views/events/_event_card.html.erb`
- `app/views/events/show.html.erb`
- `app/views/events/index.html.erb`
- `app/views/pages/index.html.erb`
- `app/views/events/_form.html.erb`
- `app/admin/events.rb`
- `spec/models/event_spec.rb`
- `spec/models/attendance_spec.rb`
- `spec/policies/event_policy_spec.rb`
- `spec/factories/events.rb`
- `app/assets/stylesheets/_style.scss`

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

