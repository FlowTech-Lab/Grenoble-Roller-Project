# 🎯 Prompt Perplexity : Architecture Produits & Boutique - Panel Admin

**Objectif** : Obtenir la meilleure architecture pour gérer les produits et la boutique dans le nouveau panel admin Rails, en tenant compte de l'existant et des besoins spécifiques.

---

## 📋 CONTEXTE PROJET

**Application** : Grenoble Roller - Plateforme communautaire avec e-boutique  
**Stack** : Rails 8.1.1, Bootstrap 5.3.2, Stimulus, PostgreSQL 16, Pundit  
**Migration** : Remplacer Active Admin par un panel admin moderne et maintenable

### Modèles Existants

**Product**
- `belongs_to :category` (ProductCategory)
- `has_many :product_variants`
- Champs : `name`, `slug`, `description`, `price_cents`, `currency`, `stock_qty`, `is_active`
- `has_one_attached :image` (Active Storage) ou `image_url` (transition)
- **Important** : Le stock réel est géré au niveau des **variantes**, pas du produit

**ProductCategory**
- Catégories (ex: "Rollers", "Protections", "Accessoires")
- `has_many :products`

**ProductVariant**
- `belongs_to :product`
- `has_many :variant_option_values` → `has_many :option_values` (couleur, taille)
- Champs : `sku`, `price_cents`, `currency`, `stock_qty`, `is_active`
- `has_one_attached :image` (Active Storage) ou `image_url`
- **Important** : C'est ici que se trouve le vrai stock

**Order**
- Statuts : `pending`, `paid`, `preparation`, `shipped`, `cancelled`, `refund_requested`, `refunded`, `failed`
- `belongs_to :user`
- `has_many :order_items`
- Callbacks : restauration stock si annulée, notifications email

**OrderItem**
- `belongs_to :order`
- `belongs_to :variant` (ProductVariant)
- Quantité commandée

### Active Admin Actuel

Le fichier `app/admin/products.rb` gère :
- CRUD produits avec filtres et scopes (actifs, inactifs, en stock, rupture)
- Affichage des variantes dans un panel avec création/édition inline
- Gestion des images (upload ou URL)
- **Avertissement** : Le stock du produit est décoratif, le vrai stock est dans les variantes

### Nouveau Panel Admin

**Existant** :
- Controller `app/controllers/admin/products_controller.rb` avec Pundit
- Pas de vues encore
- Structure Bootstrap + Stimulus déjà décidée

---

## 🎯 BESOINS IDENTIFIÉS

### Gestion Produits

1. **Liste des produits** :
   - Tableau avec colonnes : Nom, Catégorie, Prix, Stock (agrégé des variantes), Statut (actif/inactif), Image
   - Filtres : Catégorie, Statut, Nom (recherche), Stock (en stock/rupture)
   - Scopes : Tous, Actifs, Inactifs, En stock, En rupture
   - Actions : Créer, Voir, Modifier, Supprimer

2. **Création/Édition produit** :
   - Formulaire avec tabs suggéré : "Informations", "Variantes", "Images"
   - Champs : Catégorie, Nom, Slug (auto-généré ?), Description, Prix de base, Devise, Statut actif/inactif
   - **Gestion variantes** : Liste des variantes avec création/édition inline ou modal
   - **Gestion images** : Upload Active Storage ou URL (transition)
   - **Validation** : Slug unique, image requise (upload ou URL), nom max 140 caractères

3. **Vue détail produit** :
   - Informations complètes
   - Liste des variantes avec SKU, options (couleur/taille), prix, stock, statut
   - Actions : Créer variante, Modifier variante, Supprimer variante
   - Images du produit

### Gestion Variantes

1. **Liste variantes d'un produit** :
   - Tableau avec : SKU, Options (couleur/taille), Prix, Stock, Statut
   - Filtres : Actif/Inactif, En stock/Rupture
   - Actions : Créer, Modifier, Supprimer

2. **Création/Édition variante** :
   - Formulaire avec : SKU (unique), Prix, Stock, Options (couleur/taille via OptionValues), Statut, Image
   - **Important** : Validation SKU unique, image requise

### Gestion Commandes (Orders)

1. **Liste des commandes** :
   - Tableau avec : ID, Utilisateur, Date, Statut, Total, Nombre articles
   - Filtres : Statut, Date, Utilisateur
   - Scopes : Tous, En attente, Payées, En préparation, Expédiées, Annulées

2. **Vue détail commande** :
   - Informations client
   - Liste des articles (variante, quantité, prix unitaire, total ligne)
   - Statut avec changement possible
   - Actions : Changer statut, Voir paiement, Exporter facture

3. **Gestion statuts** :
   - Workflow : pending → paid → preparation → shipped
   - Actions spéciales : Annuler, Demander remboursement, Confirmer remboursement
   - **Callbacks** : Restauration stock si annulée, notifications email

### Gestion Catégories

1. **CRUD simple** : Liste, Créer, Modifier, Supprimer
2. **Champs** : Nom, Slug (unique)
3. **Validation** : Impossible de supprimer si produits associés

---

## ❓ QUESTIONS POUR PERPLEXITY

### Architecture & Organisation

1. **Structure des vues** :
   - Faut-il créer des partials réutilisables pour les formulaires produits/variantes ?
   - Comment organiser les vues : `app/views/admin/products/` avec sous-dossiers ?
   - Faut-il des composants Stimulus pour la gestion des variantes inline ?

2. **Formulaires complexes** :
   - Comment gérer un formulaire produit avec ses variantes (nested forms) ?
   - Bootstrap tabs vs sections séparées pour organiser le formulaire produit ?
   - Comment gérer la création/édition de variantes depuis la vue produit ?

