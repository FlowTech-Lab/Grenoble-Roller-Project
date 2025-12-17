# Migration Complète - Toutes les Ressources Active Admin

**Objectif** : Liste exhaustive de TOUTES les ressources Active Admin à migrer vers le nouveau panel admin  
**Source** : [inventaire-active-admin.md](inventaire-active-admin.md)

---

## 📊 Vue d'Ensemble

**Total à migrer** : **24 ressources** + **2 pages personnalisées** = **26 éléments**

---

## ✅ Checklist Migration par Ressource

### Pages Personnalisées (2)

#### 1. Dashboard
- [ ] **Statistiques principales** (8 cartes avec liens)
- [ ] **Section Événements à valider** (liste 10 derniers + tableau)
- [ ] **Section Statistiques Boutique** (KPIs + 5 dernières commandes)
- [ ] **Section Statistiques Adhésions** (KPIs + 5 dernières adhésions)
- [ ] **Section Accès rapide** (liens ressources)
- **Guide** : Fonctionnalité déjà couverte par US-011 (Dashboard) + US-012 (Statistiques)

#### 2. Maintenance Mode
- [ ] **Affichage état actuel** (Actif/Inactif)
- [ ] **Bouton activation/désactivation**
- [ ] **Informations techniques** (Cache key, status, middleware)
- [ ] **Documentation intégrée**
- [ ] **Action toggle** (PATCH) - Controller existe déjà : `Admin::MaintenanceToggleController`
- **Note** : Controller existe déjà, besoin de vue admin uniquement

---

### Utilisateurs (4 ressources)

#### 3. Users
- [ ] **Index** : ID, Nom complet, Email, Rôle, Bénévole, Confirmé, Date création
- [ ] **Filtres** : Email, Email non confirmé, Prénom, Nom, Rôle, Bénévole, Dates
- [ ] **Show** : 
  - [ ] Infos personnelles + Adresse + Confirmation email (Devise)
  - [ ] Panel Inscriptions (tableau participations)
- [ ] **Form** :
  - [ ] Infos personnelles + Adresse + Authentification
  - [ ] Préférences + Bénévole + Avatar
- [ ] **Actions** : Destroy, Update (gestion spéciale password, can_be_volunteer)

#### 4. Roles
- [ ] **Index** : ID, Nom, Code, Niveau, Description, Dates
- [ ] **Filtres** : Nom, Code, Niveau, Utilisateur, Dates
- [ ] **Show** : Attributs + Panel Utilisateurs associés
- [ ] **Form** : Nom, Code, Niveau, Description

#### 5. OrganizerApplications
- [ ] **Index** : ID, Utilisateur, Statut, Revisé par, Date révision, Date création
- [ ] **Scopes** : Tous, En attente, Approuvées, Refusées
- [ ] **Filtres** : Utilisateur, Statut, Revisé par, Date création
- [ ] **Show** : Attributs (ID, Utilisateur, Statut, Motivation, etc.)
- [ ] **Form** : Utilisateur, Statut, Motivation, Revisé par, Date révision
- [ ] **Actions personnalisées** : `approve` (PUT), `reject` (PUT)
- [ ] **Action items conditionnels** : Boutons "Approuver" / "Refuser" (si pending)

#### 6. Memberships
- [ ] **Index** : ID, Utilisateur, Type, Catégorie, Statut, Saison, Montant, Dates, Nom enfant, Paiement
- [ ] **Scopes** : Tous, Actives, En attente, Expirées, Personnelles, Enfants, Expirent bientôt
- [ ] **Filtres** : Utilisateur, Statut, Catégorie, Type, Saison, Dates
- [ ] **Show** :
  - [ ] Attributs adhésion
  - [ ] Panel Informations enfant (si enfant)
  - [ ] Panel Questionnaire de santé
  - [ ] Panel Consentements
  - [ ] Comments Active Admin
- [ ] **Form** :
  - [ ] Adhésion (utilisateur, catégorie, statut, dates, montant, etc.)
  - [ ] Informations enfant (si enfant)
  - [ ] Options (T-shirt)
