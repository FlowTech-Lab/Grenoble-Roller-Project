# Palette de recherche globale (Cmd+K) pour panel admin Rails + Stimulus

## Objectif

Mettre en place une **recherche globale** dans un panel admin Rails utilisant **Stimulus (Hotwire)** et **Bootstrap 5.3.2**, avec :

- Ouverture via raccourci clavier **Cmd+K / Ctrl+K**
- Recherche dans plusieurs ressources : **Users, Products, Events**, et éventuellement pages (Dashboard, etc.)
- **Navigation clavier** complète : flèches haut/bas pour sélectionner, **Enter** pour ouvrir, **Escape** pour fermer
- Limitation à **10 résultats maximum**
- Temps de réponse **< 200 ms** en pratique
- Respect de l’**accessibilité** : ARIA live regions, gestion du focus

---

## Architecture proposée

### Vue d’ensemble

3 approches possibles :

| Critère | Solution 1: Serveur (AJAX) | Solution 2: Client (JS pur) | Solution 3: Hybride (recommandée) |
|---------|----------------------------|------------------------------|------------------------------------|
| Temps réponse | 150–300 ms | < 50 ms | < 100 ms |
| Scalabilité | ✅ via DB/indexes | ❌ (limite quelques centaines d’items) | ✅✅ |
| Accessibilité | dépend réseau | ✅ | ✅✅ |
| Complexité | moyenne | simple | moyenne |
| Pertinence panel admin | bonne | limitée | **excellente** |

**Solution recommandée : approche hybride.**

Principe :

1. **Cache initial** côté client (optionnel) : récupération des données ou d’un index minimal
2. **Recherche en priorité côté client** (filtrage JS) si cache valide et taille raisonnable
3. **Fallback serveur (AJAX)** si cache expiré ou vide
4. Limitation stricte à **10 résultats** côté serveur ET côté client

Cela permet d’avoir une UX type « command palette » ultra réactive (< 50 ms en cache chaud), tout en gardant la recherche fiable et scalable côté serveur.

---

## Backend Rails – Contrôleur de recherche globale

### Route

```ruby
# config/routes.rb
namespace :admin do
  get "search/global_search", to: "search#global_search"
end
```

### Contrôleur

```ruby
# app/controllers/admin/search_controller.rb
module Admin
  class SearchController < ApplicationController
    before_action :authenticate_admin!

    def global_search
      query = params[:q].to_s.strip.downcase
      limit = (params[:limit] || 10).to_i

      return render json: { results: [] } if query.length < 2

      results = search_all_resources(query, limit)

      render json: {
        results: results,
        timestamp: Time.current.to_i
      }
    end

    private

    def search_all_resources(query, limit)
      all_results = []

      # Users
      all_results += search_users(query, limit)
      return all_results.first(limit) if all_results.size >= limit

      # Products
      all_results += search_products(query, limit - all_results.size)
      return all_results.first(limit) if all_results.size >= limit

      # Events
      all_results += search_events(query, limit - all_results.size)

      all_results.first(limit)
    end

    def search_users(query, limit)
      User
        .where("LOWER(email) LIKE ? OR LOWER(name) LIKE ?", "%#{query}%", "%#{query}%")
        .select(:id, :name, :email)
        .limit(limit)
        .map { |u| format_result(u, "User", user_path(u)) }
    end

    def search_products(query, limit)
      Product
        .where("LOWER(name) LIKE ? OR LOWER(sku) LIKE ?", "%#{query}%", "%#{query}%")
        .select(:id, :name, :sku)
        .limit(limit)
        .map { |p| format_result(p, "Product", product_path(p)) }
    end

    def search_events(query, limit)
      Event
        .where("LOWER(title) LIKE ?", "%#{query}%")
        .select(:id, :title, :created_at)
        .limit(limit)
        .map { |e| format_result(e, "Event", event_path(e)) }
    end

    def format_result(object, type, path)
      {
        id: object.id,
        type: type,
        title: object.is_a?(User) ? object.name : (object.respond_to?(:title) ? object.title : object.name),
        subtitle: object.is_a?(User) ? object.email : nil,
        path: path,
        icon: icon_for_type(type)
      }
    end

    def icon_for_type(type)
      {
        "User" => "person",
        "Product" => "box",
        "Event" => "calendar"
      }[type] || "search"
    end
  end
end
```

### (Optionnel) Index global avec cache Rails

Si beaucoup de données, possibilité d’avoir une couche d’index pour la partie client :

