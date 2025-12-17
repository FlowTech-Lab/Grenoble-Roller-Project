# Référence CSS Classes - Panel Admin

**Objectif** : Référence complète des classes CSS disponibles pour le développement du panel admin  
**Base** : Bootstrap 5.3.2 + Liquid Design Theme custom

---

## 🎨 Classes Bootstrap Standards Disponibles

### Layout & Container

| Classe | Usage | Exemple |
|--------|-------|---------|
| `container` | Container responsive standard | `<div class="container">` |
| `container-fluid` | Container pleine largeur | `<div class="container-fluid">` |
| `row` | Ligne de grille | `<div class="row">` |
| `col-*` | Colonnes responsive | `col-12`, `col-md-6`, `col-lg-4` |
| `d-flex` | Display flex | `<div class="d-flex">` |
| `flex-column` | Direction colonne | `d-flex flex-column` |
| `align-items-center` | Alignement vertical | `d-flex align-items-center` |
| `justify-content-between` | Espacement horizontal | `d-flex justify-content-between` |
| `gap-*` | Espacement entre éléments | `gap-2`, `gap-3`, `gap-4` |

**Référence** : `app/views/layouts/_navbar.html.erb`, `app/views/products/show.html.erb`

---

### Cards & Panels

| Classe | Usage | Exemple |
|--------|-------|---------|
| `card` | Carte Bootstrap standard | `<div class="card">` |
| `card-body` | Corps de carte | `<div class="card-body">` |
| `card-header` | En-tête de carte | `<div class="card-header">` |
| `card-footer` | Pied de carte | `<div class="card-footer">` |
| `card-title` | Titre dans carte | `<h5 class="card-title">` |
| `card-text` | Texte dans carte | `<p class="card-text">` |
| `h-100` | Hauteur 100% | `card h-100` |

**Référence** : `app/views/events/_event_card.html.erb`, `app/views/products/show.html.erb`

---

### Custom Liquid Classes (Projet Grenoble Roller)

#### Cards Liquid

| Classe | Usage | Fichier CSS | Exemple |
|--------|-------|-------------|---------|
| `card-liquid` | Carte avec style liquid (glass effect) | `_style.scss` | `<div class="card card-liquid">` |
| `rounded-liquid` | Border radius liquid | `_style.scss` | `card-liquid rounded-liquid` |
| `shadow-liquid` | Ombre liquid | `_style.scss` | `card-liquid shadow-liquid` |

**Référence** : `app/views/events/_event_card.html.erb` (ligne 8), `app/views/products/show.html.erb` (ligne 37)

#### Buttons Liquid

| Classe | Usage | Fichier CSS | Exemple |
|--------|-------|-------------|---------|
| `btn-liquid-primary` | Bouton primary avec gradient | `_style.scss` | `<button class="btn btn-liquid-primary">` |
| `btn-liquid-success` | Bouton success avec gradient | `_style.scss` | `<button class="btn btn-liquid-success">` |
| `btn-outline-primary` | Bouton outline primary | Bootstrap | `<button class="btn btn-outline-primary">` |
| `btn-outline-secondary` | Bouton outline secondary | Bootstrap | `<button class="btn btn-outline-secondary">` |
| `btn-sm` | Bouton petit | Bootstrap | `btn btn-sm` |

**Référence** : `app/views/layouts/_navbar.html.erb` (ligne 148), `app/views/events/_event_card.html.erb` (ligne 167)

#### Text Colors Liquid

| Classe | Usage | Fichier CSS | Exemple |
|--------|-------|-------------|---------|
| `text-liquid-primary` | Texte couleur primary | `_style.scss` | `<i class="bi bi-calendar text-liquid-primary">` |
| `text-liquid-success` | Texte couleur success | `_style.scss` | `<i class="bi bi-check text-liquid-success">` |
| `text-liquid-danger` | Texte couleur danger | `_style.scss` | `<span class="text-liquid-danger">` |
| `text-liquid-info` | Texte couleur info | `_style.scss` | `<span class="text-liquid-info">` |
| `text-muted` | Texte muted | Bootstrap | `<p class="text-muted">` |
| `text-body-secondary` | Texte body secondaire | Bootstrap | `<p class="text-body-secondary">` |

**Référence** : `app/views/layouts/_navbar.html.erb` (ligne 47), `app/views/events/_event_card.html.erb` (ligne 28)

#### Badges Liquid

