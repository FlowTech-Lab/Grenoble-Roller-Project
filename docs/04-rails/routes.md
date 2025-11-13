# Routes de l’application (Rails 8)

Ce document liste les routes disponibles et les flux principaux. Basé sur `config/routes.rb` à la date actuelle.

## Résumé
- Santé: `GET /up` (Rails health check)
- Accueil: `GET /` → `PagesController#index`
- Association: `GET /association` → `PagesController#association`
- Boutique: `GET /products`, `GET /products/:id` (slug ou id), alias `GET /shop`
- Événements: `GET /events`, `GET /events/:id`, `GET /events/new`, `POST /events`, `PATCH/PUT /events/:id`, `DELETE /events/:id`
- Panier (singulier): `GET /cart`, `POST /cart/add_item`, `PATCH /cart/update_item`, `DELETE /cart/remove_item`, `DELETE /cart/clear`
- Commandes: `GET /orders`, `GET /orders/new`, `POST /orders`, `GET /orders/:id`, `PATCH /orders/:id/cancel`
- Authentification: `devise_for :users` (routes Devise standard + `PasswordsController` personnalisé)

## Détail

### Pages statiques
- `GET /` → `pages#index`
- `GET /association` → `pages#association`

### Produits (catalogue)
- `GET /products` → `products#index`
- `GET /products/:id` → `products#show`
  - `:id` accepte un `slug` (préféré) ou un id numérique
- Alias boutique: `GET /shop` → `products#index`

### Panier (resource singulier)
- `GET    /cart` → `carts#show`
- `POST   /cart/add_item` → `carts#add_item`
- `PATCH  /cart/update_item` → `carts#update_item`
- `DELETE /cart/remove_item` → `carts#remove_item`
- `DELETE /cart/clear` → `carts#clear`

### Commandes
- `GET   /orders` → `orders#index`
- `GET   /orders/new` → `orders#new`
- `POST  /orders` → `orders#create`
- `GET   /orders/:id` → `orders#show`
- `PATCH /orders/:id/cancel` → `orders#cancel` (membre)
  - Protégé par `authenticate_user!`

### Événements (Phase 2)
- `GET    /events` → `events#index`
- `GET    /events/new` → `events#new`
- `POST   /events` → `events#create`
- `GET    /events/:id` → `events#show`
- `GET    /events/:id/edit` → `events#edit`
- `PATCH  /events/:id` → `events#update`
- `PUT    /events/:id` → `events#update`
- `DELETE /events/:id` → `events#destroy`
  - `index`/`show` publics (seuls les événements publiés hors organisateurs)
  - Création/édition réservées aux rôles `ORGANIZER+` (Pundit)

### Authentification (Devise)
- `devise_for :users, controllers: { passwords: 'passwords' }`
  - routes standard: `/users/sign_in`, `/users/sign_out`, `/users/password`, etc.

### Santé
- `GET /up` → `rails/health#show` (200/500)

## Flux principaux

- Parcours d’achat
  1. `GET /products` → choisir un produit et variantes
  2. `POST /cart/add_item` → ajouter une variante
  3. `GET /cart` → visualiser le panier
  4. `GET /orders/new` → checkout (auth requis)
  5. `POST /orders` → créer la commande (décrémente les stocks)

- Annulation de commande
  1. `PATCH /orders/:id/cancel` → annule si statut autorisé, restaure le stock

- Authentification
  - `GET /users/sign_in` → login via Devise

## Notes
- Administration back-office: `ActiveAdmin.routes(self)` expose `/admin/*` (accès restreint via Devise + Pundit).
- Les contrôleurs utilisent `includes` pour éviter les N+1 (ex: produits/variantes/options).
