# Dashboard Réordonnables Rails 8 + Bootstrap 5.3.2 + Stimulus

## Contexte

Objectif : Dashboard admin avec widgets réordonnables (drag-drop) pour chaque utilisateur.

Contraintes :
- Stack : **Rails 8**, **Bootstrap 5.3.2**, **Stimulus** (pas de React)
- 8 widgets (statistiques, graphiques, listes)
- Réordonnage par drag-drop
- Sauvegarde des positions en base (par utilisateur)
- Responsive : **4 colonnes desktop**, **2 tablet**, **1 mobile**
- Performance : widgets pouvant charger des données async
- Accessibilité : navigation clavier pour réordonner

Ce document propose **2-3 solutions** dont une approche "simple d’abord" (MVP progressif), avec recommandations.

---

## 🧭 Vue d’ensemble des solutions

### Solution 1 : HTML5 Drag API pure + Stimulus (sans dépendance externe)

- Utilise uniquement l’API Drag & Drop native HTML5.
- Contrôleur Stimulus custom pour gérer dragstart / dragover / drop / dragend.
- Sauvegarde de l’ordre via une action Rails (JSON -> DB).

**Avantages :**
- **Zéro dépendance JS** (pas de SortableJS).
- **Contrôle fin** du comportement drag-drop.
- Très léger (essentiellement ton propre code).

**Inconvénients :**
- **Accessibilité clavier** à implémenter toi-même (ARIA, gestion des touches).
- Support tactile/mobiles moins bon que des libs spécialisées.
- API HTML5 Drag parfois capricieuse suivant les navigateurs.
- Plus de code à maintenir.

### Solution 2 : SortableJS + Stimulus (RECOMMANDÉE pour production)

- Utilise **SortableJS** (lib de référence pour drag-drop).
- Intégration via Stimulus (directe ou avec `@stimulus-components/sortable`).
- Ajout progressif : commencer avec ordre fixe, puis ajouter drag-drop.

**Avantages :**
- **Lib mature et largement utilisée** (très robuste pour listes et grilles).
- Support **tactile/mobile** et **accessibilité** meilleurs que l’API native seule.
- API riche : animation, gestion des events, drag handles, etc.
- Moins de code custom, plus de logique métier côté Rails.

**Inconvénients :**
- Ajoute une dépendance JS (~17 kB gzip).
- Un peu plus de configuration au départ.

### Solution 3 : Table séparée `user_widget_positions` (plus complexe)

- Modélisation relationnelle classique : une ligne par widget par user.
- Requêtes SQL facilitées (tri, filtres, audits...).

**Avantages :**
- Très propre côté modèle, requêtes directes sur les positions.
- Permet un audit trail plus simple (versioning possible).

**Inconvénients :**
- Overkill pour un MVP avec 8 widgets.
- Plus de migrations / code / jointures à gérer.

🔎 **Recommandation globale :**
- **MVP** : Solution 2 (SortableJS) avec **JSONB par user**, en 2 phases (ordre fixe → drag-drop).
- Solution 1 est intéressante si tu refuses toute dépendance JS, mais plus coûteuse à bien faire (a11y + mobile).

---

## 🎯 Recommandation MVP Progressif

### Phase 1 : Ordre fixe, pas de drag-drop

1. Implémenter un dashboard avec ordre fixe des widgets.
2. Utiliser une simple liste Ruby (+ éventuellement JSONB pour préparer le terrain).
3. Travail sur la grille responsive et les partials de widgets.

### Phase 2 : Ajout du drag-drop (via SortableJS)

1. Installer SortableJS et son contrôleur Stimulus.
2. Sauvegarder l’ordre en AJAX vers une action Rails.
3. Améliorer l’accessibilité clavier.

Cette approche :
- Minimiser les risques.
- Donne un dashboard utilisable dès la phase 1.
- Permet d’affiner les besoins en drag-drop avant d’investir du temps.

---

## 🗄️ Structure Base de Données

On suppose PostgreSQL (recommandé pour Rails 8, JSONB, etc.).

### Option 1 (recommandée) : Colonne JSONB sur `users`

Permet de stocker l’ordre des widgets (et plus tard d’autres préférences) dans un JSON :

```bash
rails generate migration AddWidgetPositionsToUsers widget_positions:jsonb
```