```ruby
# app/models/global_search_index.rb
class GlobalSearchIndex
  CACHE_KEY = "admin:global_search:index".freeze
  CACHE_TTL = 5.minutes

  def self.all_searchable
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
      [
        User.select(:id, :name, :email).map { |u| format_index(u, "User") },
        Product.select(:id, :name, :sku).map { |p| format_index(p, "Product") },
        Event.select(:id, :title).map { |e| format_index(e, "Event") }
      ].flatten
    end
  end

  def self.format_index(object, type)
    {
      id: object.id,
      type: type,
      title: object.respond_to?(:title) ? object.title : object.name,
      subtitle: object.is_a?(User) ? object.email : nil,
      searchable_text: [object.try(:name), object.try(:title), object.try(:email)].compact.join(" ").downcase
    }
  end
end
```

---

## Frontend – Stimulus Controller

### Idée générale

- Un **controller Stimulus** gère :
  - Le **raccourci clavier global** Cmd+K / Ctrl+K
  - L’**ouverture/fermeture** du modal
  - Les **appels fetch** au backend (fallback)
  - Le **cache** des résultats
  - Le **filtrage client**
  - La **navigation clavier** (flèches, Enter, Escape)
  - L’**accessibilité** (ARIA live region, focus trap, aria-selected)

### Controller Stimulus complet

