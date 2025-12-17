# Dark Mode Panel Admin Rails + Bootstrap 5.3.2

## Solution 1 : **RECOMMANDÉE** - localStorage + Script en Head (Optimal pour FOWT)

### Avantages
✅ Aucune flash de thème incorrect
✅ localStorage simple et GDPR-friendly
✅ Exécution ultra-rapide avant rendu
✅ Pas de dépendance serveur
✅ Parfait pour panel admin

### Implémentation complète

#### 1. Rails Layout (`app/views/layouts/admin.html.erb`)

```erb
<!DOCTYPE html>
<html lang="fr" data-bs-theme="light">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    
    <!-- 🔴 CRITIQUE : Script AVANT Bootstrap CSS -->
    <!-- Prévient FOWT en appliquant le thème avant rendu -->
    <script>
      (function() {
        'use strict';
        
        // Récupère thème sauvegardé ou préférence système
        const getPreferredTheme = () => {
          const stored = localStorage.getItem('admin-theme');
          if (stored) {
            return stored; // 'light' ou 'dark'
          }
          // Fallback : préférence système
          return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
        };
        
        // Applique le thème IMMÉDIATEMENT
        const theme = getPreferredTheme();
        document.documentElement.setAttribute('data-bs-theme', theme);
      })();
    </script>
    
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body>
    <%= render 'shared/navbar' %>
    
    <main class="container-fluid mt-4">
      <%= yield %>
    </main>
  </body>
</html>
```

#### 2. Partial Navbar avec Toggle (`app/views/shared/_navbar.html.erb`)

```erb
<nav class="navbar navbar-expand-lg navbar-light bg-body-tertiary sticky-top">
  <div class="container-fluid">
    <a class="navbar-brand" href="<%= admin_path %>">Admin Panel</a>
    
    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" 
            data-bs-target="#navbarNav" aria-controls="navbarNav" 
            aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
    </button>

    <div class="collapse navbar-collapse" id="navbarNav">
      <ul class="navbar-nav ms-auto">
        <li class="nav-item">
          <button 
            id="theme-toggle" 
            class="btn btn-outline-secondary" 
            type="button"
            aria-label="Toggle dark mode"
            title="Dark/Light mode">
            <i class="theme-icon" id="theme-icon">☀️</i>
          </button>
        </li>
        <li class="nav-item dropdown">
          <a class="nav-link dropdown-toggle" href="#" id="userDropdown" 
             role="button" data-bs-toggle="dropdown">
            <%= current_user.email %>
          </a>
          <ul class="dropdown-menu dropdown-menu-end">
            <li><a class="dropdown-item" href="<%= account_settings_path %>">Settings</a></li>
            <li><hr class="dropdown-divider"></li>
            <li><a class="dropdown-item" href="<%= logout_path %>">Logout</a></li>
          </ul>
        </li>
      </ul>
    </div>
  </div>
</nav>
```

#### 3. JavaScript Controller Stimulus (`app/javascript/controllers/theme_controller.js`)

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.updateIcon();
    // Écoute changement de préférence système (si thème = 'auto')
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', 
      () => this.updateIcon()
    );
  }

  toggle() {
    const current = document.documentElement.getAttribute('data-bs-theme');
    const newTheme = current === 'light' ? 'dark' : 'light';
    
    // Applique le thème
    document.documentElement.setAttribute('data-bs-theme', newTheme);
    
    // Sauvegarde en localStorage
    localStorage.setItem('admin-theme', newTheme);
    
    // Met à jour l'icône
    this.updateIcon();
  }

  updateIcon() {
    const theme = document.documentElement.getAttribute('data-bs-theme');
    const icon = document.getElementById('theme-icon');
    
    if (theme === 'dark') {
      icon.textContent = '🌙';
      icon.classList.add('text-warning');
      icon.classList.remove('text-secondary');
    } else {
      icon.textContent = '☀️';
      icon.classList.remove('text-warning');
      icon.classList.add('text-secondary');
    }
  }
}
```

Connecter le controller au bouton :
```erb
<!-- Dans _navbar.html.erb -->
<button 
  id="theme-toggle" 
  data-controller="theme"
  data-action="click->theme#toggle"
  class="btn btn-outline-secondary" 
  type="button"
  aria-label="Toggle dark mode"
  title="Dark/Light mode">
  <i class="theme-icon" id="theme-icon">☀️</i>