```ruby
# db/migrate/[timestamp]_add_widget_positions_to_users.rb
class AddWidgetPositionsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :widget_positions, :jsonb, default: {}, null: false
    add_index :users, :widget_positions, using: :gin
  end
end
```

### Modèle `User` avec JSONB

```ruby
# app/models/user.rb
class User < ApplicationRecord
  DASHBOARD_WIDGETS = [
    'stats',
    'revenue',
    'users',
    'tasks',
    'calendar',
    'notifications',
    'recent',
    'performance'
  ].freeze

  # Renvoie l’ordre effectif des widgets pour le user
  def dashboard_widget_order
    raw = (widget_positions && widget_positions['widget_order']) || []
    raw = raw.is_a?(String) ? raw.split(',').map(&:strip) : raw

    # On ne garde que les widgets connus
    order = raw & DASHBOARD_WIDGETS

    # On ajoute les widgets manquants à la fin
    missing = DASHBOARD_WIDGETS - order
    (order + missing).uniq
  end

  # Met à jour l’ordre de manière sécurisée
  def set_dashboard_widget_order!(order)
    order = Array(order).map(&:to_s)
    order = (order & DASHBOARD_WIDGETS) # Filtre de sécurité

    # Ajoute les manquants
    missing = DASHBOARD_WIDGETS - order
    save_order = (order + missing).uniq

    update!(widget_positions: (widget_positions || {}).merge('widget_order' => save_order))
  end

  def reset_dashboard_layout!
    update!(widget_positions: (widget_positions || {}).except('widget_order'))
  end
end
```

**Avantages JSONB :**
- Très simple pour ce use case.
- Extensible (plus tard : widget masqués, tailles, etc.).
- Index GIN pour requêtes éventuelles.

### Option 2 : Table séparée `user_widget_positions`

```bash
rails generate model UserWidgetPosition user:references widget_type:string position:integer
```

```ruby
# app/models/user_widget_position.rb
class UserWidgetPosition < ApplicationRecord
  belongs_to :user

  validates :widget_type, presence: true
  validates :position, presence: true, numericality: { only_integer: true }
  validates :widget_type, uniqueness: { scope: :user_id }

  default_scope { order(:position) }
end
```

```ruby
# app/models/user.rb
class User < ApplicationRecord
  DASHBOARD_WIDGETS = [
    'stats',
    'revenue',
    'users',
    'tasks',
    'calendar',
    'notifications',
    'recent',
    'performance'
  ].freeze

  has_many :user_widget_positions, dependent: :destroy

  def dashboard_widget_order
    if user_widget_positions.exists?
      user_widget_positions.order(:position).pluck(:widget_type)
    else
      DASHBOARD_WIDGETS
    end
  end
end
```

Cette option est plus lourde, utile si tu veux :
- Auditer les changements.
- Faire des requêtes complexes sur les widgets.

Pour 8 widgets/user, JSONB est largement suffisant.

---

## 🧩 Solution 1 : HTML5 Drag API + Stimulus

### Contrôleur Rails

```ruby
# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @widgets = current_user.dashboard_widget_order
  end

  def update_widget_order
    order = params[:widget_order]

    unless order.is_a?(Array)
      return render json: { error: 'Invalid payload' }, status: :unprocessable_entity
    end

    # Sécurisation
    order = order.map(&:to_s)
    if (order - User::DASHBOARD_WIDGETS).any?
      return render json: { error: 'Invalid widget id' }, status: :unprocessable_entity
    end

    current_user.set_dashboard_widget_order!(order)

    render json: { success: true }, status: :ok
  end
end
```

### Routes

```ruby
# config/routes.rb
scope '/admin' do
  get  'dashboard',                  to: 'dashboard#index',  as: :dashboard
  patch 'dashboard/widget_order',    to: 'dashboard#update_widget_order', as: :dashboard_update_widget_order
end
```

### Contrôleur Stimulus (HTML5 Drag)