| Classe | Usage | Fichier CSS | Exemple |
|--------|-------|-------------|---------|
| `badge-liquid-primary` | Badge primary liquid | `_style.scss` | `<span class="badge badge-liquid-primary">` |
| `badge-liquid-success` | Badge success liquid | `_style.scss` | `<span class="badge badge-liquid-success">` |
| `badge-liquid-danger` | Badge danger liquid | `_style.scss` | `<span class="badge badge-liquid-danger">` |
| `badge-liquid-secondary` | Badge secondary liquid | `_style.scss` | `<span class="badge badge-liquid-secondary">` |
| `bg-primary`, `bg-success`, `bg-danger`, `bg-warning`, `bg-info` | Badges Bootstrap standards | Bootstrap | `<span class="badge bg-success">` |

**Référence** : `app/views/events/_event_card.html.erb` (ligne 13, 74, 113), `app/views/products/show.html.erb` (ligne 80)

#### Navbar Liquid

| Classe | Usage | Fichier CSS | Exemple |
|--------|-------|-------------|---------|
| `navbar-liquid` | Navbar avec style liquid | `_style.scss` | `<nav class="navbar navbar-liquid">` |
| `navbar-logo-light` | Logo pour thème clair | `_style.scss` | `<img class="navbar-logo navbar-logo-light">` |
| `navbar-logo-dark` | Logo pour thème sombre | `_style.scss` | `<img class="navbar-logo navbar-logo-dark">` |

**Référence** : `app/views/layouts/_navbar.html.erb` (lignes 11, 14-15)

---

### Tables Bootstrap

| Classe | Usage | Exemple |
|--------|-------|---------|
| `table` | Table Bootstrap | `<table class="table">` |
| `table-striped` | Table avec rayures | `<table class="table table-striped">` |
| `table-hover` | Table avec hover | `<table class="table table-hover">` |
| `table-bordered` | Table avec bordures | `<table class="table table-bordered">` |
| `table-sm` | Table compacte | `<table class="table table-sm">` |
| `thead-light` | En-tête clair | `<thead class="thead-light">` |
| `thead-dark` | En-tête sombre | `<thead class="thead-dark">` |

**Référence** : À utiliser pour les tables dans le panel admin

---

### Forms Bootstrap

| Classe | Usage | Exemple |
|--------|-------|---------|
| `form-control` | Input standard | `<input class="form-control">` |
| `form-select` | Select dropdown | `<select class="form-select">` |
| `form-check` | Checkbox/radio container | `<div class="form-check">` |
| `form-check-input` | Checkbox/radio input | `<input class="form-check-input">` |
| `form-check-label` | Label pour checkbox/radio | `<label class="form-check-label">` |
| `form-label` | Label standard | `<label class="form-label">` |
| `form-text` | Aide texte | `<div class="form-text">` |
| `is-invalid` | État invalide | `<input class="form-control is-invalid">` |
| `is-valid` | État valide | `<input class="form-control is-valid">` |
| `invalid-feedback` | Message d'erreur | `<div class="invalid-feedback">` |

**Référence** : `app/views/devise/registrations/edit.html.erb`

---

### Navigation & Sidebar

| Classe | Usage | Exemple |
|--------|-------|---------|
| `navbar` | Navbar Bootstrap | `<nav class="navbar">` |
| `navbar-nav` | Liste de navigation | `<ul class="navbar-nav">` |
| `nav-item` | Item de navigation | `<li class="nav-item">` |
| `nav-link` | Lien de navigation | `<a class="nav-link">` |
| `dropdown` | Dropdown container | `<div class="dropdown">` |
| `dropdown-menu` | Menu dropdown | `<ul class="dropdown-menu">` |
| `dropdown-item` | Item dropdown | `<a class="dropdown-item">` |
| `offcanvas` | Sidebar offcanvas (Bootstrap 5) | `<div class="offcanvas offcanvas-start">` |
| `offcanvas-header` | En-tête offcanvas | `<div class="offcanvas-header">` |
| `offcanvas-body` | Corps offcanvas | `<div class="offcanvas-body">` |
| `collapse` | Contenu collapsible | `<div class="collapse">` |

**Référence** : `app/views/layouts/_navbar.html.erb`, Bootstrap 5 Offcanvas docs

---

### Breadcrumb

| Classe | Usage | Exemple |
|--------|-------|---------|
| `breadcrumb` | Container breadcrumb | `<ol class="breadcrumb">` |
| `breadcrumb-item` | Item breadcrumb | `<li class="breadcrumb-item">` |
| `active` | Item actif | `<li class="breadcrumb-item active">` |

**Référence** : `app/views/products/show.html.erb` (lignes 7-13)

---

### Alerts & Toasts

