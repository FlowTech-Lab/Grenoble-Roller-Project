# Validation des formulaires Rails + Bootstrap + Stimulus

## TL;DR

Pour un panel admin Rails avec Bootstrap 5.3 et Stimulus, la meilleure approche est une **validation hybride** :

- **Rails** reste la source de vérité (validations ActiveRecord).
- **Stimulus** gère la validation **client-side en temps réel** (blur/input).
- **Bootstrap** fournit le feedback visuel (`is-invalid`, `invalid-feedback`).
- Le **submit est désactivé** tant qu'il reste des erreurs.
- Les **erreurs serveur** (422 + JSON ou HTML) sont propagées et affichées inline.

La structure la plus maintenable est **un Stimulus controller par formulaire**, qui gère tous les champs + le bouton submit.

---

## 1. Stratégie globale de validation

### 1.1. Pourquoi une approche hybride (client + serveur) est la meilleure

- **Le serveur est obligatoire** :
  - Garantit l'intégrité des données.
  - Les validations ActiveRecord sont fiables et versionnées avec le modèle.
  - Ne dépend pas de JS (important pour sécurité / bypass).

- **Le client améliore l'UX** :
  - Retour immédiat sur blur / input.
  - Evite la frustration de soumettre un formulaire plein d'erreurs.
  - Permet de guider l'utilisateur : contraintes min/max, format, etc.

- **Principe clé** :
  - Le client **ne remplace jamais** la validation serveur.
  - Il **copie / reflète** les règles les plus simples côté client (présence, longueur, format basique).
  - Pour des règles complexes ou dépendantes des données (unicité, contraintes business…), on peut faire des requêtes AJAX/Turbo spécifiques.

### 1.2. Rôle de chaque couche

- **ActiveRecord (serveur)** :
  - `validates :email, presence: true, format: …`
  - `validates :password, length: { minimum: 8 }`
  - `validates :name, presence: true, length: { minimum: 3 }`

- **Stimulus (client)** :
  - Sur `blur` : validation du champ, ajout de `is-invalid` si erreur.
  - Sur `input` : suppression rapide du message d'erreur dès correction.
  - Sur `submit` : validation de tous les champs, blocage si erreurs.
  - Optionnel : appels AJAX pour validation côté serveur en temps réel.

- **Bootstrap** :
  - `is-invalid` / `is-valid` sur les champs.
  - `<div class="invalid-feedback">Message…</div>` pour les messages.
  - Optionnel : `was-validated` sur le form pour un comportement global.

---

## 2. Synchronisation Rails / Bootstrap

### 2.1. Mapping des erreurs Rails vers les classes Bootstrap

Sur retour serveur (HTML ou JSON) :

- Pour chaque champ ayant des erreurs :
  - Ajout de `class="form-control is-invalid"`.
  - Affichage des messages dans un `<div class="invalid-feedback d-block">`.
- À l'initialisation du formulaire (après un render :new avec erreurs) :
  - Le HTML contient déjà les classes / messages.
  - Stimulus se contente de reprendre l'état initial et de le maintenir.

---

## 3. Gestion des erreurs serveur (422) et affichage inline

### 3.1. Retour HTML classique (Turbo ou non)

Pattern historique :

- `form_with(model: ...)` en HTML.
- En cas d'échec :

  ```ruby
  render :new, status: :unprocessable_entity
  ```

- La vue `_form.html.erb` inspecte `@model.errors` et applique les classes.

### 3.2. Retour JSON pour intégration fine avec Stimulus

Pour validation inline plus dynamique :

- Côté contrôleur, on renvoie les erreurs en JSON :

  ```ruby
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: "Utilisateur créé" }
        format.json { render json: { redirect_url: user_path(@user) }, status: :ok }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: format_validation_errors(@user), status: :unprocessable_entity }
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password)
  end

  def format_validation_errors(record)
    errors_hash = {}
    record.errors.messages.each do |field, messages|
      errors_hash[field] = messages
    end
    errors_hash
  end
  ```

