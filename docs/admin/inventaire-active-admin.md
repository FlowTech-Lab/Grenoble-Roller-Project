# Inventaire complet des fonctionnalités Active Admin

**Date de création** : 2025-01-27  
**Objectif** : Recenser toutes les fonctionnalités Active Admin utilisées pour faciliter la migration vers un panel admin personnalisé

---

## 📋 Vue d'ensemble

Ce document liste **toutes les fonctionnalités Active Admin** actuellement utilisées dans l'application Grenoble Roller. Il servira de référence pour choisir et implémenter la meilleure solution de remplacement.

**Nombre total de ressources** : 24 ressources + 2 pages personnalisées

---

## 🎯 Configuration globale

### Authentification & Autorisation
- **Authentification** : Devise (`authenticate_user!`)
- **Autorisation** : Pundit (`ActiveAdmin::PunditAdapter`)
- **Policy par défaut** : `Admin::ApplicationPolicy`
- **Namespace policy** : `:admin`
- **Rôles autorisés** : `ADMIN`, `SUPERADMIN` (niveau >= 60)

### Autres configurations
- **Namespace par défaut** : `:activeadmin`
- **Titre du site** : "Grenoble Roller Admin"
- **Batch actions** : Activées
- **Comments** : Activés (par défaut)
- **Filtres** : Activés par défaut
- **Format de date** : `:long`
- **Logout** : Redirige vers `/` (GET)

---

## 📊 Dashboard (Page personnalisée)

**Fichier** : `app/admin/dashboard.rb`

### Fonctionnalités
- **Statistiques principales** (8 cartes) :
  - Événements à valider (avec lien)
  - Nombre d'utilisateurs (avec lien)
  - Commandes en attente (avec lien)
  - CA boutique (commandes payées)
  - Adhésions actives (avec lien)
  - Adhésions en attente (avec lien)
  - Revenus adhésions (saison courante)
  - CA total (boutique + adhésions)

- **Section Événements à valider** :
  - Liste des 10 derniers événements en attente
  - Tableau avec : Titre, Créateur, Date prévue, Inscriptions
  - Lien vers tous les événements à valider

- **Section Statistiques Boutique** :
  - Produits en catalogue
  - Produits en rupture de stock
  - Commandes payées/complétées
  - CA boutique
  - Liste des 5 dernières commandes (utilisateur, total, statut, date)

- **Section Statistiques Adhésions** :
  - Adhésions actives
  - Adhésions en attente
  - Adhésions personnelles (toutes saisons)
  - Adhésions enfants (toutes saisons)
  - Adhésions expirant bientôt (30j)
  - Revenus adhésions
  - Liste des 5 dernières adhésions (utilisateur, type, nom, total, statut, date)

- **Section Accès rapide** :
  - Liens vers : Événements, Utilisateurs, Commandes, Produits, Messages de contact, Adhésions

---

## ⚙️ Maintenance Mode (Page personnalisée)

**Fichier** : `app/admin/maintenance.rb`

### Fonctionnalités
- **Affichage de l'état actuel** : Actif/Inactif avec indicateur visuel
- **Bouton d'activation** : Visible uniquement pour ADMIN/SUPERADMIN
- **Bouton de désactivation** : Visible quand maintenance active
- **Informations techniques** : Cache key, status, middleware
- **Documentation intégrée** : Liste des comportements en maintenance

### Actions personnalisées
- Route : `toggle_activeadmin_maintenance_path` (PATCH)
- Controller : `Admin::MaintenanceToggleController`

---

## 👥 Utilisateurs

**Fichier** : `app/admin/users.rb`  
**Menu** : Parent "Utilisateurs", priorité 1

### Index
- Colonnes : ID, Nom complet, Email, Rôle, Bénévole, Confirmé, Date de création
- Colonne sélectionnable
- Actions : Voir, Modifier, Supprimer

### Filtres
- Email
- Email non confirmé (`unconfirmed_email`)
- Prénom
- Nom
- Rôle
- Bénévole (boolean)
- Date de confirmation
- Date de naissance
- Ville
- Date de création