```javascript
// app/javascript/controllers/dashboard_controller.js
import { Controller } from "@hotwired/stimulus"
import { patch } from "@rails/request.js"

export default class extends Controller {
  static targets = ["widget"]
  static values = {
    updateUrl: String
  }

  connect() {
    this.draggedElement = null
  }

  dragStart(event) {
    const el = event.currentTarget
    this.draggedElement = el

    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", el.dataset.widgetId)

    el.classList.add("opacity-50", "border", "border-primary")
  }

  dragOver(event) {
    event.preventDefault() // Indispensable pour autoriser le drop
    event.dataTransfer.dropEffect = "move"

    const over = event.target.closest("[data-dashboard-target='widget']")
    if (!over || over === this.draggedElement) return

    over.classList.add("border", "border-dashed", "border-primary")
  }

  dragLeave(event) {
    const over = event.target.closest("[data-dashboard-target='widget']")
    if (over) {
      over.classList.remove("border", "border-dashed", "border-primary")
    }
  }

  async drop(event) {
    event.preventDefault()

    const dropTarget = event.currentTarget.closest("[data-dashboard-target='widget']")
    if (!dropTarget || dropTarget === this.draggedElement) return

    const parent = dropTarget.parentElement
    const children = Array.from(parent.querySelectorAll("[data-dashboard-target='widget']"))

    const draggedIndex = children.indexOf(this.draggedElement)
    const dropIndex    = children.indexOf(dropTarget)

    if (draggedIndex < dropIndex) {
      parent.insertBefore(this.draggedElement, dropTarget.nextSibling)
    } else {
      parent.insertBefore(this.draggedElement, dropTarget)
    }

    dropTarget.classList.remove("border", "border-dashed", "border-primary")

    await this.saveOrder()
  }

  dragEnd(event) {
    const el = event.currentTarget
    el.classList.remove("opacity-50", "border", "border-primary")

    this.widgetTargets.forEach(w => w.classList.remove("border", "border-dashed", "border-primary"))
  }

  async saveOrder() {
    const order = Array.from(this.element.querySelectorAll("[data-dashboard-target='widget']"))
      .map(w => w.dataset.widgetId)

    try {
      await patch(this.updateUrlValue, {
        body: JSON.stringify({ widget_order: order }),
        contentType: "application/json",
        responseKind: "json"
      })
    } catch (e) {
      console.error("Error saving widget order", e)
    }
  }

  // Gestion clavier (exemple simple : Shift+flèches)
  keyDown(event) {
    const widget = event.target.closest("[data-dashboard-target='widget']")
    if (!widget) return

    const row = widget.parentElement
    const widgets = Array.from(row.querySelectorAll("[data-dashboard-target='widget']"))
    const index = widgets.indexOf(widget)

    // Shift + flèche gauche -> déplacer à gauche
    if (event.shiftKey && event.key === "ArrowLeft" && index > 0) {
      row.insertBefore(widget, widgets[index - 1])
      widget.focus()
      this.saveOrder()
    }

    // Shift + flèche droite -> déplacer à droite
    if (event.shiftKey && event.key === "ArrowRight" && index < widgets.length - 1) {
      row.insertBefore(widget, widgets[index + 1].nextSibling)
      widget.focus()
      this.saveOrder()
    }
  }
}
```

### Vue (Bootstrap + HTML5 Drag)

```erb
<!-- app/views/dashboard/index.html.erb -->
<div class="container-fluid mt-4">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h1>Dashboard</h1>
    <%= button_to 'Reset layout', dashboard_update_widget_order_path,
                  method: :patch,
                  params: { widget_order: User::DASHBOARD_WIDGETS },
                  class: 'btn btn-outline-secondary btn-sm' %>
  </div>

  <div
    data-controller="dashboard"
    data-dashboard-update-url-value="<%= dashboard_update_widget_order_path %>"
  >
    <div class="row row-cols-1 row-cols-md-2 row-cols-lg-4 g-3">
      <% @widgets.each do |widget_id| %>
        <div
          class="col"
          data-dashboard-target="widget"
          data-widget-id="<%= widget_id %>"
          draggable="true"
          tabindex="0"
          data-action="
            dragstart->dashboard#dragStart
            dragover->dashboard#dragOver
            dragleave->dashboard#dragLeave
            drop->dashboard#drop
            dragend->dashboard#dragEnd
            keydown->dashboard#keyDown
          "
          aria-label="Widget <%= widget_id %>. Shift+flèche gauche/droite pour changer l'ordre"
        >
          <%= render "widgets/#{widget_id}" %>
        </div>
      <% end %>
    </div>
  </div>
</div>

<style>
  [draggable="true"] {
    cursor: grab;
  }

  [draggable="true"]:active {
    cursor: grabbing;
  }

  [draggable="true"]:focus {
    outline: 2px solid var(--bs-primary);
    outline-offset: 2px;
  }

  .border-dashed {
    border-style: dashed !important;
  }
</style>
```

---