- Stimulus analyse la réponse JSON et applique `is-invalid` + `invalid-feedback` champ par champ.

---

## 4. Structure Stimulus recommandée

### 4.1. Controller par formulaire (recommandé)

**Pourquoi ?**

- Le formulaire a un état unique :
  - Validité globale.
  - État du bouton submit.
- Les règles portent souvent sur plusieurs champs (ex : password + confirmation).
- Simplifie le wiring :
  - `data-controller="form-validation"`
  - Targets : `form`, `submitBtn`, éventuellement `field` si besoin.

**Pattern :**

- `connect()` :
  - Ajoute des listeners `blur` et `input` pour tous les `input/textarea/select`.
- `validateField(field)` :
  - Applique les règles client.
  - Ajoute ou supprime `is-invalid`.
- `updateSubmitButton()` :
  - Désactive le bouton si au moins un champ est invalide.

### 4.2. Controller par champ (optionnel)

Utile si :

- Comportement très spécifique par type de champ.
- Champs réutilisés dans plusieurs formulaires (ex: composant "EmailFieldController").

Mais pour un panel admin complet, **un controller par formulaire** est plus simple et maintenable.

---

## 5. Solution 1 : Validation serveur + Bootstrap (simple)

### 5.1. Modèle Rails

```ruby
# app/models/user.rb
class User < ApplicationRecord
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }
  validates :name, presence: true, length: { minimum: 3 }
end
```

### 5.2. Vue formulaire

```erb
<!-- app/views/users/_form.html.erb -->
<%= form_with(model: user, local: true, class: "needs-validation", novalidate: true) do |form| %>
  <% if user.errors.any? %>
    <div class="alert alert-danger">
      <strong><%= pluralize(user.errors.count, "erreur") %></strong>
      <ul>
        <% user.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="mb-3">
    <%= form.label :name, "Nom", class: "form-label" %>
    <%= form.text_field :name,
        class: ["form-control", user.errors[:name].any? ? "is-invalid" : ""],
        required: true,
        aria_label: "Nom complet",
        aria_required: "true",
        aria_invalid: user.errors[:name].any?.to_s,
        aria_describedby: user.errors[:name].any? ? "name-error" : nil %>

    <% if user.errors[:name].any? %>
      <div class="invalid-feedback d-block" id="name-error">
        <%= user.errors[:name].join(", ") %>
      </div>
    <% end %>
  </div>

  <div class="mb-3">
    <%= form.label :email, "Email", class: "form-label" %>
    <%= form.email_field :email,
        class: ["form-control", user.errors[:email].any? ? "is-invalid" : ""],
        required: true,
        aria_label: "Adresse email",
        aria_required: "true",
        aria_invalid: user.errors[:email].any?.to_s,
        aria_describedby: user.errors[:email].any? ? "email-error" : nil %>

    <% if user.errors[:email].any? %>
      <div class="invalid-feedback d-block" id="email-error">
        <%= user.errors[:email].join(", ") %>
      </div>
    <% end %>
  </div>

  <div class="mb-3">
    <%= form.label :password, "Mot de passe", class: "form-label" %>
    <%= form.password_field :password,
        class: ["form-control", user.errors[:password].any? ? "is-invalid" : ""],
        required: true,
        aria_label: "Mot de passe",
        aria_required: "true",
        aria_invalid: user.errors[:password].any?.to_s,
        aria_describedby: user.errors[:password].any? ? "password-error" : nil %>

    <% if user.errors[:password].any? %>
      <div class="invalid-feedback d-block" id="password-error">
        <%= user.errors[:password].join(", ") %>
      </div>
    <% end %>
  </div>

  <%= form.submit "Créer", class: "btn btn-primary" %>
<% end %>
```

### 5.3. Contrôleur Rails

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: "Utilisateur créé" }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password)
  end