### Show
- **Informations personnelles** : ID, Email, Email non confirmé, Prénom, Nom, Date de naissance, Téléphone, Bio, Avatar (image ou URL), Niveau de compétence
- **Adresse** : Adresse, Ville, Code postal
- **Confirmation d'email (Devise)** : Date de confirmation, Statut confirmé, Token (masqué), Date d'envoi, Date d'utilisation, IP, User-Agent
- **Autres informations** : Rôle, Bénévole, Préférences email/événements/initiations/WhatsApp, Dates (remember, reset password, création, mise à jour)
- **Panel Inscriptions** : Tableau des participations (événement, statut, date)

### Form
- **Informations personnelles** : Email, Prénom, Nom, Date de naissance, Téléphone, Bio, Niveau de compétence
- **Adresse** : Adresse, Ville, Code postal
- **Authentification** : Mot de passe (optionnel si existant), Confirmation, Rôle
- **Préférences** : Email info, Événements mail, Initiations mail, WhatsApp
- **Bénévole** : Checkbox avec hint
- **Avatar** : Upload fichier ou URL

### Actions personnalisées
- `destroy` : Avec autorisation Pundit
- `update` : Gestion spéciale des champs password et can_be_volunteer

---

## 🎭 Rôles

**Fichier** : `app/admin/roles.rb`  
**Menu** : Parent "Utilisateurs", priorité 2

### Index
- Colonnes : ID, Nom, Code, Niveau, Description, Dates
- Filtres activés

### Filtres
- Nom
- Code
- Niveau
- Utilisateur (email contient)
- Dates de création/mise à jour

### Show
- Attributs : Nom, Code, Niveau, Description, Dates
- **Panel Utilisateurs associés** : Tableau avec email, prénom, nom, date de création

### Form
- Champs : Nom, Code, Niveau, Description

---

## 🛒 Boutique

### Produits

**Fichier** : `app/admin/products.rb`  
**Menu** : Parent "Boutique", priorité 1

#### Index
- Colonnes : ID, Nom, Catégorie, Slug, Actif/Inactif, Prix, Stock (avec alertes), Date de création
- **Scopes** : Tous, Actifs, Inactifs, En rupture de stock, En stock

#### Filtres
- Nom, Catégorie, Actif, Devise, Date de création

#### Show
- Attributs : Nom, Catégorie, Slug, Description, Prix, Stock (avec alertes), Devise, Statut actif, Image (upload ou URL), Dates
- **Panel Variantes du produit** :
  - Bouton "Créer une nouvelle variante"
  - Tableau des variantes : SKU, Options (couleur/taille), Prix, Stock, Statut, Actions (Voir, Modifier, Supprimer)

#### Form
- **Produit** : Catégorie, Nom, Slug, Description, Prix (cents), Devise, Stock (hint: géré au niveau variantes), Actif, Image (upload ou URL)

#### Actions personnalisées
- `destroy` : Avec autorisation

---

### Catégories de produits

**Fichier** : `app/admin/product_categories.rb`  
**Menu** : Parent "Boutique", priorité 2

#### Index
- Colonnes : ID, Nom, Slug, Nombre de produits, Date de création

#### Filtres
- Nom, Slug, Date de création

#### Show
- Attributs : ID, Nom, Slug, Dates
- **Panel Products** : Tableau avec ID (lien), Nom, Prix, Stock, Statut, Date

#### Form
- Champs : Nom, Slug

---

### Variantes de produits

**Fichier** : `app/admin/product_variants.rb`  
**Menu** : Parent "Boutique", priorité 3

#### Index
- Colonnes : ID, Produit (lien), SKU, Options (couleur/taille formatées), Prix, Stock (avec alertes), Statut, Date
- **Scopes** : Tous, Actives, Inactives, En rupture, En stock

#### Filtres
- Produit, SKU, Actif, Stock, Date de création

#### Show
- Attributs : Produit (lien), SKU, Options formatées, Prix, Stock (avec alertes), Statut, Dates

#### Form
- **Variante** : Produit (select), SKU, Prix (cents), Devise, Stock, Actif
- **Options** : Checkboxes pour sélectionner les valeurs d'options (couleur/taille)