```javascript
// app/javascript/controllers/search_palette_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "modal",
    "input",
    "results",
    "liveRegion",
    "overlay",
    "empty",
    "loading"
  ];

  static values = {
    cacheExpiry: { type: Number, default: 300000 }, // 5 min
    debounceDelay: { type: Number, default: 150 }
  };

  connect() {
    this.registerKeyboardShortcut();
    this.searchCache = null;
    this.cacheTimestamp = null;
    this.selectedIndex = -1;
    this.results = [];
    this.debounceTimer = null;
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydownHandler);
    if (this.focusTrapHandler) {
      this.modalTarget.removeEventListener("keydown", this.focusTrapHandler);
    }
  }

  // ============ RACCOURCI CLAVIER GLOBAL ============
  registerKeyboardShortcut() {
    this.boundKeydownHandler = this.handleGlobalKeydown.bind(this);
    document.addEventListener("keydown", this.boundKeydownHandler);
  }

  handleGlobalKeydown(event) {
    const activeElement = document.activeElement;
    const tag = activeElement.tagName;
    const type = activeElement.type;

    // Ne pas capturer Cmd+K / Ctrl+K quand on tape déjà dans un champ important
    if (
      tag === "TEXTAREA" ||
      (tag === "INPUT" && !["search", "text", ""].includes(type))
    ) {
      return;
    }

    const isCmdOrCtrlK =
      (event.metaKey || event.ctrlKey) &&
      event.key.toLowerCase() === "k" &&
      event.code === "KeyK";

    if (!isCmdOrCtrlK) return;

    event.preventDefault();
    this.open();
  }

  // ============ OUVERTURE / FERMETURE ============
  open() {
    this.modalTarget.classList.add("show");
    this.overlayTarget.classList.add("show");
    this.modalTarget.removeAttribute("aria-hidden");

    this.inputTarget.focus();
    this.inputTarget.select();

    this.trapFocus();

    if (!this.searchCache || this.isCacheExpired()) {
      this.loadInitialCache();
    }
  }

  close() {
    this.modalTarget.classList.remove("show");
    this.overlayTarget.classList.remove("show");
    this.modalTarget.setAttribute("aria-hidden", "true");

    this.inputTarget.value = "";
    this.results = [];
    this.selectedIndex = -1;
    this.resultsTarget.innerHTML = "";
    this.emptyTarget.classList.add("d-none");
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close();
    }
  }

  closeOnOverlay(event) {
    if (event.target === this.overlayTarget) {
      this.close();
    }
  }

  // ============ CACHING & RECHERCHE ============
  async loadInitialCache() {
    try {
      this.loadingTarget.classList.remove("d-none");
      const response = await fetch("/admin/search/global_search?q=&limit=0");
      const data = await response.json();
      // Ici, on pourrait stocker un index global si l'API le fournit
      this.searchCache = data.results || [];
      this.cacheTimestamp = Date.now();
    } catch (error) {
      console.error("Cache init failed:", error);
    } finally {
      this.loadingTarget.classList.add("d-none");
    }
  }

  async performSearch() {
    const query = this.inputTarget.value.trim();

    clearTimeout(this.debounceTimer);

    this.debounceTimer = setTimeout(async () => {
      this.selectedIndex = -1;

      if (query.length < 2) {
        this.results = [];
        this.resultsTarget.innerHTML = "";
        this.emptyTarget.classList.remove("d-none");
        this.emptyTarget.textContent = "Commencez à taper pour rechercher (min. 2 caractères)";
        return;
      }

      // 1. Si cache présent et non expiré, filtrage côté client
      if (this.searchCache && !this.isCacheExpired()) {
        const filtered = this.filterCachedResults(query);
        this.results = filtered.slice(0, 10);
        this.renderResults();
        this.announceResults();
        return;
      }

      // 2. Sinon, fallback côté serveur
      try {
        this.loadingTarget.classList.remove("d-none");
        const response = await fetch(
          `/admin/search/global_search?q=${encodeURIComponent(query)}&limit=10`
        );
        const data = await response.json();

        this.results = data.results || [];
        this.searchCache = data.results || [];
        this.cacheTimestamp = Date.now();

        this.renderResults();
        this.announceResults();
      } catch (error) {
        console.error("Search failed:", error);
        this.results = [];
        this.renderError();
      } finally {
        this.loadingTarget.classList.add("d-none");
      }
    }, this.debounceDelayValue);
  }

  filterCachedResults(query) {
    if (!this.searchCache || this.searchCache.length === 0) return [];

    const lowerQuery = query.toLowerCase();
    return this.searchCache.filter((item) => {
      return (
        item.title.toLowerCase().includes(lowerQuery) ||
        (item.subtitle && item.subtitle.toLowerCase().includes(lowerQuery))
      );
    });
  }

  isCacheExpired() {
    if (!this.cacheTimestamp) return true;
    return Date.now() - this.cacheTimestamp > this.cacheExpiryValue;
  }

  // ============ NAVIGATION CLAVIER ============
  handleInputKeydown(event) {
    switch (event.key) {
      case "ArrowDown":
        event.preventDefault();
        this.selectNext();
        break;
      case "ArrowUp":
        event.preventDefault();
        this.selectPrevious();
        break;
      case "Enter":
        event.preventDefault();
        this.navigateSelected();
        break;
      case "Escape":
        this.close();
        break;
    }
  }

  selectNext() {
    if (this.results.length === 0) return;
    this.selectedIndex = Math.min(this.selectedIndex + 1, this.results.length - 1);
    this.updateSelection();
  }

  selectPrevious() {
    if (this.results.length === 0) return;
    this.selectedIndex = Math.max(this.selectedIndex - 1, -1);
    this.updateSelection();
  }

  updateSelection() {
    const items = this.resultsTarget.querySelectorAll("[data-search-result]");

    items.forEach((el, index) => {
      const selected = index === this.selectedIndex;
      el.classList.toggle("selected", selected);
      el.setAttribute("aria-selected", selected ? "true" : "false");
      if (selected) {
        el.scrollIntoView({ block: "nearest" });
      }
    });

    if (this.selectedIndex >= 0) {
      const selected = this.results[this.selectedIndex];
      this.liveRegionTarget.textContent = `${selected.type}: ${selected.title}`;
    }
  }

  selectResult(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10);
    this.selectedIndex = index;
    this.updateSelection();
    this.navigateSelected();
  }

  navigateSelected() {
    if (this.selectedIndex < 0 || this.selectedIndex >= this.results.length) {
      return;
    }

    const selected = this.results[this.selectedIndex];
    window.location.href = selected.path;
  }

  // ============ RENDU ============
  renderResults() {
    if (this.results.length === 0) {
      this.emptyTarget.classList.remove("d-none");
      this.emptyTarget.textContent = "Aucun résultat";
      this.resultsTarget.innerHTML = "";
      return;
    }

    this.emptyTarget.classList.add("d-none");
    this.resultsTarget.innerHTML = this.results
      .map(
        (result, index) => `
        <button
          type="button"
          class="search-result-item ${index === this.selectedIndex ? "selected" : ""}"
          data-search-result
          data-index="${index}"
          data-action="click->search-palette#selectResult"
          aria-selected="${index === this.selectedIndex}"
          role="option"
        >
          <span class="search-result-icon">
            <i class="bi bi-${result.icon}"></i>
          </span>
          <div class="search-result-content">
            <div class="search-result-title">${this.escapeHtml(result.title)}</div>
            ${result.subtitle ? `<div class="search-result-subtitle">${this.escapeHtml(result.subtitle)}</div>` : ""}
          </div>
          <span class="search-result-type badge bg-secondary">${result.type}</span>
        </button>
      `
      )
      .join("");
  }

  renderError() {
    this.resultsTarget.innerHTML = `
      <div class="alert alert-danger m-3">
        Erreur lors de la recherche. Veuillez réessayer.
      </div>
    `;
  }

  announceResults() {
    const count = this.results.length;
    const query = this.inputTarget.value;
    this.liveRegionTarget.textContent = `${count} résultat${count !== 1 ? "s" : ""} pour "${query}"`;
  }

  // ============ ACCESSIBILITÉ ============
  trapFocus() {
    const focusableElements = this.modalTarget.querySelectorAll(
      "button, [href], input, select, textarea, [tabindex]:not([tabindex='-1'])"
    );
    const firstElement = focusableElements[0];
    const lastElement = focusableElements[focusableElements.length - 1];

    this.focusTrapHandler = (event) => {
      if (event.key !== "Tab") return;

      if (event.shiftKey) {
        if (document.activeElement === firstElement) {
          event.preventDefault();
          lastElement.focus();
        }
      } else {
        if (document.activeElement === lastElement) {
          event.preventDefault();
          firstElement.focus();
        }
      }
    };

    this.modalTarget.addEventListener("keydown", this.focusTrapHandler);
  }

  escapeHtml(text) {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }
}
```