## 🧩 Solution 2 : SortableJS + Stimulus (recommandée)

### Phase 1 : MVP sans drag-drop (ordre fixe)

```ruby
# app/models/user.rb
class User < ApplicationRecord
  DASHBOARD_WIDGETS = [
    'stats',
    'revenue',
    'users',
    'tasks',
    'calendar',
    'notifications',
    'recent',
    'performance'
  ].freeze

  def dashboard_widget_order
    DASHBOARD_WIDGETS
  end
end
```

```erb
<!-- app/views/dashboard/index.html.erb -->
<div class="container-fluid mt-4">
  <h1 class="mb-4">Dashboard</h1>

  <div class="row row-cols-1 row-cols-md-2 row-cols-lg-4 g-3">
    <% current_user.dashboard_widget_order.each do |widget_id| %>
      <div class="col">
        <%= render "widgets/#{widget_id}" %>
      </div>
    <% end %>
  </div>
</div>
```

### Phase 2 : Ajout de SortableJS

#### Installation

```bash
yarn add sortablejs @stimulus-components/sortable @rails/request.js
```

#### Enregistrement du contrôleur Sortable

```javascript
// app/javascript/controllers/index.js
import { Application } from "@hotwired/stimulus"
import Sortable from "@stimulus-components/sortable"

window.Stimulus = Application.start()
Stimulus.register("sortable", Sortable)
```

> Tu peux aussi faire un wrapper custom si tu préfères ne pas utiliser `@stimulus-components/sortable`.

#### mise à jour `User` (JSONB)

```ruby
# app/models/user.rb
class User < ApplicationRecord
  DASHBOARD_WIDGETS = [
    'stats',
    'revenue',
    'users',
    'tasks',
    'calendar',
    'notifications',
    'recent',
    'performance'
  ].freeze

  def dashboard_widget_order
    raw = (widget_positions && widget_positions['widget_order']) || []
    raw = raw.is_a?(String) ? raw.split(',').map(&:strip) : raw

    order = raw & DASHBOARD_WIDGETS
    missing = DASHBOARD_WIDGETS - order
    (order + missing).uniq
  end

  def set_dashboard_widget_order!(order)
    order = Array(order).map(&:to_s)
    order = (order & DASHBOARD_WIDGETS)
    missing = DASHBOARD_WIDGETS - order
    save_order = (order + missing).uniq

    update!(widget_positions: (widget_positions || {}).merge('widget_order' => save_order))
  end
end
```

#### Contrôleur Rails (update order)

```ruby
# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @widgets = current_user.dashboard_widget_order
  end

  def update_widget_order
    order = params[:order]
    unless order.is_a?(Array)
      return render json: { error: 'Invalid payload' }, status: :unprocessable_entity
    end

    current_user.set_dashboard_widget_order!(order)
    head :ok
  end

  def reset_layout
    current_user.reset_dashboard_layout!
    redirect_to dashboard_path, notice: 'Dashboard reset.'
  end
end
```

#### Routes

```ruby
# config/routes.rb
scope '/admin' do
  get    'dashboard',                to: 'dashboard#index',          as: :dashboard
  patch  'dashboard/widget_order',   to: 'dashboard#update_widget_order', as: :dashboard_update_widget_order
  delete 'dashboard/reset_layout',   to: 'dashboard#reset_layout',   as: :dashboard_reset_layout
end
```

#### Vue avec SortableJS

```erb
<!-- app/views/dashboard/index.html.erb -->
<div class="container-fluid mt-4">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h1>Dashboard</h1>
    <%= button_to 'Reset layout', dashboard_reset_layout_path,
                  method: :delete,
                  class: 'btn btn-outline-secondary btn-sm' %>
  </div>

  <div
    data-controller="sortable"
    data-sortable-animation-value="150"
    data-sortable-handle-value=".widget-header"
    data-sortable-onEnd-value="dashboard#onEnd"
    data-sortable-draggable-value=".widget-item"
    class="row row-cols-1 row-cols-md-2 row-cols-lg-4 g-3"
  >
    <% @widgets.each_with_index do |widget_id, index| %>
      <div
        class="col widget-item"
        data-id="<%= widget_id %>"
        tabindex="0"
        aria-label="Widget <%= widget_id %>. Position <%= index + 1 %>"
      >
        <div class="card h-100">
          <div class="card-header d-flex align-items-center justify-content-between widget-header" style="cursor: grab;">
            <span><%= widget_id.humanize %></span>
            <span class="text-muted small">⋮⋮</span>
          </div>
          <div class="card-body">
            <%= render "widgets/#{widget_id}" %>
          </div>
        </div>
      </div>
    <% end %>
  </div>
</div>

<style>
  .widget-item {
    touch-action: none;
  }

  .widget-item:focus {
    outline: 2px solid var(--bs-primary);
    outline-offset: 2px;
  }

  .sortable-ghost {
    opacity: 0.4;
    background: var(--bs-gray-200);
  }
</style>
```