---

### Types d'options

**Fichier** : `app/admin/option_types.rb`  
**Menu** : Parent "Boutique", priorité 4

#### Index
- Colonnes : ID, Nom, Nombre de valeurs d'options, Date

#### Filtres
- Nom, Date de création

#### Show
- Attributs : ID, Nom, Dates
- **Panel Option Values** : Tableau avec ID, Valeur, Date

#### Form
- Champs : Nom

---

### Valeurs d'options

**Fichier** : `app/admin/option_values.rb`  
**Menu** : Parent "Boutique", priorité 5

#### Index
- Colonnes : ID, Valeur, Type d'option, Nombre de variantes utilisant cette valeur, Date

#### Filtres
- Type d'option, Valeur, Date de création

#### Show
- Attributs : ID, Valeur, Type d'option, Dates
- **Panel Product Variants** : Tableau avec ID, Produit (lien), SKU, Prix

#### Form
- Champs : Type d'option, Valeur

---

### Associations variantes-options

**Fichier** : `app/admin/variant_option_values.rb`  
**Menu** : Parent "Boutique", priorité 6

#### Index
- Colonnes : ID, Variante (lien SKU), Produit (lien), Valeur d'option (lien), Type d'option (lien), Date

#### Filtres
- Variante, Valeur d'option, Date de création

#### Show
- Attributs : ID, Variante (lien), Produit (lien), Valeur d'option (lien), Type d'option (lien), Dates

#### Form
- Champs : Variante, Valeur d'option

---

## 📦 Commandes

### Commandes

**Fichier** : `app/admin/orders.rb`  
**Menu** : Parent "Commandes", priorité 1

#### Index
- Colonnes : ID, Utilisateur, Statut (avec tags colorés), Total, Paiement, Date
- **Scopes** : Tous, En attente, Complétées, Annulées

#### Filtres
- Utilisateur, Statut, Paiement, Date de création

#### Show
- Attributs : ID, Utilisateur, Statut (avec tags), Total, Don (si > 0), Devise, Paiement, Dates
- **Panel Articles** : Tableau avec Variante ID, Quantité, Prix unitaire, Date

#### Form
- Champs : Utilisateur (select), Statut (select), Total (cents), Don (cents), Devise, Paiement

---

### Articles de commande

**Fichier** : `app/admin/order_items.rb`  
**Menu** : Parent "Commandes", priorité 3

#### Index
- Colonnes : ID, Commande (lien), Variante (lien SKU), Produit (lien), Quantité, Prix unitaire, Total calculé, Date

#### Filtres
- Commande, Variante, Quantité, Date de création

#### Show
- Attributs : ID, Commande (lien), Variante (lien), Produit (lien), Quantité, Prix unitaire, Total calculé, Dates

#### Form
- Champs : Commande, Variante, Quantité, Prix unitaire (cents)

---

### Paiements

**Fichier** : `app/admin/payments.rb`  
**Menu** : Parent "Commandes", priorité 2

#### Index
- Colonnes : ID, Fournisseur, Statut (avec tags), Montant, ID paiement fournisseur, Nombre de commandes, Nombre d'adhésions, Nombre de participations, Date

#### Filtres
- Fournisseur, Statut, ID paiement fournisseur, Date de création

#### Show
- Attributs : ID, Fournisseur, Statut (avec tags), Montant, ID paiement fournisseur, Devise, Dates
- **Panel Orders** : Tableau avec ID (lien), Utilisateur, Total, Statut, Date
- **Panel Memberships** : Tableau avec ID (lien), Utilisateur, Type, Statut, Date
- **Panel Attendances** : Tableau avec ID (lien), Utilisateur, Événement (lien), Statut, Date

#### Form
- Champs : Fournisseur, Statut (select), Montant (cents), ID paiement fournisseur, Devise

---

## 📅 Événements

### Randos (Events)

**Fichier** : `app/admin/events.rb`  
**Menu** : Parent "Événements", priorité 1