</button>
```

#### 4. CSS Custom (`app/assets/stylesheets/admin.scss`)

```scss
// Transition smooth entre thèmes (sans transition au chargement initial)
// Ajouté après le premier toggle
html.theme-transitioning,
html.theme-transitioning * {
  transition: background-color 250ms ease-in-out,
              color 250ms ease-in-out,
              border-color 250ms ease-in-out !important;
}

// Icône du toggle
.theme-icon {
  font-size: 1.1rem;
  vertical-align: -0.15em;
  transition: opacity 200ms ease-in-out;
}

.theme-icon:hover {
  opacity: 0.8;
}

// Bootstrap dark mode styles (déjà inclus dans Bootstrap 5.3.2)
[data-bs-theme="dark"] {
  // Les variables CSS Bootstrap dark sont appliquées automatiquement
  // --bs-body-bg, --bs-body-color, etc.
}
```

Améliorer le transition smoothly :
```javascript
// Variante : ajouter transition classe seulement au toggle, pas au chargement
toggle() {
  const html = document.documentElement;
  const current = html.getAttribute('data-bs-theme');
  const newTheme = current === 'light' ? 'dark' : 'light';
  
  // Active les transitions
  html.classList.add('theme-transitioning');
  
  // Applique le thème
  html.setAttribute('data-bs-theme', newTheme);
  localStorage.setItem('admin-theme', newTheme);
  
  // Désactive transitions après (évite effet sur prochaines animations)
  setTimeout(() => {
    html.classList.remove('theme-transitioning');
    this.updateIcon();
  }, 250);
}
```

---

## Solution 2 : localStorage + Cookie Hybride (Production avancée)

### Cas d'usage
- SSR (Server-side rendering) qui a besoin du thème serveur
- Multiple devices/sync
- Analytics du thème préféré

### Implémentation Rails

```ruby
# config/initializers/dark_mode.rb
module DarkMode
  DEFAULT_THEME = 'light'
  COOKIE_NAME = 'admin_theme'
  COOKIE_EXPIRES = 1.year
end
```

```ruby
# app/helpers/admin_helper.rb
module AdminHelper
  def current_theme
    cookies[DarkMode::COOKIE_NAME] || DarkMode::DEFAULT_THEME
  end
  
  def set_theme_cookie(theme)
    cookies.encrypted[DarkMode::COOKIE_NAME] = {
      value: theme,
      expires: DarkMode::COOKIE_EXPIRES,
      same_site: :lax
    }
  end
end
```

```erb
<!-- Layout avec cookie en head -->
<script>
  const cookieTheme = '<%= current_theme %>';
  document.documentElement.setAttribute('data-bs-theme', cookieTheme);
  localStorage.setItem('admin-theme', cookieTheme);
</script>
```

```javascript
// Synchroniser cookie + localStorage
toggle() {
  // ...
  const newTheme = current === 'light' ? 'dark' : 'light';
  
  localStorage.setItem('admin-theme', newTheme);
  
  // Appel AJAX pour persister le cookie serveur
  fetch('/admin/api/theme', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
    },
    body: JSON.stringify({ theme: newTheme })
  });
}
```

---

## Solution 3 : CSS Custom Classes (Alternative sans data-bs-theme)

### Quand l'utiliser ?
- Legacy Bootstrap versions
- Overrides personnalisés poussés
- ⚠️ Plus verbeux, moins recommandé avec BS 5.3+

### Exemple

```scss
// app/assets/stylesheets/dark-mode.scss
:root {
  --theme-bg: #ffffff;
  --theme-text: #212529;
  --theme-border: #dee2e6;
}

[data-theme="dark"] {
  --theme-bg: #212529;
  --theme-text: #ffffff;
  --theme-border: #495057;
}

body {
  background-color: var(--theme-bg);
  color: var(--theme-text);
  border-color: var(--theme-border);
}

