# 🎨 Grenoble Roller - Liquid Apple 2025 Theme

## 📋 Vue d'ensemble

Le thème **Liquid Apple 2025** est un design system premium inspiré des dernières tendances Apple, spécialement adapté pour l'association Grenoble Roller. Il combine l'élégance du design Apple avec l'identité visuelle de Grenoble Roller.

## ✨ Caractéristiques principales

### 🎯 **Design Liquid Apple 2025**
- **Glass Morphism** : Effets de transparence et de flou
- **Dégradés organiques** : Couleurs douces et naturelles
- **Animations subtiles** : Micro-interactions fluides
- **Typographie Apple** : Police SF Pro Display/Text
- **Ombres liquides** : Effets d'ombre sophistiqués

### 🎨 **Palette de couleurs Grenoble Roller**
```css
--gr-primary: #007AFF;      /* Bleu Apple */
--gr-secondary: #8E8E93;    /* Gris Apple */
--gr-accent: #FF3B30;        /* Rouge Apple */
--gr-success: #34C759;      /* Vert Apple */
--gr-warning: #FF9500;       /* Orange Apple */
```

### 🔧 **Composants disponibles**

#### **Boutons Liquid**
```html
<button class="btn btn-liquid btn-liquid-primary">Primary</button>
<button class="btn btn-liquid btn-liquid-secondary">Secondary</button>
<button class="btn btn-liquid btn-liquid-accent">Accent</button>
```

#### **Cartes Liquid**
```html
<div class="card-liquid">
    <div class="card-liquid-header">
        <h5 class="card-title">Titre</h5>
    </div>
    <div class="card-liquid-body">
        <p class="card-text">Contenu de la carte</p>
    </div>
</div>
```

#### **Formulaires Liquid**
```html
<input type="email" class="form-control-liquid" placeholder="email@example.com">
<textarea class="form-control-liquid" rows="3"></textarea>
```

#### **Alertes Liquid**
```html
<div class="alert-liquid alert-liquid-primary">
    <strong>Primary!</strong> Message d'alerte
</div>
```

## 🚀 Installation et utilisation

### **1. Fichiers requis**
```html
<!-- Bootstrap Icons -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
<!-- Thème Liquid Apple 2025 -->
<link rel="stylesheet" href="liquid-apple-2025.css">
```

### **2. Structure HTML de base**
```html
<!DOCTYPE html>
<html lang="fr" data-bs-theme="light">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Grenoble Roller - Liquid Apple 2025</title>
    <link rel="stylesheet" href="liquid-apple-2025.css">
</head>
<body>
    <!-- Votre contenu ici -->
</body>
</html>
```

### **3. Support des thèmes clair/sombre**
```javascript
// Toggle de thème
function toggleTheme() {
    const html = document.documentElement;
    const currentTheme = html.getAttribute('data-bs-theme');
    const newTheme = currentTheme === 'light' ? 'dark' : 'light';
    html.setAttribute('data-bs-theme', newTheme);
}
```

## 🎨 Classes utilitaires

### **Couleurs**
```css
.text-liquid-primary    /* Texte bleu Apple */
.text-liquid-secondary  /* Texte gris Apple */
.text-liquid-accent     /* Texte rouge Apple */
.bg-liquid-primary     /* Fond bleu dégradé */
.bg-liquid-secondary   /* Fond gris dégradé */
```

### **Ombres**
```css
.shadow-liquid          /* Ombre liquide standard */
.shadow-liquid-hover    /* Ombre au survol */
.shadow-liquid-inset    /* Ombre intérieure */
.shadow-liquid-glow     /* Ombre avec lueur */
```

### **Bordures**
```css
.rounded-liquid         /* Bordure arrondie standard */
.rounded-liquid-sm      /* Bordure arrondie petite */
.rounded-liquid-lg      /* Bordure arrondie grande */
.rounded-liquid-full    /* Bordure complètement arrondie */
```

## 🎭 Animations disponibles

### **Classes d'animation**
```css
.liquid-float           /* Animation de flottement */
.liquid-glow            /* Animation de lueur */
.liquid-pulse           /* Animation de pulsation */
```

### **Transitions**
```css
--transition-fast       /* 0.15s cubic-bezier */
--transition-normal      /* 0.3s cubic-bezier */
--transition-slow        /* 0.5s cubic-bezier */
--transition-bounce       /* 0.3s cubic-bezier bounce */
```

## 📱 Responsive Design

### **Breakpoints**
```css
--breakpoint-sm: 576px;
--breakpoint-md: 768px;
--breakpoint-lg: 992px;
--breakpoint-xl: 1200px;
--breakpoint-2xl: 1400px;
```

### **Adaptations mobiles**
- Réduction des marges sur petits écrans
- Optimisation des boutons pour le tactile
- Navigation adaptée aux écrans tactiles

## ♿ Accessibilité