---

## HTML – Modal Bootstrap + ARIA

```erb
<!-- app/views/layouts/_search_palette.html.erb -->
<div
  data-controller="search-palette"
  data-search-palette-cache-expiry-value="300000"
  data-search-palette-debounce-delay-value="150"
>
  <!-- Overlay -->
  <div
    class="search-palette-overlay"
    data-search-palette-target="overlay"
    data-action="click->search-palette#closeOnOverlay"
  ></div>

  <!-- Modal -->
  <div
    class="modal fade search-palette-modal"
    id="searchPalette"
    tabindex="-1"
    role="dialog"
    aria-labelledby="searchPaletteLabel"
    aria-hidden="true"
    data-search-palette-target="modal"
  >
    <div class="modal-dialog modal-dialog-centered modal-lg">
      <div class="modal-content">
        <div class="modal-header border-bottom">
          <h5 class="modal-title" id="searchPaletteLabel">
            <i class="bi bi-search"></i>
            Recherche globale
          </h5>
          <button
            type="button"
            class="btn-close"
            data-action="click->search-palette#close"
            aria-label="Fermer"
          ></button>
        </div>

        <div class="modal-body p-0">
          <!-- Champ de recherche -->
          <div class="search-palette-input-wrapper p-3 border-bottom">
            <input
              type="text"
              class="form-control form-control-lg search-palette-input"
              placeholder="Tapez pour rechercher... (Échap pour fermer)"
              data-search-palette-target="input"
              data-action="input->search-palette#performSearch keydown->search-palette#handleInputKeydown keydown->search-palette#closeOnEscape"
              aria-label="Champ de recherche"
              aria-describedby="searchHint"
              autocomplete="off"
              spellcheck="false"
            />
            <small id="searchHint" class="text-muted d-block mt-2">
              Raccourci : <kbd>Cmd</kbd><kbd>K</kbd> / <kbd>Ctrl</kbd><kbd>K</kbd>
              · Flèches pour naviguer · Entrée pour sélectionner
            </small>
          </div>

          <!-- Loading -->
          <div
            class="text-center p-4 d-none"
            data-search-palette-target="loading"
          >
            <div class="spinner-border spinner-border-sm" role="status">
              <span class="visually-hidden">Recherche en cours...</span>
            </div>
          </div>

          <!-- Résultats -->
          <div
            class="search-palette-results"
            role="listbox"
            data-search-palette-target="results"
            style="max-height: 400px; overflow-y: auto;"
          ></div>

          <!-- État vide -->
          <div
            class="alert alert-info m-3 d-none"
            data-search-palette-target="empty"
          >
            📝 Commencez à taper pour rechercher (minimum 2 caractères)
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- ARIA Live Region -->
  <div
    aria-live="polite"
    aria-atomic="true"
    class="visually-hidden"
    data-search-palette-target="liveRegion"
  ></div>
</div>
```

À inclure dans le layout admin :

```erb
<!-- app/views/layouts/admin.html.erb -->
<%= render "search_palette" %>
```

