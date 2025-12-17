# 🎯 Prompt Perplexity : Validation Base UX-UI Panel Admin

**Objectif** : Valider et finaliser la base UX-UI du panel admin, préparer la sidebar, et intégrer le dashboard accessible depuis la navbar.

---

## 📋 CONTEXTE PROJET

**Application** : Grenoble Roller - Plateforme communautaire  
**Stack** : Rails 8.1.1, Bootstrap 5.3.2, Stimulus, PostgreSQL 16, Pundit  
**Situation** : Active Admin existe actuellement, nouveau panel admin en développement (coexistence)

---

## ✅ CE QUI EXISTE DÉJÀ

### 1. Navbar Principale (`app/views/layouts/_navbar.html.erb`)

**Lien Active Admin actuel** (lignes 121-132) :
```erb
<% if current_user.role&.code.in?(%w[ADMIN SUPERADMIN]) %>
  <li>
    <%= link_to Rails.application.routes.url_helpers.activeadmin_root_path, class: "dropdown-item" do %>
      <i class="bi bi-shield-check me-2"></i>Administration
    <% end %>
  </li>
  <li>
    <%= link_to Rails.application.routes.url_helpers.activeadmin_root_path, class: "dropdown-item" do %>
      <i class="bi bi-gear me-2"></i>Active Admin
    <% end %>
  </li>
<% end %>
```

**Besoins** :
- Ajouter un nouveau lien "Nouveau Panel Admin" ou remplacer "Administration" par ce nouveau panel
- Garder "Active Admin" pour coexistence temporaire
- Le lien doit pointer vers `/admin/dashboard` (nouveau panel)

### 2. Sidebar Admin (`app/views/admin/shared/_sidebar.html.erb`)

**Existe déjà** avec :
- Structure complète (desktop/mobile)
- Menu hiérarchique (Utilisateurs, Boutique, Commandes, Événements, etc.)
- Offcanvas pour mobile
- Classes Bootstrap utilisées
- Stimulus controller `admin-sidebar` référencé

**Structure** :
- Desktop : Sidebar fixe `d-none d-lg-flex` avec `width: 280px`
- Mobile : Offcanvas Bootstrap `offcanvas-start`
- Menu avec collapse Bootstrap pour submenus

**Contrôleur Stimulus référencé** : `admin-sidebar` (ligne 10) mais pas encore créé

### 3. Controllers Admin

**Existent** : Plusieurs controllers dans `app/controllers/admin/` :
- `users_controller.rb`
- `products_controller.rb`
- `orders_controller.rb`
- `routes_controller.rb`
- `payments_controller.rb`
- etc.

**Manque** :
- `Admin::DashboardController`
- `Admin::BaseController` (parent avec Pundit)

### 4. Layout Application (`app/views/layouts/application.html.erb`)

**Structure actuelle** :
- Navbar incluse : `<%= render 'layouts/navbar' %>`
- Dark mode déjà implémenté avec toggle dans navbar
- Fonction `toggleTheme()` dans le layout

**Manque** :
- Layout admin séparé (`layouts/admin.html.erb`)
- Layout admin doit inclure la sidebar

### 5. Routes (`config/routes.rb`)

**Existe** :
- `ActiveAdmin.routes(self)` (ligne 2)
- Routes Active Admin accessibles

**Manque** :
- Namespace admin pour nouveau panel
- Route `/admin` ou `/admin/dashboard`
- Routes admin pour dashboard

---

## 🎯 OBJECTIFS

### 1. Layout Admin avec Sidebar

**Besoins** :
- Créer `app/views/layouts/admin.html.erb`
- Layout qui hérite de `application.html.erb` OU layout indépendant ?
- Intégrer la sidebar existante (`_sidebar.html.erb`)
- Structure : Sidebar à gauche + Contenu principal à droite
- Responsive : Sidebar fixe desktop, offcanvas mobile

**Questions** :
- Le layout admin doit-il hériter de `application.html.erb` (navbar incluse) ?
- Ou layout complètement séparé (navbar spécifique admin) ?
- Comment gérer le dark mode dans le layout admin (hérite automatiquement) ?