### **Conformité WCAG 2.2**
- Contraste suffisant (ratio 4.5:1 minimum)
- Navigation au clavier
- Support des lecteurs d'écran
- Focus visible sur tous les éléments interactifs

### **Bonnes pratiques**
```html
<!-- Labels explicites -->
<label for="email">Email</label>
<input type="email" id="email" class="form-control-liquid">

<!-- Attributs ARIA -->
<button class="btn btn-liquid" aria-label="Fermer">
    <i class="bi bi-x"></i>
</button>
```

## 🚀 Performance

### **Optimisations incluses**
- **Backdrop-filter** avec fallback pour les navigateurs non supportés
- **Transitions CSS** optimisées avec `cubic-bezier`
- **Animations** avec `will-change` pour l'accélération GPU
- **Media queries** pour les animations réduites

### **Bonnes pratiques**
```css
/* Désactiver les animations pour les utilisateurs préférant les mouvements réduits */
@media (prefers-reduced-motion: reduce) {
    .liquid-float,
    .liquid-glow,
    .liquid-pulse {
        animation: none;
    }
}
```

## 🎯 Cas d'usage Grenoble Roller

### **Page d'accueil**
```html
<div class="liquid-glass p-5 text-center">
    <h1 class="display-4 mb-4">Grenoble Roller</h1>
    <p class="lead mb-4">Association de roller à Grenoble</p>
    <button class="btn btn-liquid btn-liquid-primary">Rejoindre</button>
</div>
```

### **Formulaire d'inscription**
```html
<div class="liquid-glass p-4">
    <h3>Inscription</h3>
    <form>
        <div class="mb-3">
            <label for="nom" class="form-label">Nom</label>
            <input type="text" class="form-control-liquid" id="nom">
        </div>
        <button type="submit" class="btn btn-liquid btn-liquid-primary">S'inscrire</button>
    </form>
</div>
```

### **Carte d'événement**
```html
<div class="card-liquid">
    <div class="card-liquid-header">
        <h5 class="card-title">Rando Roller</h5>
    </div>
    <div class="card-liquid-body">
        <p class="card-text">Randonnée roller dans Grenoble</p>
        <button class="btn btn-liquid btn-liquid-accent">Participer</button>
    </div>
</div>
```

## 🔧 Personnalisation

### **Variables CSS personnalisables**
```css
:root {
    /* Couleurs Grenoble Roller */
    --gr-primary: #007AFF;
    --gr-secondary: #8E8E93;
    --gr-accent: #FF3B30;
    
    /* Espacements */
    --space-md: 1rem;
    --space-lg: 1.5rem;
    
    /* Bordures */
    --border-radius-md: 0.5rem;
    --border-radius-lg: 0.75rem;
}
```

### **Thème enfant**
```css
/* Votre thème enfant */
:root {
    --gr-primary: #FF6B35;  /* Orange Grenoble */
    --gr-secondary: #2C3E50; /* Bleu foncé */
}
```

## 📊 Métriques de performance

### **Objectifs de performance**
- **LCP** (Largest Contentful Paint) : < 2.5s
- **FID** (First Input Delay) : < 100ms
- **CLS** (Cumulative Layout Shift) : < 0.1
- **TTI** (Time to Interactive) : < 3.5s

### **Optimisations recommandées**
1. **Images** : Format WebP, lazy loading
2. **CSS** : Minification, critical CSS
3. **JavaScript** : Code splitting, tree shaking
4. **Fonts** : Preload, font-display: swap

## 🎨 Exemples d'utilisation

### **Navigation**
```html
<nav class="navbar navbar-expand-lg navbar-liquid">
    <div class="container">
        <a class="navbar-brand" href="#">Grenoble Roller</a>
        <ul class="navbar-nav">
            <li class="nav-item">
                <a class="nav-link active" href="#">Accueil</a>
            </li>
        </ul>
    </div>
</nav>
```

### **Tableau de données**
```html
<div class="table-liquid">
    <table class="table">
        <thead>
            <tr>
                <th>Événement</th>
                <th>Date</th>
                <th>Statut</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>Rando Roller</td>
                <td>15/01/2025</td>
                <td><span class="badge-liquid badge-liquid-success">Actif</span></td>
            </tr>
        </tbody>
    </table>
</div>
```

## 🚀 Prochaines étapes

1. **Intégration Rails** : Adapter le thème pour Rails 8
2. **Composants Stimulus** : Créer des contrôleurs Stimulus
3. **Tests** : Tests d'accessibilité et de performance
4. **Documentation** : Guide de développement complet

## 📞 Support

Pour toute question ou suggestion concernant le thème Liquid Apple 2025 :

- **Documentation** : Consultez ce README
- **Exemples** : Voir `liquid-apple-2025.html`
- **Issues** : Créer une issue sur le repository

---

**Grenoble Roller - Liquid Apple 2025 Theme**  
*Design premium inspiré d'Apple avec identité Grenoble Roller*