end
```

**Avantages :** simple, 100 % serveur, pas de JS.  
**Limites :** pas de validation en temps réel, rechargement/refresh pour voir les erreurs.

---

## 6. Solution 2 : Validation client temps réel (RECOMMANDÉE)

### 6.1. Stimulus Controller

```javascript
// app/javascript/controllers/form_validation_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "submitBtn"]
  static values = { validationsUrl: String }

  connect() {
    this.formTarget = this.element

    this.element.querySelectorAll('input, textarea, select').forEach(field => {
      field.addEventListener('blur', () => this.validateField(field))
      field.addEventListener('input', () => {
        this.clearFieldError(field)
        this.updateSubmitButton()
      })
    })

    this.updateSubmitButton()
  }

  validateField(field) {
    const fieldName = this.extractFieldName(field)
    const value = field.value?.trim() ?? ""
    const errors = this.runClientValidations(fieldName, value)

    if (errors.length > 0) {
      this.showFieldError(field, errors)
    } else {
      this.clearFieldError(field)
    }

    this.updateSubmitButton()
  }

  extractFieldName(field) {
    // ex: user[email] -> "email"
    const name = field.name || ""
    if (name.includes("[")) {
      return name.split("[").pop().replace("]", "")
    }
    return name
  }

  runClientValidations(fieldName, value) {
    const errors = []

    if (fieldName === "name") {
      if (!value) errors.push("Le nom est requis")
      else if (value.length < 3) errors.push("Minimum 3 caractères")
    }

    if (fieldName === "email") {
      if (!value) errors.push("L'email est requis")
      else if (!this.isValidEmail(value)) errors.push("Email invalide")
    }

    if (fieldName === "password") {
      if (!value) errors.push("Le mot de passe est requis")
      else if (value.length < 8) errors.push("Minimum 8 caractères")
    }

    return errors
  }

  isValidEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
  }

  showFieldError(field, errors) {
    field.classList.add("is-invalid")
    field.classList.remove("is-valid")

    let feedbackDiv = this.getOrCreateFeedbackDiv(field)
    feedbackDiv.textContent = errors[0]

    field.setAttribute("aria-invalid", "true")
    field.setAttribute("aria-describedby", feedbackDiv.id)
  }

  clearFieldError(field) {
    field.classList.remove("is-invalid")
    field.classList.add("is-valid")

    const feedbackDiv = field.nextElementSibling
    if (feedbackDiv && feedbackDiv.classList.contains("invalid-feedback")) {
      feedbackDiv.remove()
    }

    field.setAttribute("aria-invalid", "false")
    field.removeAttribute("aria-describedby")
  }

  getOrCreateFeedbackDiv(field) {
    let feedbackDiv = field.nextElementSibling

    if (!feedbackDiv || !feedbackDiv.classList.contains("invalid-feedback")) {
      feedbackDiv = document.createElement("div")
      feedbackDiv.className = "invalid-feedback d-block"
      feedbackDiv.id = `${field.id || this.extractFieldName(field)}-error`
      field.parentNode.insertBefore(feedbackDiv, field.nextSibling)
    }

    return feedbackDiv
  }

  updateSubmitButton() {
    const hasErrors = this.element.querySelectorAll(".is-invalid").length > 0
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = hasErrors
    }
  }

  async submitForm(event) {
    event.preventDefault()

    // Re-valider tous les champs
    this.element.querySelectorAll("input, textarea, select").forEach(field => {
      this.validateField(field)
    })

    if (this.element.querySelectorAll(".is-invalid").length > 0) {
      return
    }

    const formData = new FormData(this.formTarget)

    const response = await fetch(this.formTarget.action, {
      method: this.formTarget.method || "POST",
      body: formData,
      headers: { "Accept": "application/json" }
    })

    if (response.ok) {
      const data = await response.json().catch(() => null)
      if (data?.redirect_url) {
        window.location.href = data.redirect_url
      } else if (response.url) {
        window.location.href = response.url
      }
    } else if (response.status === 422) {
      const errors = await response.json()
      this.handleServerErrors(errors)
      this.updateSubmitButton()
    } else {
      console.error("Unexpected error", response)
    }
  }

  handleServerErrors(errorsData) {
    Object.keys(errorsData).forEach(fieldName => {
      const field = this.element.querySelector(`[name$="[${fieldName}]"]`)
      if (field) {
        this.showFieldError(field, errorsData[fieldName])
      }
    })
  }
}
```

### 6.2. Vue formulaire (Bootstrap + Stimulus + ARIA)

```erb
<!-- app/views/users/_form.html.erb -->
<%= form_with(
  model: user,
  url: users_path,
  method: :post,
  data: {
    controller: "form-validation",
    action: "submit->form-validation#submitForm",
    "form-validation-validations-url-value": validations_user_path # si besoin
  },
  html: {
    class: "needs-validation",
    novalidate: true
  }
) do |form| %>

  <div class="mb-3">
    <%= form.label :name, "Nom complet", class: "form-label" %>
    <%= form.text_field :name,
        class: "form-control",
        required: true,
        aria: {
          label: "Votre nom complet",
          required: "true"
        },
        id: "user_name" %>
  </div>

  <div class="mb-3">
    <%= form.label :email, "Email", class: "form-label" %>
    <%= form.email_field :email,
        class: "form-control",
        required: true,
        aria: {
          label: "Adresse email",
          required: "true"
        },
        id: "user_email" %>
  </div>

  <div class="mb-3">
    <%= form.label :password, "Mot de passe", class: "form-label" %>
    <small class="text-muted d-block mb-2">Minimum 8 caractères</small>
    <%= form.password_field :password,
        class: "form-control",
        required: true,
        aria: {
          label: "Votre mot de passe",
          required: "true"
        },
        id: "user_password" %>
  </div>

  <%= form.submit "Créer mon compte",
      class: "btn btn-primary w-100",
      data: { "form-validation-target": "submitBtn" } %>