| Classe | Usage | Exemple |
|--------|-------|---------|
| `alert` | Container alert | `<div class="alert">` |
| `alert-success` | Alert success | `<div class="alert alert-success">` |
| `alert-danger` | Alert danger | `<div class="alert alert-danger">` |
| `alert-warning` | Alert warning | `<div class="alert alert-warning">` |
| `alert-info` | Alert info | `<div class="alert alert-info">` |
| `toast` | Container toast | `<div class="toast">` |
| `toast-header` | En-tête toast | `<div class="toast-header">` |
| `toast-body` | Corps toast | `<div class="toast-body">` |
| `toast-container` | Container pour toasts | `<div class="toast-container position-fixed">` |

**Référence** : `app/views/layouts/_flash.html.erb`, `app/views/products/show.html.erb` (ligne 20)

---

### Modals Bootstrap

| Classe | Usage | Exemple |
|--------|-------|---------|
| `modal` | Container modal | `<div class="modal fade">` |
| `modal-dialog` | Dialog modal | `<div class="modal-dialog">` |
| `modal-dialog-centered` | Dialog centré | `<div class="modal-dialog modal-dialog-centered">` |
| `modal-content` | Contenu modal | `<div class="modal-content">` |
| `modal-header` | En-tête modal | `<div class="modal-header">` |
| `modal-title` | Titre modal | `<h2 class="modal-title">` |
| `modal-body` | Corps modal | `<div class="modal-body">` |
| `modal-footer` | Pied modal | `<div class="modal-footer">` |

**Référence** : `app/views/events/_event_card.html.erb` (ligne 224)

---

### Typography

| Classe | Usage | Exemple |
|--------|-------|---------|
| `h1` à `h6` | Titres | `<h1>`, `<h2>`, etc. |
| `fw-bold` | Font weight bold | `<span class="fw-bold">` |
| `fw-semibold` | Font weight semibold | `<span class="fw-semibold">` |
| `small` | Texte petit | `<p class="small">` |
| `lead` | Paragraphe lead | `<p class="lead">` |
| `text-center` | Texte centré | `<p class="text-center">` |
| `text-start` | Texte aligné à gauche | `<p class="text-start">` |
| `text-end` | Texte aligné à droite | `<p class="text-end">` |

**Référence** : `app/views/products/show.html.erb`

---

### Spacing (Utility Classes)

| Classe | Usage | Exemple |
|--------|-------|---------|
| `m-*` | Margin | `m-0`, `m-1`, `m-2`, `m-3`, `m-4`, `m-5` |
| `mt-*` | Margin top | `mt-2`, `mt-3` |
| `mb-*` | Margin bottom | `mb-2`, `mb-4` |
| `ms-*` | Margin start | `ms-2` |
| `me-*` | Margin end | `me-2` |
| `p-*` | Padding | `p-0`, `p-1`, `p-2`, `p-3`, `p-4` |
| `pt-*` | Padding top | `pt-4` |
| `pb-*` | Padding bottom | `pb-4`, `pb-5` |
| `px-*` | Padding horizontal | `px-3` |
| `py-*` | Padding vertical | `py-4`, `py-lg-5` |

**Référence** : Utilisé partout dans les vues

---

### Display & Visibility

| Classe | Usage | Exemple |
|--------|-------|---------|
| `d-none` | Display none | `<div class="d-none">` |
| `d-block` | Display block | `<div class="d-block">` |
| `d-inline` | Display inline | `<span class="d-inline">` |
| `d-inline-block` | Display inline-block | `<span class="d-inline-block">` |
| `d-flex` | Display flex | `<div class="d-flex">` |
| `d-md-none` | Masqué sur md+ | `<div class="d-md-none">` |
| `d-none d-md-block` | Masqué sur mobile, visible md+ | `<div class="d-none d-md-block">` |
| `visually-hidden` | Visuellement caché (screen readers) | `<span class="visually-hidden">` |

**Référence** : `app/views/layouts/_navbar.html.erb` (ligne 69)

---

### Position & Layout

| Classe | Usage | Exemple |
|--------|-------|---------|
| `position-fixed` | Position fixed | `<div class="position-fixed">` |
| `position-sticky` | Position sticky | `<nav class="position-sticky">` |
| `position-absolute` | Position absolute | `<span class="position-absolute">` |
| `sticky-top` | Sticky en haut | `<nav class="sticky-top">` |
| `top-0`, `end-0`, `bottom-0`, `start-0` | Position absolue | `position-fixed top-0 end-0` |

**Référence** : `app/views/layouts/_flash.html.erb` (ligne 3)

---

### Icons (Bootstrap Icons)

**Format** : `<i class="bi bi-icon-name">`