#### Index
- Colonnes : ID, Titre, Statut (avec tags), Date de début, Durée, Participants max, Nombre d'inscriptions, Liste d'attente, Parcours, Créateur, Prix
- **Scopes** : Tous, À venir, Publiés, En attente de validation, Refusés, Annulés
- Filtre pour exclure les initiations (STI)

#### Filtres
- Titre, Statut (select), Parcours, Créateur (select), Date de début, Date de création

#### Show
- Attributs : Titre, Statut, Date de début, Durée, Participants max, Nombre d'inscriptions, Places restantes, Créateur, Parcours, Prix, Devise, Lieu, Coordonnées GPS, Image de couverture, Description, Dates
- **Panel Inscriptions** : Tableau avec Participant (email ou nom enfant), Statut, Paiement, Date
- **Panel Liste d'attente** :
  - Colonnes : Position, Personne, Statut, Notifié le, Créé le, Actions
  - Actions : Convertir en inscription, Notifier maintenant (selon statut)

#### Form
- **Informations générales** : Titre, Statut (select), Parcours, Créateur (select), Date de début (datetime), Durée, Participants max (0 = illimité), Niveau (select), Distance (km), Lieu, Description
- **Tarification** : Prix (cents), Devise
- **Point de rendez-vous** : Latitude, Longitude, Image de couverture (upload)

#### Actions personnalisées
- Routes pour liste d'attente : `convert_waitlist`, `notify_waitlist` (member actions)

---

### Initiations

**Fichier** : `app/admin/event/initiations.rb`  
**Menu** : Parent "Événements", priorité 2

#### Index
- Colonnes : ID, Titre, Date de début, Statut (avec tags), Places (disponibles/max), Participants, Bénévoles, Liste d'attente, Créateur
- **Scopes** : Tous, À venir, Publiées, Annulées
- Filtre pour n'afficher que les initiations (type: "Event::Initiation")

#### Filtres
- Titre, Statut (select), Date de début, Créateur (select), Date de création

#### Show
- Attributs : ID, Titre, Statut, Date de début, Durée, Participants max, Places disponibles, Participants (avec détail), Bénévoles, Créateur, Lieu, Coordonnées GPS, Description, Dates
- **Panel Bénévoles encadrants** :
  - Tableau avec Bénévole (email ou nom enfant), Statut, Actions (Retirer bénévole), Matériel demandé, Date
- **Panel Participants** :
  - Tableau avec Participant, Statut, Essai gratuit, Actions (Ajouter bénévole), Matériel demandé, Date
- **Panel Liste d'attente** :
  - Colonnes : Position, Personne, Statut, Notifié le, Créé le, Actions
  - Actions : Convertir en inscription, Notifier maintenant

#### Form
- **Informations générales** : Titre, Statut (select), Créateur (select), Date de début (datetime, hint: samedi 10h15), Durée (défaut: 105 min), Participants max (défaut: 30), Description
- **Lieu** : Lieu (défaut: Gymnase Ampère), Latitude (défaut: 45.1891), Longitude (défaut: 5.7317)

#### Actions personnalisées
- `convert_waitlist` (POST) : Convertir une entrée de liste d'attente en inscription
- `notify_waitlist` (POST) : Notifier manuellement une personne en liste d'attente
- `presences` (GET) : Dashboard de gestion des présences
  - **Vue personnalisée** : `app/views/admin/event/initiations/presences.html.erb`
  - Formulaire de pointage avec sections Bénévoles et Participants
  - Radio buttons pour présence (Présent/Absent/Non pointé)
  - Checkboxes pour statut bénévole
  - Statistiques (Participants, Bénévoles, Places disponibles, Présents pointés)
- `update_presences` (PATCH) : Mise à jour en masse des présences
- `toggle_volunteer` (PATCH) : Basculer le statut bénévole d'une participation

---

### Participations (Attendances)

**Fichier** : `app/admin/attendances.rb`  
**Menu** : Parent "Événements", priorité 4

#### Index
- Colonnes : ID, Utilisateur, Événement, Statut, Paiement, ID client Stripe, Date
- **Scopes** : Tous, Actives, Annulées

#### Filtres
- Utilisateur (select), Événement, Statut (select), Paiement, Bénévole, Essai gratuit utilisé, Date de création