- [ ] **Actions personnalisées** : `activate` (PUT)

---

### Boutique (6 ressources)

#### 7. Products
- [ ] **Index** : ID, Nom, Catégorie, Slug, Actif/Inactif, Prix, Stock (alertes), Date création
- [ ] **Scopes** : Tous, Actifs, Inactifs, En rupture, En stock
- [ ] **Filtres** : Nom, Catégorie, Actif, Devise, Date création
- [ ] **Show** : Attributs + Panel Variantes (bouton créer + tableau)
- [ ] **Form** : Catégorie, Nom, Slug, Description, Prix, Devise, Stock, Actif, Image
- [ ] **Actions** : Destroy

#### 8. ProductCategories
- [ ] **Index** : ID, Nom, Slug, Nombre produits, Date création
- [ ] **Filtres** : Nom, Slug, Date création
- [ ] **Show** : Attributs + Panel Products
- [ ] **Form** : Nom, Slug

#### 9. ProductVariants
- [ ] **Index** : ID, Produit, SKU, Options (formatées), Prix, Stock (alertes), Statut, Date
- [ ] **Scopes** : Tous, Actives, Inactives, En rupture, En stock
- [ ] **Filtres** : Produit, SKU, Actif, Stock, Date création
- [ ] **Show** : Attributs (Produit, SKU, Options, Prix, Stock, Statut)
- [ ] **Form** : Produit, SKU, Prix, Devise, Stock, Actif + Options (checkboxes)

#### 10. OptionTypes
- [ ] **Index** : ID, Nom, Nombre valeurs, Date
- [ ] **Filtres** : Nom, Date création
- [ ] **Show** : Attributs + Panel Option Values
- [ ] **Form** : Nom

#### 11. OptionValues
- [ ] **Index** : ID, Valeur, Type option, Nombre variantes utilisant, Date
- [ ] **Filtres** : Type option, Valeur, Date création
- [ ] **Show** : Attributs + Panel Product Variants
- [ ] **Form** : Type option, Valeur

#### 12. VariantOptionValues
- [ ] **Index** : ID, Variante (SKU), Produit, Valeur option, Type option, Date
- [ ] **Filtres** : Variante, Valeur option, Date création
- [ ] **Show** : Attributs (liens vers ressources associées)
- [ ] **Form** : Variante, Valeur option

---

### Commandes (3 ressources)

#### 13. Orders
- [ ] **Index** : ID, Utilisateur, Statut (tags), Total, Paiement, Date
- [ ] **Scopes** : Tous, En attente, Complétées, Annulées
- [ ] **Filtres** : Utilisateur, Statut, Paiement, Date création
- [ ] **Show** : Attributs + Panel Articles
- [ ] **Form** : Utilisateur, Statut, Total, Don, Devise, Paiement

#### 14. OrderItems
- [ ] **Index** : ID, Commande, Variante (SKU), Produit, Quantité, Prix unitaire, Total calculé, Date
- [ ] **Filtres** : Commande, Variante, Quantité, Date création
- [ ] **Show** : Attributs (liens vers ressources)
- [ ] **Form** : Commande, Variante, Quantité, Prix unitaire

#### 15. Payments
- [ ] **Index** : ID, Fournisseur, Statut (tags), Montant, ID paiement fournisseur, Nombre commandes/adhésions/participations, Date
- [ ] **Filtres** : Fournisseur, Statut, ID paiement fournisseur, Date création
- [ ] **Show** : Attributs + Panel Orders + Panel Memberships + Panel Attendances
- [ ] **Form** : Fournisseur, Statut, Montant, ID paiement fournisseur, Devise

---

### Événements (4 ressources)