#### Contrôleur Stimulus custom pour gérer l’event `onEnd`

Si tu veux rester maître de la requête vers Rails :

```javascript
// app/javascript/controllers/dashboard_sortable_controller.js
import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"
import { patch } from "@rails/request.js"

export default class extends Controller {
  static values = {
    updateUrl: String
  }

  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      handle: ".widget-header",
      draggable: ".widget-item",
      onEnd: this.reorder.bind(this)
    })
  }

  async reorder() {
    const order = Array.from(this.element.querySelectorAll('.widget-item')).map(el => el.dataset.id)

    try {
      await patch(this.updateUrlValue, {
        body: JSON.stringify({ order: order }),
        contentType: "application/json",
        responseKind: "json"
      })
    } catch (e) {
      console.error("Error updating order", e)
    }
  }
}
```

Puis dans la vue :

```erb
<div
  data-controller="dashboard-sortable"
  data-dashboard-sortable-update-url-value="<%= dashboard_update_widget_order_path %>"
  class="row row-cols-1 row-cols-md-2 row-cols-lg-4 g-3"
>
  ...
</div>
```

---

## 📐 Grille Responsive : CSS Grid vs Bootstrap Grid vs Flexbox

Tu veux :
- 4 colonnes en desktop
- 2 colonnes en tablet
- 1 colonne en mobile

### Option simple : Bootstrap Grid uniquement

```erb
<div class="row row-cols-1 row-cols-md-2 row-cols-lg-4 g-3">
  <% @widgets.each do |widget_id| %>
    <div class="col">
      <%= render "widgets/#{widget_id}" %>
    </div>
  <% end %>
</div>
```

Bootstrap 5.3.2 gère déjà :
- `row-cols-1` (mobile)
- `row-cols-md-2` (≥ md)
- `row-cols-lg-4` (≥ lg)

Pour un MVP, c’est largement suffisant.

### Option plus fine : CSS Grid custom

```scss
// app/assets/stylesheets/dashboard.scss
.dashboard-grid {
  display: grid;
  gap: 1.5rem;

  // Défaut desktop : 4 colonnes
  grid-template-columns: repeat(4, 1fr);

  @media (max-width: 576px) {
    grid-template-columns: 1fr; // 1 colonne mobile
  }

  @media (min-width: 577px) and (max-width: 991px) {
    grid-template-columns: repeat(2, 1fr); // 2 colonnes tablet
  }
}

.dashboard-grid .widget {
  border: 1px solid var(--bs-border-color);
  border-radius: 0.5rem;
  padding: 1.5rem;
  background: #fff;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  transition: all 0.2s ease;

  &:hover {
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    transform: translateY(-2px);
  }
}
```

```erb
<div class="dashboard-grid">
  <% @widgets.each do |widget_id| %>
    <div class="widget" data-widget-id="<%= widget_id %>">
      <%= render "widgets/#{widget_id}" %>
    </div>
  <% end %>
</div>
```

### Conclusion layout

- **MVP** : `row/col` Bootstrap suffit largement, surtout si tu t’appuies sur SortableJS.
- Si tu veux un layout plus "modern grid", tu peux basculer en CSS Grid plus tard.

---

## 🔄 Chargement Async des Widgets

Les widgets peuvent être lourds (statistiques, requêtes SQL, API externes). Pour éviter de bloquer le render :

### Utiliser Turbo Frames (lazy loading)

```erb
<!-- app/views/widgets/_revenue.html.erb -->
<%= turbo_frame_tag "widget_revenue", src: widget_revenue_path, loading: :lazy do %>
  <div class="d-flex justify-content-center align-items-center" style="min-height: 120px;">
    <div class="spinner-border" role="status">
      <span class="visually-hidden">Loading revenue...</span>
    </div>
  </div>
<% end %>
```