3. **Gestion des images** :
   - Upload Active Storage avec prévisualisation : Stimulus controller dédié ?
   - Comment gérer la transition image_url → Active Storage ?
   - Prévisualisation multiple pour variantes ?

4. **Stock agrégé** :
   - Comment calculer et afficher le stock total d'un produit (somme des variantes actives) ?
   - Faut-il un scope ou méthode helper ?
   - Comment mettre à jour ce calcul efficacement ?

5. **Validation et UX** :
   - Validation hybride (client Stimulus + serveur Rails) pour les formulaires produits/variantes ?
   - Messages d'erreur inline avec Bootstrap `is-invalid` / `invalid-feedback` ?
   - Comment gérer les validations croisées (ex: variante avec même SKU, produit sans variantes actives) ?

6. **Performance** :
   - Eager loading des associations (variantes, catégories, images) ?
   - Pagination avec Kaminari ou pagy pour les listes ?
   - Comment optimiser les requêtes pour le stock agrégé ?

7. **Actions batch** :
   - Sélection multiple pour activer/désactiver plusieurs produits ?
   - Export CSV des produits avec variantes ?
   - Import CSV pour création massive ?

8. **Relations complexes** :
   - Comment afficher efficacement les variantes avec leurs options (couleur/taille) ?
   - Gestion des OptionValues dans le formulaire variante (select multiple ?) ?
   - Comment pré-remplir les options disponibles selon le produit ?

9. **Workflow commandes** :
   - Comment gérer le changement de statut avec Stimulus (dropdown ou modal confirmation) ?
   - Comment afficher l'historique des changements de statut ?
   - Gestion des transitions invalides (ex: shipped → pending) ?

10. **Réutilisation Active Admin** :
    - Quels éléments de la logique Active Admin peut-on réutiliser ?
    - Comment migrer les scopes et filtres existants ?
    - Compatibilité avec les permissions Pundit existantes ?

---

## 📝 CONTRAINTES TECHNIQUES

### Stack Confirmée
- **Framework** : Rails 8.1.1 (pas de View Components, utiliser Partials)
- **CSS** : Bootstrap 5.3.2 (pas Tailwind)
- **JS** : Stimulus (pas React)
- **Autorisations** : Pundit (déjà configuré)
- **Base de données** : PostgreSQL 16 (JSONB disponible)
- **Images** : Active Storage (transition depuis image_url)

### Patterns à Suivre

1. **Partials Rails** : Créer des partials réutilisables (`_form.html.erb`, `_product_row.html.erb`)
2. **Stimulus Controllers** : Un controller par fonctionnalité interactive (ex: `image_upload_controller.js`, `variant_form_controller.js`)
3. **Classes Bootstrap** : Utiliser les classes existantes (`card-liquid`, `btn-liquid-primary`, etc.)
4. **Validation hybride** : Stimulus pour feedback immédiat, Rails pour source de vérité
5. **Dark mode** : Hériter automatiquement (déjà implémenté)

### Bonnes Pratiques

- MVP progressif : Fonctionnalités de base d'abord, améliorations ensuite
- Réutilisation maximale : Pas de nouvelles dépendances inutiles
- Accessibilité : WCAG 2.1 AA minimum
- Performance : Optimiser dès le début (eager loading, pagination)

---

## 🎯 RÉSULTAT ATTENDU

**Livrable souhaité** :

1. **Architecture recommandée** :
   - Structure des controllers (méthodes, callbacks, scopes)
   - Organisation des vues (partials, layouts)
   - Stimulus controllers nécessaires
   - Helpers et services si besoin

2. **Formulaires détaillés** :
   - Structure HTML Bootstrap pour formulaire produit avec tabs
   - Gestion des variantes (nested forms ou approche séparée)
   - Validation client/serveur
   - Upload images avec prévisualisation

3. **Listes et tableaux** :
   - Structure tableau Bootstrap pour produits/commandes
   - Filtres et scopes
   - Pagination
   - Actions batch

4. **Gestion stock** :
   - Calcul stock agrégé (méthode helper ou scope)
   - Affichage dans les listes
   - Indicateurs visuels (badges Bootstrap)

5. **Code d'exemple** :
   - Exemple de controller avec scopes et filtres
   - Exemple de vue index avec tableau Bootstrap
   - Exemple de formulaire avec tabs
   - Exemple Stimulus controller pour variantes

6. **Workflow commandes** :
   - Gestion changement statut
   - Transitions valides/invalides
   - Callbacks et notifications

7. **Migration Active Admin** :
   - Équivalences des scopes Active Admin → Nouveau panel
   - Migration des filtres
   - Compatibilité permissions Pundit

---

## 📚 RÉFÉRENCES EXISTANTES

### Codebase Actuel
- `app/admin/products.rb` : Configuration Active Admin produits
- `app/controllers/admin/products_controller.rb` : Controller nouveau panel (début)
- `app/models/product.rb` : Modèle avec validations
- `app/models/product_variant.rb` : Modèle variante
- `app/models/order.rb` : Modèle commande avec callbacks

### Documentation Projet
- `docs/admin/ressources/references/reference-css-classes.md` : Classes CSS disponibles
- `docs/admin/ressources/decisions/form-validation-guide.md` : Guide validation hybride
- `docs/admin/ressources/guides/guide-ux-ui.md` : Guide UX/UI
- `docs/admin/START_HERE.md` : Guide démarrage

---

**Format réponse souhaité** : Guide complet avec code, exemples Bootstrap, et explications détaillées étape par étape.