#### 16. Events (Randos)
- [ ] **Index** : ID, Titre, Statut (tags), Date début, Durée, Participants max, Inscriptions, Liste attente, Parcours, Créateur, Prix
- [ ] **Scopes** : Tous, À venir, Publiés, En attente validation, Refusés, Annulés
- [ ] **Filtres** : Titre, Statut, Parcours, Créateur, Date début, Date création
- [ ] **Filtre spécial** : Exclure initiations (STI)
- [ ] **Show** :
  - [ ] Attributs (titre, statut, dates, participants, créateur, parcours, prix, lieu, GPS, image, description)
  - [ ] Panel Inscriptions (tableau)
  - [ ] Panel Liste d'attente (position, personne, statut, actions)
- [ ] **Form** :
  - [ ] Infos générales (titre, statut, parcours, créateur, dates, durée, participants, niveau, distance, lieu, description)
  - [ ] Tarification (prix, devise)
  - [ ] Point rendez-vous (lat, lng, image)
- [ ] **Actions personnalisées** : `convert_waitlist` (POST), `notify_waitlist` (POST)

#### 17. Event::Initiations
- [ ] **Index** : ID, Titre, Date début, Statut (tags), Places (disponibles/max), Participants, Bénévoles, Liste attente, Créateur
- [ ] **Scopes** : Tous, À venir, Publiées, Annulées
- [ ] **Filtres** : Titre, Statut, Date début, Créateur, Date création
- [ ] **Filtre spécial** : Afficher uniquement initiations (type: "Event::Initiation")
- [ ] **Show** :
  - [ ] Attributs (ID, titre, statut, dates, participants, bénévoles, créateur, lieu, GPS, description)
  - [ ] Panel Bénévoles encadrants (tableau avec actions)
  - [ ] Panel Participants (tableau avec actions)
  - [ ] Panel Liste d'attente (position, personne, statut, actions)
- [ ] **Form** :
  - [ ] Infos générales (titre, statut, créateur, date début, durée, participants max, description)
  - [ ] Lieu (lieu, lat, lng avec valeurs par défaut)
- [ ] **Actions personnalisées** :
  - [ ] `convert_waitlist` (POST)
  - [ ] `notify_waitlist` (POST)
  - [ ] `presences` (GET) - Dashboard présences (vue personnalisée)
  - [ ] `update_presences` (PATCH) - Mise à jour masse présences
  - [ ] `toggle_volunteer` (PATCH) - Basculer statut bénévole

#### 18. Attendances (Participations)
- [ ] **Index** : ID, Utilisateur, Événement, Statut, Paiement, ID client Stripe, Date
- [ ] **Scopes** : Tous, Actives, Annulées
- [ ] **Filtres** : Utilisateur, Événement, Statut, Paiement, Bénévole, Essai gratuit, Date création
- [ ] **Show** : Attributs (ID, utilisateur, événement, statut, bénévole, essai gratuit, rappel, matériel, taille rollers, note équipement, paiement, Stripe)
- [ ] **Form** : Utilisateur, Événement, Statut, Bénévole, Essai gratuit, Rappel, Matériel, Taille rollers, Note équipement, Paiement, ID Stripe

#### 19. Routes (Parcours)
- [ ] **Index** : ID, Nom, Difficulté (tag), Distance (km), Dénivelé (m), Date mise à jour
- [ ] **Scopes** : Tous, Faciles, Intermédiaires, Difficiles
- [ ] **Filtres** : Nom, Difficulté, Distance, Dénivelé, Date création
- [ ] **Show** : Attributs + Panel Événements associés
- [ ] **Form** : Nom, Difficulté, Distance, Dénivelé, URL GPX, Image carte, Description, Notes sécurité

---

### Communication (2 ressources)

#### 20. ContactMessages
- [ ] **Index** : ID, Nom, Email, Sujet, Date création
- [ ] **Actions** : Voir, Supprimer, **Répondre** (mailto)
- [ ] **Actions désactivées** : Créer, Modifier
- [ ] **Filtres** : Nom, Email, Sujet, Date création
- [ ] **Show** : Attributs (ID, Nom, Email mailto, Sujet, Message formaté, Dates)