### 2. Routes Admin

**Besoins** :
- Namespace `/admin` pour nouveau panel
- Route `/admin` → Dashboard (root du namespace)
- Coexistence avec Active Admin (`/activeadmin/*`)

**Routes à créer** :
```ruby
namespace :admin do
  root 'dashboard#index'  # /admin → dashboard
  # Routes futures pour autres ressources
end
```

**Questions** :
- Comment éviter conflit entre `/admin` (nouveau) et `/activeadmin` (ancien) ?
- Faut-il un préfixe différent ou garder `/admin` ?

### 3. Intégration Navbar

**Besoins** :
- Modifier le lien "Administration" dans dropdown utilisateur
- Lien vers `/admin/dashboard` au lieu de `/activeadmin`
- Garder "Active Admin" pour accès à l'ancien panel
- Ou renommer les liens pour clarifier

**Options** :
- Option A : "Nouveau Panel" → `/admin`, "Active Admin" → `/activeadmin`
- Option B : "Administration" → `/admin`, "Active Admin (Legacy)" → `/activeadmin`
- Option C : Un seul lien avec toggle/choix

### 4. BaseController Admin

**Besoins** :
- Controller parent `Admin::BaseController`
- Authentification admin (rôles ADMIN/SUPERADMIN)
- Pundit pour autorisations
- Layout admin par défaut

**Questions** :
- Quelle structure pour BaseController ?
- Comment gérer les autorisations (before_action) ?
- Layout admin automatique ou explicite ?

### 5. DashboardController

**Besoins** :
- Controller `Admin::DashboardController < BaseController`
- Méthode `index` qui prépare les données statistiques
- Vue `app/views/admin/dashboard/index.html.erb`

**Questions** :
- Quelles statistiques afficher en premier (MVP) ?
- Comment optimiser les requêtes (éviter N+1) ?
- Faut-il du caching pour les stats lourdes ?

### 6. Stimulus Controllers

**Besoins** :
- Controller `admin_sidebar_controller.js` pour gestion collapse/expand
- Persistence état collapsed dans localStorage
- Gestion responsive (desktop/mobile)

**Existe déjà** : Référence à `data-controller="admin-sidebar"` dans sidebar mais fichier JS manquant

**Questions** :
- Structure du controller Stimulus pour sidebar ?
- Comment gérer la transition desktop/mobile ?
- Persistence localStorage : clé et format ?

---

## 🎨 CONSIDÉRATIONS UX-UI

### 1. Navigation Double

**Problème** : Comment gérer navigation navbar principale + sidebar admin ?

**Options** :
- **Option A** : Layout admin masque navbar principale, sidebar seule
- **Option B** : Layout admin garde navbar principale (avec toggle dark mode), sidebar en plus
- **Option C** : Navbar admin spécifique (différente de navbar principale)

**Recommandation souhaitée** : Quelle option est la meilleure pour UX cohérente ?

### 2. Transition Active Admin → Nouveau Panel

**Besoin** : Coexistence temporaire pendant migration

**Questions** :
- Comment identifier visuellement qu'on est dans le nouveau panel vs Active Admin ?
- Faut-il un indicateur visuel (badge "Nouveau", etc.) ?
- Comment gérer les liens entre les deux panels si nécessaire ?

### 3. Responsive Sidebar

**Structure actuelle** :
- Desktop : Sidebar fixe 280px (expanded), 64px (collapsed)
- Mobile : Offcanvas Bootstrap

**Questions** :
- Breakpoint pour basculer desktop → mobile ?
- Comment gérer le toggle sur mobile (hamburger dans navbar admin ou fixe) ?
- Faut-il un topbar admin séparé pour mobile ?

### 4. Dark Mode dans Panel Admin

**Existe** : Dark mode dans layout principal avec `toggleTheme()` et `data-bs-theme`

**Questions** :
- Le layout admin hérite-t-il automatiquement du dark mode ?
- Faut-il un toggle dark mode dans la sidebar admin aussi ?
- Comment garantir cohérence entre navbar principale et panel admin ?

---

## 📝 CONTRAINTES TECHNIQUES