---

## CSS – Styles pour la palette (Bootstrap 5.3.2)

```scss
// app/assets/stylesheets/search_palette.scss

$primary-color: #208384;
$border-color: #e9ecef;

.search-palette-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0);
  z-index: 1040;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.15s ease-in-out, background 0.15s ease-in-out;

  &.show {
    background: rgba(0, 0, 0, 0.5);
    opacity: 1;
    pointer-events: all;
  }
}

.search-palette-modal {
  z-index: 1050;

  .modal-content {
    border: 1px solid $border-color;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
    border-radius: 12px;
    animation: slideUp 0.2s ease-out;
  }

  .modal-header {
    background: #f8f9fa;

    .modal-title {
      font-weight: 600;
      font-size: 1.1rem;
      color: #333;
    }
  }
}

.search-palette-input-wrapper {
  .form-control {
    border: 1px solid $border-color;
    border-radius: 8px;
    font-size: 1rem;
    padding: 12px 16px;

    &:focus {
      border-color: $primary-color;
      box-shadow: 0 0 0 3px rgba(32, 131, 132, 0.1);
    }
  }

  small {
    font-size: 0.875rem;

    kbd {
      background: #f1f3f5;
      border: 1px solid #dee2e6;
      border-radius: 4px;
      padding: 2px 6px;
      font-family: monospace;
      font-size: 0.875em;
      margin: 0 2px;
    }
  }
}

.search-palette-results {
  display: flex;
  flex-direction: column;
  border-top: 1px solid $border-color;
}

.search-result-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border: none;
  background: transparent;
  cursor: pointer;
  transition: background 0.1s ease;
  text-align: left;
  width: 100%;
  border-bottom: 1px solid $border-color;

  &:last-child {
    border-bottom: none;
  }

  &:hover,
  &.selected {
    background: #f0f8f9;
  }

  &:focus {
    outline: 2px solid $primary-color;
    outline-offset: -2px;
  }

  .search-result-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 40px;
    height: 40px;
    background: #f1f3f5;
    border-radius: 8px;
    color: $primary-color;
    font-size: 1.2rem;
    flex-shrink: 0;
  }

  .search-result-content {
    flex: 1;
    min-width: 0;

    .search-result-title {
      font-weight: 500;
      color: #333;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .search-result-subtitle {
      font-size: 0.875rem;
      color: #6c757d;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
  }

  .badge {
    flex-shrink: 0;
    font-size: 0.75rem;
    padding: 4px 8px;
    background: #e9ecef;
    color: #495057;
  }
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.search-palette-modal {
  &.show {
    .search-palette-input-wrapper .form-control {
      &:focus {
        box-shadow: 0 0 0 3px rgba(32, 131, 132, 0.1), 0 0 0 2px $primary-color;
      }
    }
  }
}
```

---

## Sécurité & accessibilité

### Sécurité

- `before_action :authenticate_admin!` pour sécuriser l’endpoint
- Optionnel : contrôle de rôle

```ruby
before_action :authorize_search!

def authorize_search!
  unless current_user.admin? || current_user.has_role?(:manager)
    head :forbidden
  end
end
```

- Eventuel **rate limiting** via rack-attack si besoin

### Accessibilité

- `role="listbox"` sur le conteneur des résultats
- `role="option"` sur chaque item
- `aria-selected="true/false"` sur l’item sélectionné
- `aria-live="polite"` + `aria-atomic="true"` sur une région cachée
- Focus trap dans le modal avec gestion de Tab / Shift+Tab
- Raccourcis clavier documentés (`Cmd/Ctrl+K`, flèches, Enter, Escape)

---

## Checklist d’intégration

1. Ajouter le controller Rails `Admin::SearchController`
2. Ajouter la route `GET /admin/search/global_search`
3. Ajouter le controller Stimulus `search_palette_controller.js`
4. Ajouter la partial `_search_palette.html.erb` dans le layout admin
5. Ajouter les styles `search_palette.scss` et les importer dans le pipeline
6. Tester :
   - `Cmd+K / Ctrl+K` → ouverture
   - `Escape` → fermeture
   - Taper au moins 2 caractères → résultats
   - Flèches haut/bas → navigation
   - `Enter` → navigation vers la ressource

Cette base est pensée pour être **copiable directement** dans un projet Rails + Stimulus + Bootstrap et extensible pour d’autres ressources (pages statiques type Dashboard, Settings, etc.).