Exemples utilisés dans le projet :
- `bi-calendar-event` : Calendrier
- `bi-book` : Livre
- `bi-info-circle` : Info
- `bi-bag` : Sac (boutique)
- `bi-plus-circle` : Plus
- `bi-person-circle` : Personne
- `bi-shield-check` : Bouclier (admin)
- `bi-gear` : Engrenage
- `bi-box-arrow-right` : Déconnexion
- `bi-person-plus` : Inscription
- `bi-box-arrow-in-right` : Connexion
- `bi-basket` : Panier
- `bi-check-circle` : Check
- `bi-exclamation-triangle` : Alerte
- `bi-x-circle` : Croix
- `bi-star-fill` : Étoile
- `bi-people-fill` : Groupe
- `bi-eye` : Œil (voir)
- `bi-calendar-x` : Calendrier avec croix
- `bi-calendar-plus` : Calendrier avec plus
- `bi-calendar-check` : Calendrier avec check
- `bi-tag` : Tag
- `bi-image` : Image
- `bi-chevron-right` : Flèche droite
- `bi-envelope` : Enveloppe
- `bi-geo-alt` : Localisation

**Référence** : `app/views/layouts/_navbar.html.erb`, `app/views/events/_event_card.html.erb`

---

## 🎨 Variables CSS Custom (Liquid Theme)

Variables disponibles dans `:root` (voir `_style.scss`) :

```scss
--gr-primary: #007bff;
--gr-primary-light: #5aa9fa;
--gr-primary-dark: #0056b3;
--gr-success: #0d6322;
--gr-warning: #7e4900;
--gr-danger: #911a14;
--gr-info: #2782bb;
--liquid-glass-bg: rgba(255,255,255,0.35);
--liquid-glass-border: rgba(255,255,255,0.2);
--liquid-blur: blur(12px);
--gradient-liquid-primary: linear-gradient(135deg, #1e8dff 0%, #1ea0ff 100%);
--gradient-liquid-success: linear-gradient(135deg, var(--gr-success) 0%, #0d6322 100%);
--transition-liquid: all 300ms ease;
--shadow-hover: 0 2px 4px rgba(0, 0, 0, 0.15);
```

---

## 🎯 Recommandations Panel Admin

### Pour la Sidebar

**Classes recommandées** :
- `offcanvas offcanvas-start` : Sidebar mobile (Bootstrap 5)
- `bg-dark text-white` : Sidebar dark theme
- `card card-liquid` : Pour desktop (style liquid)
- `nav nav-pills flex-column` : Menu navigation

### Pour les Tables

**Classes recommandées** :
- `table table-striped table-hover` : Table standard
- `table-sm` : Table compacte si besoin
- `thead-dark` ou `thead-light` : En-tête selon thème

### Pour les Formulaires

**Classes recommandées** :
- `form-control`, `form-select`, `form-check` : Standards Bootstrap
- `mb-3` : Espacement entre champs
- `is-invalid`, `invalid-feedback` : Validation

### Pour les Boutons Actions

**Classes recommandées** :
- `btn btn-liquid-primary` : Actions principales
- `btn btn-outline-secondary` : Actions secondaires
- `btn btn-sm` : Boutons compacts dans tableaux
- `btn btn-outline-danger` : Actions destructives

---

## 📝 Notes Importantes

1. **Thème Dark** : Le projet supporte `data-bs-theme="dark"` (voir `application.html.erb`)
2. **Liquid Theme** : Classes custom `*-liquid-*` pour le style "liquid design"
3. **Bootstrap Icons** : Toujours utiliser `bi bi-icon-name` avec `aria-hidden="true"`
4. **Accessibilité** : Toujours ajouter `aria-label` sur les boutons icon-only

---

## 🔗 Références Fichiers

- **CSS Custom** : `app/assets/stylesheets/_style.scss`
- **Bootstrap** : Inclus via `application.bootstrap.scss`
- **Exemples Navbar** : `app/views/layouts/_navbar.html.erb`
- **Exemples Cards** : `app/views/events/_event_card.html.erb`
- **Exemples Forms** : `app/views/devise/registrations/edit.html.erb`
- **Exemples Toast** : `app/views/layouts/_flash.html.erb`

---

---

## 🔗 Références Croisées

- **[START_HERE.md](START_HERE.md)** - Guide de démarrage complet
- **[RESUME_DECISIONS.md](RESUME_DECISIONS.md)** - Résumé des décisions techniques
- **[plan-implementation.md](plan-implementation.md)** - Plan d'implémentation complet
- **[descisions/](descisions/)** - Guides techniques détaillés (Perplexity)

---

**Document créé le** : 2025-01-27  
**Dernière mise à jour** : 2025-01-27  
**Version** : 1.0