<% end %>
```

### 6.3. Contrôleur (HTML + JSON)

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: "Utilisateur créé" }
        format.json { render json: { redirect_url: user_path(@user) }, status: :ok }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: format_validation_errors(@user), status: :unprocessable_entity }
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password)
  end

  def format_validation_errors(record)
    record.errors.messages.transform_values do |messages|
      messages
    end
  end
end
```

---

## 7. Solution 3 : Validation temps réel côté serveur (AJAX / Turbo)

### 7.1. Stimulus Controller (validation asynchrone)

```javascript
// app/javascript/controllers/async_form_validation_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "submitBtn"]
  static values = { validationUrl: String }

  connect() {
    this.element.querySelectorAll("input, textarea, select").forEach(field => {
      field.addEventListener("blur", () => this.validateFieldAsync(field))
      field.addEventListener("input", () => this.debounceValidate(field))
    })
  }

  debounceValidate(field) {
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => this.validateFieldAsync(field), 400)
  }

  extractFieldName(field) {
    const name = field.name || ""
    if (name.includes("[")) {
      return name.split("[").pop().replace("]", "")
    }
    return name
  }

  async validateFieldAsync(field) {
    const fieldName = this.extractFieldName(field)
    const value = field.value

    try {
      const response = await fetch(this.validationUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          field: fieldName,
          value: value
        })
      })

      if (!response.ok) return

      const data = await response.json()

      if (data.valid) {
        this.clearFieldError(field)
      } else {
        this.showFieldError(field, data.errors)
      }

      this.updateSubmitButton()
    } catch (error) {
      console.error("Validation error:", error)
    }
  }

  showFieldError(field, errors) {
    field.classList.add("is-invalid")
    field.classList.remove("is-valid")

    let feedbackDiv = field.nextElementSibling
    if (!feedbackDiv || !feedbackDiv.classList.contains("invalid-feedback")) {
      feedbackDiv = document.createElement("div")
      feedbackDiv.className = "invalid-feedback d-block"
      feedbackDiv.id = `${field.id || this.extractFieldName(field)}-error`
      field.parentNode.insertBefore(feedbackDiv, field.nextSibling)
    }

    feedbackDiv.innerHTML = errors.map(e => `<small>${e}</small>`).join("<br>")

    field.setAttribute("aria-invalid", "true")
    field.setAttribute("aria-describedby", feedbackDiv.id)
  }

  clearFieldError(field) {
    field.classList.remove("is-invalid")
    field.classList.add("is-valid")

    const feedbackDiv = field.nextElementSibling
    if (feedbackDiv && feedbackDiv.classList.contains("invalid-feedback")) {
      feedbackDiv.remove()
    }

    field.setAttribute("aria-invalid", "false")
    field.removeAttribute("aria-describedby")
  }

  updateSubmitButton() {
    const hasErrors = this.element.querySelectorAll(".is-invalid").length > 0
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = hasErrors
    }
  }
}
```

