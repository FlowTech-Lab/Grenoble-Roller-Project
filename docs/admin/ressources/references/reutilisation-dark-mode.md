# Réutilisation Dark Mode - Panel Admin

**Objectif** : Documenter comment réutiliser le dark mode existant pour le panel admin  
**Statut** : ✅ Déjà implémenté dans le projet

---

## 🎨 Dark Mode Existant

### Implémentation Actuelle

Le projet a déjà un dark mode complet et fonctionnel :

#### 1. Toggle dans la Navbar
**Fichier** : `app/views/layouts/_navbar.html.erb` (lignes 62-72)

```erb
<button 
  type="button"
  class="btn btn-outline-primary theme-toggle" 
  id="theme-toggle"
  aria-label="Basculer entre thème clair et thème sombre"
  aria-pressed="false"
  onclick="toggleTheme()">
  <i class="bi bi-sun-fill d-none" id="theme-icon-sun" aria-hidden="true"></i>
  <i class="bi bi-moon-fill" id="theme-icon-moon" aria-hidden="true"></i>
  <span class="visually-hidden">Changer le thème</span>
</button>
```

#### 2. Fonction JavaScript
**Fichier** : `app/views/layouts/application.html.erb` (lignes 44-105)

```javascript
function toggleTheme() {
  const html = document.documentElement;
  const currentTheme = html.getAttribute('data-bs-theme');
  const newTheme = currentTheme === 'light' ? 'dark' : 'light';
  
  html.setAttribute('data-bs-theme', newTheme);
  
  // Mise à jour icônes, ARIA, localStorage
  localStorage.setItem('theme', newTheme);
}

// Initialisation au chargement
document.addEventListener('DOMContentLoaded', function() {
  const savedTheme = localStorage.getItem('theme') || 'light';
  html.setAttribute('data-bs-theme', savedTheme);
  // ...
});
```

#### 3. Support CSS
**Fichier** : `app/assets/stylesheets/_style.scss`

- Variables CSS pour dark mode dans `:root` et `[data-bs-theme=dark]`
- Classes custom avec support dark mode (ex: `[data-bs-theme=dark] .navbar-logo-light`)

#### 4. Bootstrap Natif
- Bootstrap 5.3.2 supporte `data-bs-theme="dark"` nativement
- Toutes les classes Bootstrap s'adaptent automatiquement

---

## ✅ Réutilisation pour Panel Admin

### Ce qui fonctionne automatiquement

1. **Layout Admin** : Le layout admin utilisera le même `<html data-bs-theme="...">`, donc le dark mode fonctionne automatiquement

2. **Classes Bootstrap** : Toutes les classes Bootstrap utilisées dans le panel admin (tables, forms, cards, buttons, etc.) supportent déjà le dark mode

3. **Classes Liquid Custom** : Les classes custom du projet (`card-liquid`, `btn-liquid-primary`, etc.) ont déjà le support dark mode dans `_style.scss`

### Ce qu'il faut vérifier

1. **Layout Admin** : S'assurer que le layout admin utilise le même `<html>` avec `data-bs-theme`
   - Si layout séparé : Copier l'attribut `data-bs-theme` du layout principal
   - Si layout hérite : Le thème est déjà disponible

2. **Toggle Visible** : Le toggle dans la navbar globale sera visible dans le panel admin
   - ✅ Déjà présent dans `_navbar.html.erb`
   - Pas besoin de dupliquer

3. **Classes Custom Admin** : Si nouvelles classes CSS créées pour le panel admin :
   - Ajouter le support dark mode avec `[data-bs-theme=dark]` dans `_style.scss`

---

## 📝 Exemple Layout Admin

```erb
<!-- app/views/layouts/admin.html.erb -->
<!DOCTYPE html>
<html lang="fr" data-bs-theme="light">  <!-- ✅ Hérite du thème existant -->
  <head>
    <!-- ... -->
  </head>
  
  <body>
    <!-- Navbar globale avec toggle dark mode -->
    <%= render 'layouts/navbar' %>
    
    <!-- Contenu panel admin -->
    <div class="admin-panel">
      <!-- Le dark mode fonctionne automatiquement -->
    </div>
  </body>
</html>
```

**Note** : Si on utilise un layout complètement séparé, il faudra aussi inclure le script `toggleTheme()` ou le convertir en Stimulus controller.

---

## 🎯 Recommandation

### Option 1 : Layout qui hérite (RECOMMANDÉ)
- Utiliser le même `<html>` que le layout principal
- Le dark mode fonctionne automatiquement
- Pas de duplication de code

### Option 2 : Layout séparé
- Copier le script `toggleTheme()` dans le layout admin
- Ou convertir en Stimulus controller réutilisable
- S'assurer que `data-bs-theme` est synchronisé

---

## ✅ Checklist US-017 (Dark Mode)

- [x] Toggle dark/light existe (navbar globale)
- [x] Persistence localStorage fonctionne
- [x] Bootstrap dark mode supporté (`data-bs-theme`)
- [x] CSS custom avec support dark mode
- [ ] Vérifier que layout admin hérite du thème
- [ ] Tester toutes les classes admin en dark mode
- [ ] Ajouter support dark mode si nouvelles classes CSS créées

---

## 🔗 Références

- **Toggle Navbar** : `app/views/layouts/_navbar.html.erb`
- **Script Theme** : `app/views/layouts/application.html.erb`
- **CSS Dark Mode** : `app/assets/stylesheets/_style.scss` (section `[data-bs-theme=dark]`)

---

**Conclusion** : Le dark mode est déjà complet. Pour le panel admin, il suffit de réutiliser ce qui existe. Pas besoin de réimplémenter ou de demander à Perplexity.

---

## 🔗 Références Croisées

- **[START_HERE.md](START_HERE.md)** - Guide de démarrage (US-017 mentionne dark mode)
- **[RESUME_DECISIONS.md](RESUME_DECISIONS.md)** - Décision US-017 : déjà implémenté
- **[plan-implementation.md](plan-implementation.md)** - US-017 dans le plan
- **[descisions/darkmode-rails.md](descisions/darkmode-rails.md)** - Guide Perplexity (informations complémentaires)

---

**Document créé le** : 2025-01-27  
**Dernière mise à jour** : 2025-01-27  
**Version** : 1.0

