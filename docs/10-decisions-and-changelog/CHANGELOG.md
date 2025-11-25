# Changelog

Ce fichier documente les changements significatifs du projet Grenoble Roller.

## [2025-11-24] - Intégration changement mot de passe dans profil

### Modifié
- **Formulaire de profil unifié** :
  - **Changement de mot de passe intégré** : Plus besoin de page séparée, tout dans `/users/edit`
  - Formulaire unique pour modifier profil ET mot de passe en une seule fois
  - Section "Modifier le mot de passe" avec indicateur de force (conforme 2025)
  - Toggle pour afficher/masquer les mots de passe (accessibilité WCAG 2.2)
  - `current_password` requis pour toute modification (sécurité renforcée)

- **RegistrationsController** :
  - `update_resource` : Gère changement de mot de passe optionnel
  - Vérifie `current_password` même si le mot de passe n'est pas changé
  - Si password vide → vérifie `current_password` puis `update_without_password`
  - Si password rempli → utilise `update_with_password` (vérifie automatiquement)

- **PasswordsController** :
  - Simplifié : Gère uniquement "Mot de passe oublié" (reset via email)
  - Surcharge `require_no_authentication` pour permettre aux utilisateurs connectés d'accéder à `edit`/`update`
  - Redirection vers profil si utilisateur connecté tente d'utiliser "mot de passe oublié"

### Conformité
- ✅ **NIST 2025** : Mot de passe 12 caractères minimum
- ✅ **WCAG 2.2** : Indicateur de force, toggle password, cibles tactiles 44×44px
- ✅ **UX** : Formulaire unifié, pas de navigation entre pages
- ✅ **Sécurité** : `current_password` toujours requis pour modifications

### Fichiers modifiés
- `app/views/devise/registrations/edit.html.erb` (formulaire unifié avec changement mot de passe)
- `app/controllers/registrations_controller.rb` (gestion changement mot de passe optionnel)
- `app/controllers/passwords_controller.rb` (simplifié pour reset uniquement)

### Notes techniques
- Le formulaire de profil permet maintenant de modifier :
  - Informations personnelles (email, bio, etc.)
  - OU mot de passe (nouveau + confirmation)
  - OU les deux en même temps
- `current_password` est obligatoire pour toute modification (sécurité)
- Si les champs password sont vides, seul le profil est mis à jour
- L'indicateur de force du mot de passe est identique à celui de l'inscription

## [2025-11-24] - Simplification formulaire inscription + Confirmation email

### Ajouté
- **Formulaire d'inscription simplifié** :
  - Réduction à **4 champs obligatoires uniquement** : Email, Prénom, Mot de passe (12 caractères), Niveau
  - Prénom obligatoire pour personnaliser les interactions (événements, emails)
  - Skill level avec cards Bootstrap visuelles (Débutant, Intermédiaire, Avancé)
  - Header moderne avec icône dans cercle coloré
  - Labels avec icônes Bootstrap (envelope, person, shield-lock, speedometer)
  - Help text positif pour mot de passe avec exemple de passphrase

- **Confirmation email avec accès immédiat** :
  - Module `:confirmable` activé dans Devise
  - Période de grâce : `allow_unconfirmed_access_for = 2.days` (meilleure UX)
  - Accès immédiat après inscription (navigation, consultation)
  - Confirmation **requise** pour actions critiques :
    - S'inscrire à un événement (`EventsController#attend`)
    - Passer une commande (`OrdersController#create`)
  - Email de confirmation envoyé automatiquement après inscription

- **Email de bienvenue** :
  - `UserMailer.welcome_email` avec template HTML responsive
  - Template texte (fallback)
  - Envoyé automatiquement après création du compte
  - Lien direct vers les événements

- **Skill level** :
  - Nouveau champ `skill_level` (beginner, intermediate, advanced)
  - Validation obligatoire à l'inscription
  - Cards Bootstrap avec icônes et hover effects
  - Responsive (3 colonnes mobile-friendly)

### Modifié
- **Mot de passe** :
  - Longueur réduite : **14 → 12 caractères** (NIST 2025 standard)
  - Help text amélioré : "Astuce : Utilisez une phrase facile à retenir" + exemple
  - Placeholder : "12 caractères minimum"

- **Modèle User** :
  - `first_name` rendu obligatoire (important pour événements)
  - `skill_level` obligatoire avec validation inclusion
  - Callback `after_create :send_welcome_email_and_confirmation`
  - Méthode `active_for_authentication?` pour permettre accès non confirmé

- **CSS** :
  - Skill level cards avec styles Bootstrap `.btn-check`
  - Auth icon wrapper (header moderne)
  - Focus states WCAG 2.2 (outline 3px)
  - Compatible mode sombre

- **Controllers** :
  - `ApplicationController#ensure_email_confirmed` : méthode réutilisable
  - `EventsController` : exige confirmation pour `attend`
  - `OrdersController` : exige confirmation pour `create`
  - `ApplicationController#configure_permitted_parameters` : `first_name` et `skill_level` dans sign_up