// Mais Bootstrap a déjà ces variables via data-bs-theme
// Donc cette approche est redondante avec BS 5.3+
```

---

## **Comparaison des solutions**

| Critère | Solution 1 ⭐ | Solution 2 | Solution 3 |
|---------|-----------|-----------|-----------|
| **FOWT** | ✅ Aucune | ⚠️ Minimal | ⚠️ Minimal |
| **localStorage** | ✅ Oui | ✅ Oui | ✅ Oui |
| **Persistence serveur** | ❌ Non | ✅ Oui | ❌ Non |
| **SSR-ready** | ❌ Non | ✅ Oui | ⚠️ Partial |
| **Simplicité** | ✅ Haute | ⚠️ Moyenne | ❌ Basse |
| **GDPR** | ✅ Optimal | ⚠️ Cookie géré | ✅ Optimal |
| **Performance** | ✅ Ultra-rapide | ⚠️ +1 requête | ✅ Rapide |
| **Maintenance** | ✅ Facile | ⚠️ Modérée | ❌ Complexe |

---

## **Checklist d'implémentation Solution 1**

- [ ] Ajouter script dans `<head>` avant Bootstrap CSS
- [ ] Créer Stimulus controller `theme_controller.js`
- [ ] Ajouter bouton toggle dans navbar
- [ ] Tester FOWT au hard-refresh (`Cmd+Shift+R`)
- [ ] Vérifier localStorage save/restore
- [ ] Tester icône update (☀️ ↔️ 🌙)
- [ ] Vérifier transition smooth (250ms)
- [ ] Tester tous les composants Bootstrap (btn, card, table, form)
- [ ] Vérifier accessibility (aria-label, focus states)
- [ ] Tester sur Turbo (si utilisé) - ajouter data-turbo-permanent si besoin

---

## **Accessibilité**

```erb
<!-- Ajouter dans navbar -->
<button 
  id="theme-toggle"
  class="btn btn-outline-secondary"
  aria-label="Toggle dark mode (currently: light)"
  aria-pressed="false">
  <i class="theme-icon">☀️</i>
</button>
```

```javascript
// Mettre à jour aria-label et aria-pressed
updateIcon() {
  const theme = document.documentElement.getAttribute('data-bs-theme');
  const btn = document.getElementById('theme-toggle');
  
  btn.setAttribute('aria-pressed', theme === 'dark' ? 'true' : 'false');
  btn.setAttribute('aria-label', `Toggle dark mode (currently: ${theme})`);
}
```

---

## **CSS Bootstrap Variables disponibles en Dark Mode**

```scss
// Disponibles automatiquement avec data-bs-theme="dark"
[data-bs-theme="dark"] {
  --bs-body-bg: #{$gray-900};
  --bs-body-color: #{$gray-100};
  --bs-link-color: #{$info};
  --bs-link-hover-color: #{tint-color($info, 15%)};
  --bs-code-color: #{$pink-500};
  --bs-border-color: #{$gray-700};
  --bs-table-striped-bg: #{rgba(255, 255, 255, 0.05)};
  --bs-table-striped-color: #{$body-color};
  --bs-form-check-input-bg: #{$body-bg};
  --bs-form-check-input-border: #{$body-color};
  // ... +50 variables
}
```

Vous pouvez les utiliser dans vos custom styles :
```scss
.my-component {
  background: var(--bs-body-bg);
  color: var(--bs-body-color);
  border: 1px solid var(--bs-border-color);
}
```

---

## **Troubleshooting**

### Flash blanc au chargement ?
→ Le script DOIT être dans `<head>` AVANT Bootstrap CSS

### localStorage ne persiste pas ?
→ Vérifier mode incognito (localStorage désactivé)
→ Vérifier HTTPS (certains navigateurs requièrent HTTPS)

### Icône ne change pas ?
→ Vérifier `data-bs-theme` sur `<html>`
→ Vérifier console pour erreurs JavaScript

### Transition trop rapide/lente ?
→ Ajuster `transition: ... 250ms ease-in-out;` dans CSS
→ Augmenter/diminuer selon préférence (200-300ms recommandé)

### Bootstrap dark mode partiellement appliqué ?
→ Vérifier que vous utilisez Bootstrap 5.3+ (< 5.3 pas de dark mode natif)
→ Vérifier que CSS Bootstrap est chargée correctement