#### Show
- Attributs : ID, Utilisateur, Événement, Statut, Bénévole, Essai gratuit utilisé, Souhaite rappel, Besoin matériel, Taille rollers (si besoin matériel), Note équipement, Paiement, ID client Stripe, Dates

#### Form
- Champs : Utilisateur (select), Événement, Statut (select), Bénévole, Essai gratuit utilisé, Souhaite rappel, Besoin matériel, Taille rollers (select depuis RollerStock), Note équipement, Paiement, ID client Stripe

---

### Parcours (Routes)

**Fichier** : `app/admin/routes.rb`  
**Menu** : Parent "Événements", priorité 3

#### Index
- Colonnes : ID, Nom, Difficulté (avec tag), Distance (km), Dénivelé (m), Date de mise à jour
- **Scopes** : Tous, Faciles, Intermédiaires, Difficiles

#### Filtres
- Nom, Difficulté (select), Distance, Dénivelé, Date de création

#### Show
- Attributs : Nom, Difficulté, Distance, Dénivelé, URL GPX, Image carte (upload ou URL), Description, Notes sécurité, Dates
- **Panel Événements associés** : Tableau avec Titre, Statut, Date de début, Créateur

#### Form
- Champs : Nom, Difficulté (select), Distance (km), Dénivelé (m), URL GPX, Image carte (upload ou URL), Description, Notes sécurité

---

## 👥 Utilisateurs (suite)

### Candidatures Organisateur

**Fichier** : `app/admin/organizer_applications.rb`  
**Menu** : Parent "Utilisateurs", priorité 4

#### Index
- Colonnes : ID, Utilisateur, Statut, Revisé par, Date de révision, Date de création
- **Scopes** : Tous, En attente, Approuvées, Refusées

#### Filtres
- Utilisateur (select), Statut (select), Revisé par (select), Date de création

#### Show
- Attributs : ID, Utilisateur, Statut, Motivation, Revisé par, Date de révision, Dates

#### Form
- Champs : Utilisateur (select), Statut (select), Motivation, Revisé par (select), Date de révision (datetime)

#### Actions personnalisées
- **Action items** : Boutons "Approuver" et "Refuser" (visibles uniquement si statut = pending)
- `approve` (PUT) : Approuve la candidature, définit reviewed_by et reviewed_at
- `reject` (PUT) : Refuse la candidature, définit reviewed_by et reviewed_at

---

### Adhésions

**Fichier** : `app/admin/memberships.rb`  
**Menu** : Parent "Utilisateurs", priorité 3

#### Index
- Colonnes : ID, Utilisateur, Type (Personnelle/Enfant), Catégorie (Standard/FFRS), Statut (avec tags), Saison, Montant total, Dates (début → fin), Nom enfant (si enfant), Paiement, Date de création
- **Scopes** : Tous, Actives, En attente, Expirées, Personnelles, Enfants, Expirent bientôt

#### Filtres
- Utilisateur, Statut (select), Catégorie (select), Type (Personnelle/Enfant), Saison, Dates de début/fin, Date de création

#### Show
- Attributs : Utilisateur, Type, Catégorie, Statut, Saison, Dates, Montant, Montant total, Devise, Paiement, Variante T-shirt, Prix T-shirt
- **Panel Informations enfant** (si adhésion enfant) : Prénom, Nom, Nom complet, Date de naissance, Âge, Informations parent (nom, email, téléphone), Autorisation parentale, Date autorisation
- **Panel Questionnaire de santé** : Statut questionnaire, Certificat médical (lien de téléchargement)
- **Panel Consentements** : RGPD, Mentions légales acceptées, Partage données FFRS
- **Comments Active Admin** : Activés

#### Form
- **Adhésion** : Utilisateur (select), Catégorie (select), Statut (select), Saison, Dates (date picker), Montant (cents), Devise, Adhésion enfant (checkbox), Paiement
- **Informations enfant** : Prénom, Nom, Date de naissance, Informations parent (nom, email, téléphone), Autorisation parentale, Date autorisation
- **Options** : Variante T-shirt, Prix T-shirt (cents)