### 7.2. Route + contrôleur de validation

```ruby
# config/routes.rb
post "validate_user_field", to: "validations#validate_user_field"
```

```ruby
# app/controllers/validations_controller.rb
class ValidationsController < ApplicationController
  def validate_user_field
    field = params[:field]
    value = params[:value]

    errors = validate_user(field, value)

    render json: { valid: errors.empty?, errors: errors }
  end

  private

  def validate_user(field, value)
    errors = []
    user = User.new(field.to_sym => value)

    case field
    when "name"
      user.valid?
      errors.concat(user.errors[:name])
    when "email"
      user.valid?
      errors.concat(user.errors[:email])
      if value.present? && User.exists?(email: value)
        errors << "Email déjà utilisé"
      end
    when "password"
      user.valid?
      errors.concat(user.errors[:password])
    end

    errors
  end
end
```

---

## 8. Accessibilité (ARIA) pour les erreurs

Bonnes pratiques à appliquer sur les champs :

- `aria-required="true"` pour les champs obligatoires.
- `aria-invalid="true"` lorsque le champ est invalide.
- `aria-describedby="id-du-message"` pour lier le champ au message d'erreur.

Dans Stimulus :

- Lors de `showFieldError` :
  - `field.setAttribute('aria-invalid', 'true')`
  - `field.setAttribute('aria-describedby', feedbackDiv.id)`
- Lors de `clearFieldError` :
  - `field.setAttribute('aria-invalid', 'false')`
  - `field.removeAttribute('aria-describedby')`

---

## 9. Comparaison des 3 solutions

| Critère                       | Solution 1 (Serveur) | Solution 2 (Hybride client) | Solution 3 (AJAX serveur)      |
|------------------------------|----------------------|-----------------------------|--------------------------------|
| Feedback temps réel          | Non                  | Oui (blur / input)          | Oui (blur / input, via serveur)|
| Complexité                   | Faible              | **Moyenne (recommandée)**   | Élevée                         |
| Sécurité                     | Très bonne          | Très bonne                  | Très bonne                     |
| Dupli. règles client/serveur | Non                 | Oui (minimale)              | Faible (plus côté serveur)     |
| Support modales / Turbo      | Basique              | Bon                          | Excellent                      |
| Accessibilité ARIA           | Basique             | **Très bonne**              | Très bonne                     |
| UX global                    | Moyen               | **Excellent**               | Excellent mais plus cher       |

---

## 10. Recommandation finale

Pour ton panel admin Rails + Bootstrap + Stimulus :

- Partir sur la **Solution 2** :
  - 1 **Stimulus controller par formulaire**.
  - Validation client sur `blur` + `input`.
  - Désactivation du bouton submit si des champs sont invalides.
  - Soumission via `fetch` avec `Accept: application/json`.
  - Traitement des erreurs Rails (422) et affichage inline.

- Optionnellement, pour certains champs critiques (email unique, slug, etc.), ajouter la **Solution 3** (validation asynchrone serveur) sur ces champs seulement.

Ce fichier contient tout le nécessaire pour plugger une implémentation clean, évolutive et accessible dans ton admin.