#### 21. Partners
- [ ] **Index** : ID, Nom, URL (lien externe), Actif/Inactif, Date mise à jour
- [ ] **Scopes** : Tous, Actifs, Inactifs
- [ ] **Filtres** : Nom, Actif, Date création
- [ ] **Show** : Attributs (ID, Nom, URL, Logo, Description formatée, Statut, Dates)
- [ ] **Form** : Nom, URL, URL logo, Description, Actif

---

### Matériel (1 ressource)

#### 22. RollerStocks
- [ ] **Index** : ID, Taille (EU), Quantité (alertes), Actif/Inactif, Dates
- [ ] **Filtres** : Taille, Quantité, Actif, Dates
- [ ] **Show** : Attributs + Panel Demandes en attente (participations avec besoin matériel)
- [ ] **Form** : Taille (select), Quantité, Actif
- [ ] **Actions personnalisées** : Create override

---

### Système (1 ressource)

#### 23. AuditLogs
- [ ] **Index** : ID, Date création, Utilisateur acteur, Action (tag), Type cible, ID cible, Métadonnées (JSON tronqué 80 caractères)
- [ ] **Tri par défaut** : Date création (desc)
- [ ] **Actions** : Voir uniquement (pas modifier/supprimer)
- [ ] **Filtres** : Action, Utilisateur acteur, Type cible, ID cible, Date création
- [ ] **Show** : Attributs (ID, Dates, Utilisateur acteur, Action tag, Type cible, ID cible, Métadonnées JSON formaté)

---

## 🎨 Fonctionnalités Récurrentes par Ressource

Chaque ressource nécessite généralement :

### Index (Liste)
- [ ] Colonnes personnalisées (voir inventaire pour chaque ressource)
- [ ] Colonne sélectionnable (checkbox) pour batch actions
- [ ] Colonne ID
- [ ] Status tags colorés (ok, warning, error)
- [ ] Liens vers autres ressources
- [ ] Formatage monétaire (`number_to_currency`)
- [ ] Formatage dates
- [ ] Scopes personnalisés avec filtres
- [ ] Tri par colonne
- [ ] Pagination

### Filtres
- [ ] Filtres texte
- [ ] Filtres select (avec collections)
- [ ] Filtres boolean
- [ ] Filtres dates
- [ ] Filtres associations (avec collections personnalisées)
- [ ] Filtres attributs calculés

### Show (Détail)
- [ ] Attributes tables groupées par sections
- [ ] Panels avec tableaux associés (relations)
- [ ] Images (upload Active Storage ou URL)
- [ ] Formatage texte (`simple_format`)
- [ ] Status tags
- [ ] Liens vers ressources associées
- [ ] JSON formaté (métadonnées)

### Form (Création/Édition)
- [ ] Semantic errors
- [ ] Inputs groupés par sections
- [ ] Hints pour guider utilisateur
- [ ] Select avec collections personnalisées
- [ ] Date picker
- [ ] Datetime select
- [ ] Checkboxes
- [ ] File upload (Active Storage)
- [ ] Champs conditionnels (ex: password optionnel si existant)
- [ ] Tabs (si plusieurs sections)

### Actions
- [ ] Member actions (sur ressource spécifique)
- [ ] Collection actions (sur collection)
- [ ] Action items (boutons dans page show)
- [ ] Override méthodes controller (create, update, destroy)

---

## 📋 Plan de Migration par Sprint

### Sprint 1-2 : Infrastructure + Dashboard (4 semaines)

**Ressources à migrer** :
- [ ] Dashboard (page personnalisée) - US-011, US-012
- [ ] Maintenance Mode (page personnalisée)

**Fonctionnalités techniques** :
- [ ] US-001, US-002, US-003 : Sidebar + Menu
- [ ] US-004 : Recherche globale
- [ ] US-005 : Breadcrumb
- [ ] US-006 : Raccourcis clavier

### Sprint 3-4 : Ressources Simples (4 semaines)

**Ressources à migrer** (CRUD basique) :
- [ ] Roles (simple)
- [ ] ProductCategories (simple)
- [ ] OptionTypes (simple)
- [ ] OptionValues (simple)
- [ ] VariantOptionValues (simple)
- [ ] ContactMessages (simple, actions limitées)
- [ ] Partners (simple)
- [ ] RollerStocks (simple)
- [ ] AuditLogs (simple, lecture seule)