#### Actions personnalisées
- `activate` (PUT) : Active une adhésion en statut "pending"

---

## 📧 Communication

### Messages de contact

**Fichier** : `app/admin/contact_messages.rb`  
**Menu** : Parent "Communication", priorité 1

#### Index
- Colonnes : ID, Nom, Email, Sujet, Date de création
- **Actions** : Voir, Supprimer, **Répondre** (lien mailto avec sujet pré-rempli)
- **Actions désactivées** : Créer, Modifier

#### Filtres
- Nom, Email, Sujet, Date de création

#### Show
- Attributs : ID, Nom, Email (lien mailto), Sujet, Message (formaté), Dates

---

### Partenaires

**Fichier** : `app/admin/partners.rb`  
**Menu** : Parent "Communication", priorité 2

#### Index
- Colonnes : ID, Nom, URL (lien externe), Actif/Inactif, Date de mise à jour
- **Scopes** : Tous, Actifs, Inactifs

#### Filtres
- Nom, Actif, Date de création

#### Show
- Attributs : ID, Nom, URL (lien externe), Logo (image depuis URL), Description (formatée), Statut actif, Dates

#### Form
- Champs : Nom, URL, URL logo, Description, Actif

---

## 🔧 Matériel

### Stock Rollers

**Fichier** : `app/admin/roller_stocks.rb`  
**Menu** : Parent "Matériel", priorité 15

#### Index
- Colonnes : ID, Taille (EU), Quantité (avec alertes), Actif/Inactif, Dates

#### Filtres
- Taille, Quantité, Actif (boolean), Dates

#### Show
- Attributs : ID, Taille (EU), Quantité (avec alertes), Statut actif, Dates
- **Panel Demandes en attente** : Tableau avec Participant, Événement (lien), Date, Statut (pour les participations avec besoin matériel)

#### Form
- Champs : Taille (select depuis SIZES), Quantité, Actif (boolean avec hint)

#### Actions personnalisées
- `create` : Override pour gestion personnalisée

---

## 🔍 Système

### Logs d'audit

**Fichier** : `app/admin/audit_logs.rb`  
**Menu** : Parent "Système", priorité 1

#### Index
- Colonnes : ID, Date de création, Utilisateur acteur, Action (tag), Type cible, ID cible, Métadonnées (JSON tronqué à 80 caractères)
- **Tri par défaut** : Date de création (desc)
- **Actions** : Voir uniquement (pas de modification/suppression)

#### Filtres
- Action, Utilisateur acteur (select), Type cible, ID cible, Date de création

#### Show
- Attributs : ID, Dates, Utilisateur acteur, Action (tag), Type cible, ID cible, Métadonnées (JSON formaté avec `pre`)

---

## 📝 Pages personnalisées

### Page "Événements" (Menu parent)

**Fichier** : `app/admin/evenements.rb`

- Page de menu parent pour regrouper les ressources liées aux événements
- Contenu simple avec description

---

## 🎨 Fonctionnalités récurrentes utilisées

### Index
- ✅ Colonne sélectionnable (selectable_column)
- ✅ Colonne ID (id_column)
- ✅ Colonnes personnalisées avec formatage
- ✅ Status tags colorés (ok, warning, error)
- ✅ Liens vers autres ressources
- ✅ Formatage monétaire (number_to_currency)
- ✅ Formatage de dates
- ✅ Scopes personnalisés avec filtres

### Filtres
- ✅ Filtres texte
- ✅ Filtres select (avec collections)
- ✅ Filtres boolean
- ✅ Filtres de dates
- ✅ Filtres sur associations (avec collections personnalisées)
- ✅ Filtres sur attributs calculés

### Show
- ✅ Attributes tables groupées par sections
- ✅ Panels avec tableaux associés
- ✅ Images (upload Active Storage ou URL)
- ✅ Formatage de texte (simple_format)
- ✅ Status tags
- ✅ Liens vers ressources associées
- ✅ JSON formaté (pour métadonnées)

### Form
- ✅ Semantic errors
- ✅ Inputs groupés par sections
- ✅ Hints pour guider l'utilisateur
- ✅ Select avec collections personnalisées
- ✅ Date picker
- ✅ Datetime select
- ✅ Checkboxes
- ✅ File upload (Active Storage)
- ✅ Gestion des champs conditionnels (password optionnel si existant)