### Conformité
- ✅ **NIST 2025** : Mot de passe 12 caractères (standard actuel)
- ✅ **WCAG 2.2** : Focus 3px visible, cibles tactiles 44×44px
- ✅ **RGPD** : Consentement explicite CGU + Politique
- ✅ **UX** : Formulaire simplifié (4 champs, 1 minute)
- ✅ **Sécurité** : Confirmation email pour actions critiques

### Fichiers créés
- `db/migrate/YYYYMMDDHHMMSS_add_skill_level_to_users.rb`
- `db/migrate/YYYYMMDDHHMMSS_add_confirmable_to_users.rb`
- `app/mailers/user_mailer.rb`
- `app/views/user_mailer/welcome_email.html.erb`
- `app/views/user_mailer/welcome_email.text.erb`

### Fichiers modifiés
- `app/models/user.rb` (confirmable, skill_level, first_name obligatoire)
- `app/views/devise/registrations/new.html.erb` (formulaire simplifié 4 champs)
- `app/controllers/application_controller.rb` (ensure_email_confirmed, sign_up params)
- `app/controllers/events_controller.rb` (exige confirmation pour attend)
- `app/controllers/orders_controller.rb` (exige confirmation pour create)
- `config/initializers/devise.rb` (password_length 12, allow_unconfirmed_access_for)
- `app/assets/stylesheets/_style.scss` (skill level cards, auth icon wrapper)

### Notes techniques
- Migration `skill_level` : colonne string avec index
- Migration `confirmable` : colonnes confirmation_token, confirmed_at, confirmation_sent_at, unconfirmed_email
- Email bienvenue + confirmation envoyés en parallèle (`deliver_later`)
- Période de grâce 2 jours : utilisateur peut explorer sans confirmer, mais doit confirmer pour actions critiques

### Corrections finales (2025-11-24)
- **Traductions I18n** : Messages d'erreur corrigés (12 caractères au lieu de 14)
- **Redirection erreurs** : Reste sur `/users/sign_up` en cas d'erreur (ne redirige plus vers `/users`)
- **CSS Input-group** : Contour rouge englobe tout le groupe (input + bouton toggle password)
- **Rack::Attack** : Correction de l'accès à `match_data` dans `throttled_responder`
- **Validation email temps réel** : Abandonnée (validation côté serveur suffisante)

## [2025-11-21] - Pages légales complètes + Gestion des cookies RGPD 2025