```ruby
# config/routes.rb
get 'widgets/revenue', to: 'widgets#revenue', as: :widget_revenue
```

```ruby
# app/controllers/widgets_controller.rb
class WidgetsController < ApplicationController
  def revenue
    @revenue_data = RevenueService.call(current_user)
    render partial: 'widgets/revenue_content', locals: { revenue: @revenue_data }
  end
end
```

```erb
<!-- app/views/widgets/_revenue_content.html.erb -->
<div>
  <h5>Revenue</h5>
  <p>Chiffre du jour : <%= number_to_currency(revenue.today) %></p>
</div>
```

Cela fonctionne très bien combiné avec le drag-drop, car le container du widget reste le même, seul le contenu est chargé async dans le frame.

---

## ♿ Accessibilité & Clavier

Points importants :

1. Chaque widget doit être **focusable** : `tabindex="0"`.
2. Ajouter un **ARIA label** décrivant la position et les commandes clavier.
3. Fournir raccourcis clavier pour réordonner, par exemple :
   - `Shift + Flèche gauche/droite` pour déplacer d’une position.
   - Ou `Ctrl + ↑/↓` suivant ton layout.
4. Style focus visible (`outline`) explicite.

Exemple simple (HTML5 Drag) déjà montré dans le controller Stimulus :

```javascript
keyDown(event) {
  const widget = event.target.closest("[data-dashboard-target='widget']")
  if (!widget) return

  const row = widget.parentElement
  const widgets = Array.from(row.querySelectorAll("[data-dashboard-target='widget']"))
  const index = widgets.indexOf(widget)

  if (event.shiftKey && event.key === "ArrowLeft" && index > 0) {
    row.insertBefore(widget, widgets[index - 1])
    widget.focus()
    this.saveOrder()
  }

  if (event.shiftKey && event.key === "ArrowRight" && index < widgets.length - 1) {
    row.insertBefore(widget, widgets[index + 1].nextSibling)
    widget.focus()
    this.saveOrder()
  }
}
```

Tu peux adapter la logique selon que tu utilises une vraie grille CSS (grid) ou la grille Bootstrap (row/col).

---

## 📅 Plan de mise en œuvre (checklist)

### Sprint 1 (MVP sans drag-drop) – 2 à 3 jours

- [ ] Ajouter la colonne JSONB `widget_positions` sur `users`.
- [ ] Implémenter `User::DASHBOARD_WIDGETS` et `dashboard_widget_order`.
- [ ] Créer la vue dashboard avec Bootstrap (`row-cols-1 row-cols-md-2 row-cols-lg-4`).
- [ ] Implémenter les partials des 8 widgets.
- [ ] Ajouter lazy loading (Turbo Frames) pour les widgets lourds.
- [ ] Tests unitaires de base (ordre par défaut, etc.).

### Sprint 2 (Drag-drop + persistance) – 3 à 4 jours

- [ ] Installer SortableJS.
- [ ] Créer un contrôleur Stimulus `dashboard_sortable`.
- [ ] Créer l’action `update_widget_order` côté Rails.
- [ ] Sauvegarder l’ordre dans `widget_positions`.
- [ ] Ajout d’accessibilité clavier minimale.
- [ ] Tests système (Capybara) pour vérifier la persistance d’ordre.

### Sprint 3 (optionnel / polishing)

- [ ] A11y plus avancée (annonces ARIA, instructions clavier détaillées).
- [ ] Options user : masquer certains widgets, collapsibles.
- [ ] Analytics sur les mouvements de widgets.

---

## Conclusion

Pour un dashboard admin Rails 8 + Bootstrap 5.3.2 + Stimulus :

- **Meilleure solution réaliste** : **SortableJS + Stimulus** (Solution 2), avec sauvegarde dans une **colonne JSONB** par utilisateur.
- **MVP simple** : commencer par un **ordre fixe** (sans drag-drop), puis ajouter le drag-drop et la persistance en deuxième phase.
- **Grille responsive** : Bootstrap grid (`row-cols-1 row-cols-md-2 row-cols-lg-4`) suffit pour démarrer, CSS Grid peut être ajouté plus tard pour un layout plus fin.
- **Accessibilité** : assurer `tabindex="0"`, visuel focus, et quelques raccourcis clavier simples pour réordonner.

Tu as ici tous les blocs : migrations, modèles, contrôleurs, Stimulus, vues, CSS, ainsi qu’un plan d’implémentation progressif.