**Fonctionnalités techniques** :
- [ ] US-007 : Drag-drop colonnes
- [ ] US-008 : Batch actions
- [ ] US-009 : Tri et filtres

### Sprint 5-6 : Ressources Moyennes (4 semaines)

**Ressources à migrer** (avec relations) :
- [ ] Users (moyenne, avec panel Inscriptions)
- [ ] Products (moyenne, avec panel Variantes)
- [ ] ProductVariants (moyenne, avec options)
- [ ] Orders (moyenne, avec panel Articles)
- [ ] OrderItems (moyenne)
- [ ] Payments (moyenne, avec 3 panels)
- [ ] Routes (moyenne, avec panel Événements)
- [ ] Attendances (moyenne)

**Fonctionnalités techniques** :
- [ ] US-010 : Boutons dynamiques
- [ ] US-013 : Formulaires avec tabs
- [ ] US-014 : Panels associés
- [ ] US-015 : Validation inline

### Sprint 7-8 : Ressources Complexes (4 semaines)

**Ressources à migrer** (avec actions personnalisées) :
- [ ] Events (complexe : liste attente, actions)
- [ ] Event::Initiations (très complexe : présences, bénévoles, liste attente)
- [ ] OrganizerApplications (complexe : approve/reject)
- [ ] Memberships (complexe : panels multiples, activate)

**Fonctionnalités techniques** :
- [ ] US-016 : Présences initiations (dashboard spécialisé)
- [ ] US-017 : Dark mode (déjà fait)
- [ ] US-018 : Accessibilité (itératif)

---

## 📊 Statistiques Migration

| Catégorie | Nombre | Sprint |
|-----------|--------|--------|
| **Pages personnalisées** | 2 | Sprint 1-2 |
| **Ressources simples** | 9 | Sprint 3-4 |
| **Ressources moyennes** | 8 | Sprint 5-6 |
| **Ressources complexes** | 4 | Sprint 7-8 |
| **TOTAL** | **24 ressources + 2 pages** | **8 sprints (16 semaines)** |

---

## ⚠️ Fonctionnalités Spécifiques à Ne Pas Oublier

### Actions Personnalisées

- [ ] **OrganizerApplications** : `approve`, `reject` (PUT)
- [ ] **Memberships** : `activate` (PUT)
- [ ] **Events** : `convert_waitlist`, `notify_waitlist` (POST)
- [ ] **Initiations** : `convert_waitlist`, `notify_waitlist`, `presences`, `update_presences`, `toggle_volunteer`
- [ ] **Maintenance** : `toggle` (PATCH) - Controller existe déjà

### Vues Personnalisées

- [ ] **Initiations** : `presences.html.erb` - Dashboard présences avec formulaire pointage

### Scopes Personnalisés

Chaque ressource avec scopes (Events, Initiations, Orders, Memberships, etc.) :
- [ ] Implémenter tous les scopes dans les controllers
- [ ] Filtres UI pour accéder aux scopes

### Panels Associés (Relations)

- [ ] Users → Panel Inscriptions
- [ ] Products → Panel Variantes
- [ ] ProductCategories → Panel Products
- [ ] OptionTypes → Panel Option Values
- [ ] OptionValues → Panel Product Variants
- [ ] Orders → Panel Articles
- [ ] Payments → Panel Orders + Memberships + Attendances
- [ ] Routes → Panel Événements
- [ ] RollerStocks → Panel Demandes en attente
- [ ] Roles → Panel Utilisateurs associés

---

## 🔗 Références

- **[inventaire-active-admin.md](inventaire-active-admin.md)** - Détails complets de chaque ressource
- **[plan-implementation.md](plan-implementation.md)** - Plan d'implémentation avec user stories techniques
- **[START_HERE.md](START_HERE.md)** - Guide de démarrage

---

**Dernière mise à jour** : 2025-01-27  
**Version** : 1.0