### Ajouté
- **Pages légales complètes** :
  - Mentions Légales (`/mentions-legales`) - Obligatoire (risque : 75 000€)
  - Politique de Confidentialité / RGPD (`/politique-confidentialite`, `/rgpd`) - Obligatoire (risque : 4% CA)
  - Conditions Générales de Vente (`/cgv`, `/conditions-generales-vente`) - Obligatoire (risque : 15 000€)
  - Conditions Générales d'Utilisation (`/cgu`, `/conditions-generales-utilisation`) - Recommandé
  - Page Contact (`/contact`) - Recommandé (email uniquement, pas de formulaire)
  - Toutes les pages basées sur les informations collectées de l'association
  - Contenu conforme aux obligations légales françaises (RGPD, Code de la consommation, loi pour la confiance en l'économie numérique)

- **Système de gestion des cookies conforme RGPD 2025** :
  - Banner de consentement automatique (Stimulus Controller)
  - Page de préférences détaillée (`/cookie_consent/preferences`)
  - Gestion granulaire des cookies (nécessaires, préférences, analytiques)
  - Stockage des préférences dans un cookie permanent (13 mois, conforme RGPD)
  - Compatibilité Turbo et Stimulus
  - Accessibilité complète (ARIA labels, navigation clavier)

- **Routes RESTful modernes** :
  - `resource :cookie_consent` avec actions `collection` (preferences, accept, reject, update)
  - Routes légales avec alias pour SEO (`/rgpd`, `/conditions-generales-vente`, etc.)
  - Architecture conforme aux conventions Rails 8

- **Helper Ruby** :
  - `CookieConsentHelper` pour vérifier le consentement côté serveur
  - Méthodes : `cookie_consent?(type)`, `has_cookie_consent?`, `cookie_preferences`

- **Documentation légale** :
  - Formulaire de collecte d'informations complété (`informations-a-collecter.md`)
  - Guide mis à jour avec les informations réelles de l'association (`legal-pages-guide.md`)

### Modifié
- **Footer** :
  - Ajout de tous les liens légaux dans le footer simple
  - Footer complet mis à jour avec les liens légaux (prêt pour utilisation future)

- **Documentation** :
  - Mention des cookies de session Rails utilisés pour le panier d'achat
  - Clarification que les cookies de session sont strictement nécessaires

- **Architecture** :
  - Contrôleur Stimulus `cookie_consent_controller.js` pour gestion moderne du banner
  - Compatibilité Turbo avec gestion des événements `turbo:load`

### Conformité
- ✅ **RGPD** : Conforme (politique de confidentialité complète, gestion des cookies)
- ✅ **Directive ePrivacy** : Conforme (banner de consentement, préférences détaillées)
- ✅ **Code de la consommation** : Conforme (CGV complètes avec exception légale L221-28)
- ✅ **Loi pour la confiance en l'économie numérique** : Conforme (mentions légales complètes)
- ✅ **Accessibilité** : WCAG 2.1 AA (ARIA labels, navigation clavier)

### Fichiers créés
- `app/controllers/legal_pages_controller.rb`
- `app/controllers/cookie_consents_controller.rb`
- `app/helpers/cookie_consent_helper.rb`
- `app/javascript/controllers/cookie_consent_controller.js`
- `app/views/legal_pages/mentions_legales.html.erb`
- `app/views/legal_pages/politique_confidentialite.html.erb`
- `app/views/legal_pages/cgv.html.erb`
- `app/views/legal_pages/cgu.html.erb`
- `app/views/legal_pages/contact.html.erb`
- `app/views/cookie_consents/preferences.html.erb`
- `app/views/layouts/_cookie_banner.html.erb`

### Fichiers modifiés
- `config/routes.rb` (routes RESTful pour pages légales et cookies)
- `app/views/layouts/application.html.erb` (intégration du banner de cookies)
- `app/views/layouts/_footer-simple.html.erb` (liens légaux)
- `app/views/layouts/_footer.html.erb` (liens légaux pour version complète)
- `docs/08-security-privacy/informations-a-collecter.md` (formulaire complété)
- `docs/08-security-privacy/legal-pages-guide.md` (guide mis à jour)

### Notes techniques
- Cookies de session Rails (panier, authentification) sont strictement nécessaires et toujours actifs
- Durée de conservation des cookies de consentement : 13 mois (conforme RGPD)
- Attributs de sécurité : `SameSite: Lax`, `Secure` en production
- Timestamp du consentement pour traçabilité

## [2025-01-20] - Job de rappel la veille à 19h + Option wants_reminder

### Ajouté
- **Job de rappel la veille à 19h** :
  - Job `EventReminderJob` exécuté quotidiennement à 19h via Solid Queue
  - Rappels envoyés pour les événements du lendemain (toute la journée, 00:00:00 à 23:59:59)
  - Planification via `config/recurring.yml` (Solid Queue native)
  - **Impact UX** : Réduction du taux d'absence, amélioration de l'expérience utilisateur

- **Option `wants_reminder` dans les attendances** :
  - Migration pour ajouter `wants_reminder` (boolean, default: false) à `attendances`
  - Index sur `wants_reminder` pour optimiser les requêtes
  - Case à cocher dans les modales d'inscription (activée par défaut)
  - Affichage du statut du rappel sur la page événement (alerte Bootstrap)
  - Bouton pour activer/désactiver le rappel après inscription
  - Action `toggle_reminder` dans `EventsController` pour gérer le rappel
  - Route `PATCH /events/:id/toggle_reminder`
  - Rappels envoyés uniquement aux utilisateurs avec `wants_reminder = true`

- **Tests** :
  - 8 tests pour le job de rappel (événements demain, aujourd'hui, après-demain, brouillons, multiple attendees)
  - 4 tests pour l'action `toggle_reminder` (activation, désactivation, erreur si non inscrit)
  - Trait `:with_reminder` dans la factory `Attendance`
  - **Total : 12 nouveaux tests, 0 échec** ✅

### Modifié
- **Job `EventReminderJob`** :
  - Modification de la logique : rappels pour les événements du lendemain (au lieu de 24h avant)
  - Filtrage par `wants_reminder = true` pour ne rappeler que les utilisateurs qui ont activé le rappel
  - Utilisation de `Time.zone.now.beginning_of_day + 1.day` pour définir la journée du lendemain

- **Configuration `config/recurring.yml`** :
  - Modification du schedule : exécution quotidienne à 19h (au lieu de 9h)
  - Configuration pour development et production

- **Vues** :
  - Mise à jour des messages : "la veille à 19h" au lieu de "24h avant"
  - Affichage du statut du rappel sur la page événement (alerte Bootstrap avec icône)
  - Case à cocher dans les modales d'inscription (show, index, _event_card)

- **Controller `EventsController`** :
  - Action `attend` : accepte le paramètre `wants_reminder` à l'inscription
  - Action `toggle_reminder` : active/désactive le rappel pour un utilisateur inscrit
  - Chargement de `@user_attendance` dans `set_event` pour la vue

- **Modèle `Attendance`** :
  - Ajout de `wants_reminder` dans `ransackable_attributes` pour ActiveAdmin

### Fichiers modifiés
- `app/jobs/event_reminder_job.rb`
- `config/recurring.yml`
- `app/controllers/events_controller.rb`
- `app/models/attendance.rb`
- `app/views/events/show.html.erb`
- `app/views/events/index.html.erb`
- `app/views/events/_event_card.html.erb`
- `config/routes.rb`
- `spec/jobs/event_reminder_job_spec.rb`
- `spec/factories/attendances.rb`

### Fichiers créés
- `db/migrate/20250120140000_add_wants_reminder_to_attendances.rb`

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