### Actions personnalisées
- ✅ Member actions (sur une ressource spécifique)
- ✅ Collection actions (sur la collection)
- ✅ Action items (boutons dans la page show)
- ✅ Override des méthodes controller (create, update, destroy)

### Autres
- ✅ Includes pour optimiser les requêtes N+1
- ✅ Permit params pour sécurité
- ✅ Autorisation Pundit dans les controllers
- ✅ Messages de succès/erreur personnalisés
- ✅ Redirections personnalisées après actions
- ✅ Vues personnalisées (ERB) pour actions spécifiques

---

## 📊 Statistiques d'utilisation

### Répartition par catégorie
- **Utilisateurs** : 3 ressources (Users, Roles, OrganizerApplications, Memberships)
- **Boutique** : 6 ressources (Products, Categories, Variants, OptionTypes, OptionValues, VariantOptionValues)
- **Commandes** : 3 ressources (Orders, OrderItems, Payments)
- **Événements** : 4 ressources (Events, Initiations, Attendances, Routes)
- **Communication** : 2 ressources (ContactMessages, Partners)
- **Matériel** : 1 ressource (RollerStocks)
- **Système** : 1 ressource (AuditLogs)
- **Pages personnalisées** : 2 (Dashboard, Maintenance)

### Complexité des ressources
- **Simple** (CRUD basique) : Roles, ProductCategories, OptionTypes, OptionValues, VariantOptionValues, ContactMessages, Partners, RollerStocks
- **Moyenne** (avec relations) : Users, Products, ProductVariants, Orders, OrderItems, Payments, Routes, Attendances
- **Complexe** (avec actions personnalisées) : Events, Initiations, OrganizerApplications, Memberships, Dashboard, Maintenance

---

## 🔄 Actions personnalisées détaillées

### OrganizerApplications
- `approve` (PUT) : Approuve une candidature
- `reject` (PUT) : Refuse une candidature
- Action items conditionnels (si pending)

### Memberships
- `activate` (PUT) : Active une adhésion en attente

### Events
- `convert_waitlist` (POST) : Convertit une entrée de liste d'attente en inscription
- `notify_waitlist` (POST) : Notifie manuellement une personne en liste d'attente

### Initiations
- `convert_waitlist` (POST) : Convertit une entrée de liste d'attente en inscription
- `notify_waitlist` (POST) : Notifie manuellement une personne en liste d'attente
- `presences` (GET) : Dashboard de gestion des présences
- `update_presences` (PATCH) : Mise à jour en masse des présences
- `toggle_volunteer` (PATCH) : Basculer le statut bénévole

### Maintenance
- `toggle` (PATCH) : Active/désactive le mode maintenance
- **Controller personnalisé** : `Admin::MaintenanceToggleController`

---

## 🎯 Points d'attention pour la migration

### Fonctionnalités critiques
1. **Dashboard** : Statistiques en temps réel avec liens vers les ressources
2. **Gestion des événements** : Actions complexes sur liste d'attente, présences, bénévoles
3. **Gestion des adhésions** : Panels multiples (enfant, santé, consentements)
4. **Maintenance mode** : Toggle avec restrictions d'accès
5. **Filtres avancés** : Filtres sur associations, collections personnalisées
6. **Formatage** : Monnaie, dates, status tags, images
7. **Autorisation** : Pundit avec policies par ressource

### Données à migrer
- Aucune migration de données nécessaire (Active Admin n'a pas de tables propres, sauf `active_admin_comments`)

### Routes à recréer
- Toutes les routes `/activeadmin/*` devront être recréées
- Routes personnalisées pour les member actions

---

## 📚 Ressources externes

- [Documentation Active Admin](https://activeadmin.info/)
- [Pundit](https://github.com/varvet/pundit)
- [Devise](https://github.com/heartcombo/devise)

---

**Note** : Ce document doit être mis à jour si de nouvelles fonctionnalités Active Admin sont ajoutées avant la migration.