### Stack Confirmée
- **Framework** : Rails 8.1.1
- **CSS** : Bootstrap 5.3.2 (pas Tailwind)
- **JS** : Stimulus (pas React)
- **Autorisations** : Pundit (déjà configuré)
- **Base de données** : PostgreSQL 16

### Patterns à Suivre
- **Partials Rails** : Utiliser les partials existants
- **Classes Bootstrap** : Utiliser classes standards + Liquid custom
- **Dark mode** : Réutiliser le système existant
- **Stimulus** : Controllers dans `app/javascript/controllers/`

### Réutilisation Maximale
- **Sidebar** : Déjà créée (`_sidebar.html.erb`), adapter si besoin
- **Dark mode** : Déjà implémenté, hériter
- **Classes CSS** : Utiliser `card-liquid`, `btn-liquid-primary`, etc.
- **Bootstrap** : Toutes classes standards disponibles

---

## 🎯 RÉSULTAT ATTENDU

**Livrable souhaité** :

1. **Architecture Layout Admin Recommandée** :
   - Structure HTML du layout admin
   - Intégration sidebar existante
   - Gestion navbar principale vs navbar admin
   - Responsive (desktop/mobile)

2. **Routes Recommandées** :
   - Structure namespace admin
   - Routes dashboard
   - Coexistence avec Active Admin

3. **BaseController Recommandé** :
   - Structure avec Pundit
   - Authentification admin
   - Layout par défaut
   - Gestion erreurs/autorisations

4. **DashboardController Recommandé** :
   - Méthode index avec optimisations
   - Données statistiques préparées
   - Requêtes SQL optimisées

5. **Stimulus Sidebar Controller** :
   - Gestion collapse/expand
   - Persistence localStorage
   - Responsive (desktop/mobile)

6. **Modification Navbar** :
   - Lien vers nouveau panel admin
   - Coexistence avec Active Admin
   - Structure dropdown recommandée

7. **Code d'Exemple** :
   - Layout admin complet
   - BaseController avec Pundit
   - DashboardController
   - Stimulus controller sidebar
   - Modification navbar

---

## ❓ QUESTIONS SPÉCIFIQUES

1. **Layout Admin** : Hériter de `application.html.erb` ou layout séparé ? Avantages/inconvénients ?

2. **Navbar** : Garder navbar principale dans layout admin ou créer navbar admin spécifique ?

3. **Routes** : Préfixe `/admin` OK ou risque conflit avec Active Admin ? Alternative recommandée ?

4. **Sidebar Responsive** : Breakpoint Bootstrap pour basculer desktop → mobile ? (`d-lg-flex` vs `d-xl-flex` ?)

5. **Dark Mode** : Comment garantir héritage dans layout admin ? Faut-il action explicite ?

6. **Coexistence** : Comment gérer visuellement la transition Active Admin → Nouveau panel ?

7. **Autorisations** : Structure BaseController avec Pundit - exemple complet recommandé ?

8. **Performance Dashboard** : Quelles optimisations pour requêtes statistiques (compteurs, agrégats) ?

9. **Stimulus Sidebar** : Structure controller recommandée avec persistence localStorage ?

10. **Mobile UX** : Topbar admin séparé pour mobile ou réutiliser navbar principale ?

---

## 📚 RÉFÉRENCES EXISTANTES

### Codebase Actuel
- `app/views/layouts/_navbar.html.erb` : Navbar principale
- `app/views/admin/shared/_sidebar.html.erb` : Sidebar admin (existe)
- `app/views/layouts/application.html.erb` : Layout principal avec dark mode
- `app/controllers/admin/*.rb` : Controllers admin existants

### Documentation Projet
- `docs/admin/ressources/decisions/DASHBOARD.md` : Dashboard simple
- `docs/admin/ressources/decisions/sidebar_guide_bootstrap5.md` : Guide sidebar
- `docs/admin/ressources/references/reference-css-classes.md` : Classes CSS
- `docs/admin/ressources/references/reutilisation-dark-mode.md` : Dark mode

---

**Format réponse souhaité** : Guide complet avec code, explications, et recommandations claires pour chaque point.
