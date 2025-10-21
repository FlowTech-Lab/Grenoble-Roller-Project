# 🎯 PLAN D'ACTION - MOLÉCULES ET ORGANISMES UI KIT

**Projet** : Grenoble Roller UI Kit - Eventbrite Components  
**Date** : 2025-10-21  
**Durée estimée** : 7h45  
**Approche** : Hybride (Showcase complet + Code source séparé)

---

## 📋 TABLE DES MATIÈRES

- [Objectif Final](#objectif-final)
- [Structure Finale](#structure-finale)
- [Concepts Clés](#concepts-clés)
- [Plan d'Action (15 Étapes)](#plan-daction-15-étapes)
- [Timeline & Organisation](#timeline--organisation)
- [Ressources](#ressources)

---

## 🎯 OBJECTIF FINAL

Créer un **UI Kit complet** pour une application type Eventbrite avec :

✅ **1 page principale** (`index.html`)
- Showcase de TOUT (Atoms + Molecules + Organisms)
- Navigation fluide avec ancres
- Previews de tous les composants

✅ **1 page backup** (`atoms.html`)
- Référence des atomes seuls
- Documentation du kit UI de base

✅ **Dossier `/components/`**
- Code source de chaque molécule/organisme
- Fichiers isolés faciles à copier/coller
- Documentation individuelle

---

## 📂 STRUCTURE FINALE

```
UI-Kit/
├── index.html              ← Showcase complet (navigation fluide)
├── atoms.html              ← Backup du kit UI actuel
├── style.css               ← CSS global (existant + nouveau CSS)
├── PLAN_MOLECULES_ORGANISMS.md  ← Ce fichier
└── components/
    ├── navbar.html         ← Code source Navbar
    ├── footer.html         ← Code source Footer
    ├── auth-forms.html     ← Code source 4 formulaires
    ├── banners.html        ← Code source 2 bannières
    ├── cards.html          ← Code source 3 cartes
    ├── card-lists.html     ← Code source listes
    ├── comment.html        ← Code source commentaire
    ├── comment-section.html← Code source section commentaires
    ├── resource.html       ← Code source présentation ressource
    ├── element.html        ← Code source présentation élément
    └── calendar.html       ← Code source calendrier custom
```

---

## 💡 CONCEPTS CLÉS

### Atomic Design

**🔬 Atoms (Atomes)**
- Éléments de base non divisibles
- Exemples : buttons, inputs, labels, icons
- Déjà créés dans ton kit UI actuel

**🧬 Molecules (Molécules)**
- Combinaison de plusieurs atomes
- Composant fonctionnel simple
- Exemples : search bar (input + button), card, banner

**🦠 Organisms (Organismes)**
- Combinaison de molécules et/ou atomes
- Section complexe et complète
- Exemples : navbar, footer, comment section

### Approche Hybride

**Index.html** = Showcase complet
- Présente TOUT sur une seule page
- Navigation avec ancres (#atoms, #molecules, #organisms)
- Preview de chaque composant
- Lien "View source" vers le code

**Components/*.html** = Code source
- Fichier isolé par composant
- Facile à copier/coller
- Documentation + code
- Réutilisable dans n'importe quel projet

---

## 🚀 PLAN D'ACTION (15 ÉTAPES)

---

### ✅ ÉTAPE 1 : BACKUP

**⏱️ Durée** : 2 min  
**📁 Fichiers** : `index.html` → `atoms.html`

**Objectif** : Sauvegarder ton index.html actuel avant modifications

**Actions** :
1. Copier `index.html` → `atoms.html`
2. Vérifier que la copie fonctionne (ouvrir dans navigateur)

**Commande** :
```bash
cd UI-Kit
cp index.html atoms.html
```

**Ce que tu apprends** :
- ✅ Importance de la sauvegarde avant refactoring
- ✅ Versionning manuel simple

**Validation** :
- [ ] `atoms.html` existe
- [ ] `atoms.html` s'affiche correctement dans le navigateur
- [ ] Contenu identique à `index.html`

---

### ✅ ÉTAPE 2 : CREATE STRUCTURE

**⏱️ Durée** : 3 min  
**📁 Fichiers** : Créer dossier et 11 fichiers HTML

**Objectif** : Créer la structure de dossiers pour les composants

**Actions** :
1. Créer dossier `UI-Kit/components/`
2. Créer 11 fichiers HTML vides

**Commandes** :
```bash
cd UI-Kit
mkdir components
cd components
touch navbar.html footer.html auth-forms.html banners.html cards.html card-lists.html comment.html comment-section.html resource.html element.html calendar.html
```

**Ce que tu apprends** :
- ✅ Organisation d'un design system
- ✅ Séparation code source vs showcase
- ✅ Structure de fichiers professionnelle

**Validation** :
- [ ] Dossier `/components/` existe
- [ ] 11 fichiers HTML créés

---

### ✅ ÉTAPE 3 : REORGANIZE INDEX

**⏱️ Durée** : 20 min  
**📁 Fichiers** : `index.html`

**Objectif** : Transformer index.html en showcase organisé en 3 sections

**Actions** :
1. Ajouter une **Table of Contents** sticky en haut
2. Ajouter un **Hero** de présentation
3. Réorganiser en **3 sections** :
   - Section 1 : **Atoms** (tout ton contenu actuel)
   - Section 2 : **Molecules** (vide pour l'instant)
   - Section 3 : **Organisms** (vide pour l'instant)

**Structure HTML** :
```html
<!DOCTYPE html>
<html lang="en" data-bs-theme="light">
<head>
    <meta charset="UTF-8">
    <title>Grenoble Roller - UI Kit & Components</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <!-- Showcase Navigation -->
    <nav class="navbar navbar-liquid sticky-top" id="showcase-nav">
        <div class="container">
            <a class="navbar-brand" href="#hero">
                <i class="bi bi-palette"></i> UI Kit
            </a>
            <ul class="nav">
                <li class="nav-item">
                    <a class="nav-link" href="#atoms">Atoms</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="#molecules">Molecules</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="#organisms">Organisms</a>
                </li>
            </ul>
        </div>
    </nav>

    <!-- Hero Section -->
    <section id="hero" class="py-5 text-center">
        <div class="container">
            <h1 class="display-3 text-liquid-primary">
                Grenoble Roller UI Kit
            </h1>
            <p class="lead">
                Complete design system for Eventbrite-like applications
            </p>
            <p class="text-muted">
                Bootstrap 5.3.2 + Liquid Design 2025 Layer + Custom Components
            </p>
        </div>
    </section>

    <!-- ========================================
         SECTION 1 : ATOMS
         ======================================== -->
    <section id="atoms" class="py-5">
        <div class="container">
            <div class="row mb-4">
                <div class="col-12">
                    <h2 class="display-4 mb-3">🔬 Atoms</h2>
                    <p class="lead">Basic building blocks of the design system</p>
                    <hr>
                </div>
            </div>
            
            <!-- TOUT TON CONTENU ACTUEL ICI -->
            <!-- (Buttons, Typography, Forms, etc.) -->
            
        </div>
    </section>

    <!-- ========================================
         SECTION 2 : MOLECULES
         ======================================== -->
    <section id="molecules" class="py-5 bg-light">
        <div class="container">
            <div class="row mb-4">
                <div class="col-12">
                    <h2 class="display-4 mb-3">🧬 Molecules</h2>
                    <p class="lead">Functional components combining atoms</p>
                    <hr>
                </div>
            </div>
            
            <!-- On va remplir au fur et à mesure -->
            
        </div>
    </section>

    <!-- ========================================
         SECTION 3 : ORGANISMS
         ======================================== -->
    <section id="organisms" class="py-5">
        <div class="container">
            <div class="row mb-4">
                <div class="col-12">
                    <h2 class="display-4 mb-3">🦠 Organisms</h2>
                    <p class="lead">Complex sections combining molecules and atoms</p>
                    <hr>
                </div>
            </div>
            
            <!-- On va remplir au fur et à mesure -->
            
        </div>
    </section>

    <!-- Footer -->
    <footer class="py-4 text-center text-muted">
        <p>Grenoble Roller UI Kit - 2025</p>
    </footer>

    <!-- Scripts -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
```

**Ce que tu apprends** :
- ✅ Structure d'une page de documentation
- ✅ Navigation avec ancres (#atoms, #molecules)
- ✅ Organisation hiérarchique (Atomic Design)
- ✅ Sections alternées (bg-light pour contraste)

**Validation** :
- [ ] Navigation fonctionne (clics sur liens scrollent vers sections)
- [ ] 3 sections visibles : Atoms, Molecules, Organisms
- [ ] Hero présente le projet
- [ ] Design cohérent avec le kit Liquid

---

### ✅ ÉTAPE 4 : NAVBAR ORGANISM

**⏱️ Durée** : 45 min  
**📁 Fichiers** : `components/navbar.html`, `style.css`, `index.html`

**Objectif** : Créer une navbar complète pour Eventbrite

#### Phase 1 : Design (10 min)

**Dessine sur papier** :
```
┌─────────────────────────────────────────────────────────┐
│ 🎫 Eventbrite  |  Accueil  Événements  Créer            │
│                                                          │
│        [🔍 Rechercher un événement...]                  │
│                                                          │
│                        [Connexion] [Inscription]        │
└─────────────────────────────────────────────────────────┘
```

**Éléments** :
- Logo + Texte "Eventbrite"
- Menu navigation : Accueil, Événements, Créer un événement
- Search bar centrée
- Boutons auth : Connexion (outline), Inscription (primary)
- Responsive : burger menu sur mobile

#### Phase 2 : Code (`components/navbar.html`) (25 min)

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Navbar - Grenoble Roller UI Kit</title>
    <link rel="stylesheet" href="../style.css">
</head>
<body class="bg-light">
    <div class="container py-5">
        <!-- Documentation -->
        <h1 class="mb-4">Navbar Organism</h1>
        <p class="lead">Complete navigation bar for Eventbrite application</p>
        
        <div class="alert alert-info mb-4">
            <strong>Components:</strong> Logo + Menu + Search + Auth buttons
        </div>

        <!-- Preview -->
        <h2 class="h4 mb-3">Preview</h2>
        
        <!-- NAVBAR CODE START -->
        <nav class="navbar navbar-eventbrite navbar-expand-lg navbar-liquid mb-4">
            <div class="container-fluid">
                <!-- Logo -->
                <a class="navbar-brand fw-bold" href="#">
                    <i class="bi bi-ticket-perforated me-2"></i>
                    Eventbrite
                </a>
                
                <!-- Toggle button for mobile -->
                <button class="navbar-toggler" type="button" 
                        data-bs-toggle="collapse" data-bs-target="#navbarEventbrite" 
                        aria-controls="navbarEventbrite" aria-expanded="false" 
                        aria-label="Toggle navigation">
                    <span class="navbar-toggler-icon"></span>
                </button>
                
                <!-- Navbar content -->
                <div class="collapse navbar-collapse" id="navbarEventbrite">
                    <!-- Menu -->
                    <ul class="navbar-nav me-auto mb-2 mb-lg-0">
                        <li class="nav-item">
                            <a class="nav-link active" aria-current="page" href="#">
                                <i class="bi bi-house me-1"></i> Accueil
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="#">
                                <i class="bi bi-calendar-event me-1"></i> Événements
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="#">
                                <i class="bi bi-plus-circle me-1"></i> Créer un événement
                            </a>
                        </li>
                    </ul>
                    
                    <!-- Search -->
                    <form class="d-flex me-3" role="search">
                        <div class="input-group">
                            <input class="form-control form-control-liquid" 
                                   type="search" 
                                   placeholder="Rechercher un événement..." 
                                   aria-label="Search">
                            <button class="btn btn-outline-primary" type="submit">
                                <i class="bi bi-search"></i>
                            </button>
                        </div>
                    </form>
                    
                    <!-- Auth buttons -->
                    <div class="d-flex">
                        <a href="#" class="btn btn-outline-primary me-2">
                            Connexion
                        </a>
                        <a href="#" class="btn btn-liquid-primary">
                            Inscription
                        </a>
                    </div>
                </div>
            </div>
        </nav>
        <!-- NAVBAR CODE END -->

        <!-- Code snippet -->
        <h2 class="h4 mt-5 mb-3">HTML Code</h2>
        <pre class="bg-dark text-light p-3 rounded"><code>&lt;nav class="navbar navbar-eventbrite navbar-expand-lg navbar-liquid"&gt;
    &lt;div class="container-fluid"&gt;
        &lt;!-- Logo --&gt;
        &lt;a class="navbar-brand fw-bold" href="#"&gt;
            &lt;i class="bi bi-ticket-perforated me-2"&gt;&lt;/i&gt;
            Eventbrite
        &lt;/a&gt;
        
        &lt;!-- Toggle button --&gt;
        &lt;button class="navbar-toggler" data-bs-toggle="collapse" data-bs-target="#navbarEventbrite"&gt;
            &lt;span class="navbar-toggler-icon"&gt;&lt;/span&gt;
        &lt;/button&gt;
        
        &lt;!-- Content --&gt;
        &lt;div class="collapse navbar-collapse" id="navbarEventbrite"&gt;
            &lt;!-- Menu, Search, Auth... --&gt;
        &lt;/div&gt;
    &lt;/div&gt;
&lt;/nav&gt;</code></pre>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
```

#### Phase 3 : CSS Custom (`style.css`) (5 min)

Ajouter à la fin de `style.css` :

```css
/* === NAVBAR EVENTBRITE ORGANISM === */
.navbar-eventbrite {
    box-shadow: var(--bs-box-shadow);
}

.navbar-eventbrite .navbar-brand {
    font-size: 1.5rem;
    color: var(--gr-primary);
}

.navbar-eventbrite .navbar-brand:hover {
    color: var(--gr-primary-dark);
}

.navbar-eventbrite .nav-link {
    font-weight: 500;
    transition: var(--transition-liquid);
}

.navbar-eventbrite .nav-link:hover {
    color: var(--gr-primary);
    transform: translateY(-2px);
}

.navbar-eventbrite .nav-link.active {
    color: var(--gr-primary);
    font-weight: 600;
}

/* Search bar in navbar */
.navbar-eventbrite .input-group {
    min-width: 300px;
}

@media (max-width: 991px) {
    .navbar-eventbrite .input-group {
        min-width: 100%;
        margin: 1rem 0;
    }
    
    .navbar-eventbrite .d-flex {
        width: 100%;
    }
    
    .navbar-eventbrite .btn {
        flex: 1;
    }
}
```

#### Phase 4 : Intégration dans `index.html` (5 min)

Dans la section `#organisms`, ajouter :

```html
<!-- Navbar Organism -->
<div id="navbar-organism" class="mb-5">
    <h3 class="h2 mb-3">Navbar</h3>
    <p class="text-muted mb-3">
        Complete navigation bar with logo, menu, search, and authentication
    </p>
    
    <!-- Preview -->
    <div class="card card-liquid mb-3">
        <div class="card-body p-0">
            <!-- Copier le code de la navbar ici -->
            <nav class="navbar navbar-eventbrite navbar-expand-lg navbar-liquid">
                <!-- ... -->
            </nav>
        </div>
    </div>
    
    <!-- Source link -->
    <a href="components/navbar.html" class="btn btn-outline-primary" target="_blank">
        <i class="bi bi-code-square me-2"></i> View Source Code
    </a>
</div>
```

**Ce que tu apprends** :
- ✅ Créer un organisme complexe
- ✅ Combiner logo + menu + search + buttons
- ✅ Responsive design (burger menu)
- ✅ Navigation Bootstrap (collapse)
- ✅ Réutilisabilité du code
- ✅ Documentation d'un composant

**Validation** :
- [ ] Navbar s'affiche correctement
- [ ] Burger menu fonctionne sur mobile
- [ ] Search bar responsive
- [ ] Hover effects fonctionnent
- [ ] Code source disponible dans `/components/navbar.html`
- [ ] Preview dans `index.html`

---

### ✅ ÉTAPE 5 : FOOTER ORGANISM

**⏱️ Durée** : 30 min  
**📁 Fichiers** : `components/footer.html`, `style.css`, `index.html`

**Objectif** : Footer professionnel 4 colonnes

#### Design

```
┌─────────────────────────────────────────────────────────┐
│  À PROPOS      ÉVÉNEMENTS      SUPPORT       SUIVEZ-NOUS│
│  - Qui sommes  - Parcourir    - FAQ         - Facebook  │
│  - Équipe      - Catégories   - Contact     - Twitter   │
│  - Carrières   - Villes       - CGU         - Instagram │
│  - Blog        - Créer        - Confidentialité - LinkedIn│
│                                                          │
│  © 2025 Grenoble Roller - Tous droits réservés          │
└─────────────────────────────────────────────────────────┘
```

**Ce que tu apprends** :
- ✅ Layout multi-colonnes (Bootstrap grid)
- ✅ Listes de navigation
- ✅ Icônes sociales
- ✅ Footer responsive
- ✅ Espacement et alignement

---

### ✅ ÉTAPE 6 : AUTH FORMS ORGANISM

**⏱️ Durée** : 60 min  
**📁 Fichiers** : `components/auth-forms.html`, `style.css`, `index.html`

**Objectif** : Créer 4 formulaires d'authentification avec design générique

#### Les 4 formulaires

1. **Login** : Email + Password + Remember me + Forgot password
2. **Signup** : Name + Email + Password + Confirm + CGU checkbox
3. **Reset Password** : Email only
4. **Change Password** : Old password + New + Confirm

#### Template générique

Tous les formulaires partagent :
- Card centrée (max-width: 450px)
- Style Liquid glass morphism
- Bouton primary pleine largeur
- Liens secondaires en bas

**Ce que tu apprends** :
- ✅ Créer des formulaires avec validation
- ✅ Card centrée (authentification UX)
- ✅ Réutiliser les form-control-liquid
- ✅ Design générique adaptable
- ✅ UX des formulaires d'auth

---

### ✅ ÉTAPE 7 : BANNERS MOLECULES

**⏱️ Durée** : 30 min  
**📁 Fichiers** : `components/banners.html`, `style.css`, `index.html`

**Objectif** : 2 types de bannières

#### 1. Hero Banner (Homepage)
- Hauteur : 500px
- Image de fond avec overlay gradient
- Titre H1 énorme (3.5rem)
- Paragraphe accrocheur
- CTA button primary

#### 2. Page Banner (Small)
- Hauteur : 200px
- Image de fond
- Titre de page H2
- Breadcrumb (optionnel)

**Ce que tu apprends** :
- ✅ Background images avec overlay
- ✅ Positionnement texte sur image
- ✅ Call-to-action design
- ✅ Responsive banners
- ✅ Gradient overlays

---

### ✅ ÉTAPE 8 : CARDS MOLECULES

**⏱️ Durée** : 45 min  
**📁 Fichiers** : `components/cards.html`, `style.css`, `index.html`

**Objectif** : 3 types de cartes réutilisables

#### 1. Event Card (Verticale)
```
┌────────────────┐
│    [IMAGE]     │ ← Photo événement
│   [DATE BADGE] │ ← Badge date overlay
├────────────────┤
│ Titre événement│
│ 📍 Lieu        │
│ 💰 Prix        │
│   [Voir +]     │
└────────────────┘
```

#### 2. User Card (Horizontale)
```
┌──────────────────────────┐
│ [PHOTO] Nom Prénom       │
│         Bio courte...    │
│         [BADGE]  [Btn]   │
└──────────────────────────┘
```

#### 3. City Card
```
┌────────────────┐
│   [IMAGE]      │
│   PARIS        │
│   120 événements│
└────────────────┘
```

**Ce que tu apprends** :
- ✅ Card layouts différents (vertical, horizontal)
- ✅ Hover effects (translateY, scale)
- ✅ Badges overlay
- ✅ Optimisation images
- ✅ Responsive cards

---

### ✅ ÉTAPE 9 : CARD LISTS ORGANISMS

**⏱️ Durée** : 30 min  
**📁 Fichiers** : `components/card-lists.html`, `style.css`, `index.html`

**Objectif** : Listes pour afficher plusieurs cartes

#### 1. Event Grid
- 3 colonnes desktop (col-md-4)
- 2 colonnes tablet (col-sm-6)
- 1 colonne mobile
- Espacement uniforme (gap)

#### 2. User List
- Stack vertical
- Cartes horizontales
- Alternance de fond (optionnel)

**Ce que tu apprends** :
- ✅ Grid system Bootstrap
- ✅ Responsive columns
- ✅ Spacing entre cartes
- ✅ Layout de liste

---

### ✅ ÉTAPE 10 : COMMENT MOLECULE

**⏱️ Durée** : 20 min  
**📁 Fichiers** : `components/comment.html`, `style.css`, `index.html`

**Objectif** : Molécule commentaire individuel

#### Design
```
┌─────────────────────────────┐
│ [👤]  Jean Dupont            │
│       Il y a 2 heures        │
│                              │
│       Super événement ! ...  │
│                              │
│       [Répondre] [❤️ 12]     │
└─────────────────────────────┘
```

**Éléments** :
- Avatar left (50x50px, rond)
- Nom + date en haut
- Contenu commentaire
- Actions : Répondre, Like avec compteur

**Ce que tu apprends** :
- ✅ Avatar + texte layout (flexbox)
- ✅ Metadata display (date, auteur)
- ✅ Action buttons
- ✅ Compteurs sociaux

---

### ✅ ÉTAPE 11 : COMMENT SECTION ORGANISM

**⏱️ Durée** : 30 min  
**📁 Fichiers** : `components/comment-section.html`, `style.css`, `index.html`

**Objectif** : Section commentaires complète

#### Structure
```
┌─────────────────────────────────┐
│ Commentaires (12)               │
├─────────────────────────────────┤
│ [Textarea: Ajouter un commentaire]│
│ [Bouton Commenter]              │
├─────────────────────────────────┤
│ [Comment 1]                     │
│ [Comment 2]                     │
│ [Comment 3]                     │
│ ...                             │
│ [Voir plus]                     │
└─────────────────────────────────┘
```

**Ce que tu apprends** :
- ✅ Combiner form + liste
- ✅ Textarea styling
- ✅ Section complète réutilisable
- ✅ Load more pattern

---

### ✅ ÉTAPE 12 : RESOURCE PRESENTATION ORGANISM

**⏱️ Durée** : 45 min  
**📁 Fichiers** : `components/resource.html`, `style.css`, `index.html`

**Objectif** : Page show pour événement/utilisateur

#### Layout
```
┌─────────────────────────────────────┐
│ [IMAGE 8 col]    [CARD INFOS 4 col] │
├─────────────────────────────────────┤
│ [DESCRIPTION]    [SIDEBAR]          │
│ [8 col]          [4 col]            │
│                  - Organisateur     │
│                  - Date/Lieu        │
│                  - Prix             │
├─────────────────────────────────────┤
│ [PARTAGER] 📱 💬 📧                  │
└─────────────────────────────────────┘
```

**Ce que tu apprends** :
- ✅ Layout complexe (8/4 columns)
- ✅ Sidebar sticky (position: sticky)
- ✅ Page structure complète
- ✅ Social share buttons
- ✅ Responsive layout (stack sur mobile)

---

### ✅ ÉTAPE 13 : ELEMENT PRESENTATION MOLECULES

**⏱️ Durée** : 30 min  
**📁 Fichiers** : `components/element.html`, `style.css`, `index.html`

**Objectif** : Sections alternées image/texte pour landing pages

#### Variantes

**Version 1 : Image Left**
```
┌─────────────────────────────┐
│ [IMAGE]  │  Titre            │
│          │  Description...   │
│          │  [CTA Button]     │
└─────────────────────────────┘
```

**Version 2 : Image Right**
```
┌─────────────────────────────┐
│  Titre          │  [IMAGE]  │
│  Description... │           │
│  [CTA Button]   │           │
└─────────────────────────────┘
```

**Ce que tu apprends** :
- ✅ Layout flexbox
- ✅ Order responsive (flex-order)
- ✅ Landing page sections
- ✅ Image + text alignment

---

### ✅ ÉTAPE 14 : CUSTOM ORGANISM - EVENT CALENDAR

**⏱️ Durée** : 45 min  
**📁 Fichiers** : `components/calendar.html`, `style.css`, `index.html`

**Objectif** : Calendrier d'événements mensuel

#### Design
```
┌─────────────────────────────────────┐
│    ← Janvier 2025 →                 │
├─────────────────────────────────────┤
│ Lun  Mar  Mer  Jeu  Ven  Sam  Dim  │
├─────────────────────────────────────┤
│  1    2    3    4    5    6    7   │
│  8    9   [10]  11   12   13   14  │ ← [10] = événement
│  15   16   17   18   19   20   21  │
│  22   23   24   25   26   27   28  │
└─────────────────────────────────────┘
```

**Fonctionnalités** :
- Navigation mois (← →)
- Grid 7x5 (jours)
- Badges sur dates avec événements
- Hover : preview mini de l'événement
- Click : redirect vers événement

**Ce que tu apprends** :
- ✅ Grid calendrier (CSS Grid)
- ✅ JavaScript interactions basiques
- ✅ Organisme custom complexe
- ✅ Badge overlay sur dates
- ✅ Navigation temporelle

---

### ✅ ÉTAPE 15 : FINALIZE

**⏱️ Durée** : 30 min  
**📁 Fichiers** : `index.html`, tous les fichiers

**Objectif** : Finaliser et polir le showcase

#### Actions

1. **Vérifier toutes les previews** dans `index.html`
2. **Ajouter liens "View source"** pour chaque composant
3. **Polish design** : espacements, couleurs, cohérence
4. **Tester responsive** : mobile, tablet, desktop
5. **Valider navigation** : ancres, liens, smooth scroll
6. **Créer Table of Contents** complète
7. **Ajouter meta descriptions** SEO
8. **Screenshots** (optionnel) pour documentation

#### Checklist finale

- [ ] Tous les composants ont une preview dans `index.html`
- [ ] Tous les composants ont leur fichier source dans `/components/`
- [ ] Navigation fonctionne parfaitement
- [ ] Responsive sur tous les écrans
- [ ] Aucune erreur de linter
- [ ] Code propre et commenté
- [ ] Documentation complète

**Ce que tu apprends** :
- ✅ Finitions d'un projet
- ✅ Testing multi-devices
- ✅ Quality assurance
- ✅ Documentation complète

---

## 📊 TIMELINE & ORGANISATION

### Vue d'ensemble

| Étape | Composant | Type | Durée | Cumulé |
|-------|-----------|------|-------|--------|
| 1 | Backup | Setup | 2 min | 2 min |
| 2 | Structure | Setup | 3 min | 5 min |
| 3 | Reorganize Index | Setup | 20 min | 25 min |
| 4 | Navbar | Organism | 45 min | 1h10 |
| 5 | Footer | Organism | 30 min | 1h40 |
| 6 | Auth Forms | Organism | 60 min | 2h40 |
| 7 | Banners | Molecules | 30 min | 3h10 |
| 8 | Cards | Molecules | 45 min | 3h55 |
| 9 | Card Lists | Organisms | 30 min | 4h25 |
| 10 | Comment | Molecule | 20 min | 4h45 |
| 11 | Comment Section | Organism | 30 min | 5h15 |
| 12 | Resource Presentation | Organism | 45 min | 6h00 |
| 13 | Element Presentation | Molecules | 30 min | 6h30 |
| 14 | Calendar | Organism | 45 min | 7h15 |
| 15 | Finalize | Polish | 30 min | **7h45** |

### Organisation par jour

**Option 1 : 1 journée intensive**
- Matin (4h) : Étapes 1-9
- Après-midi (4h) : Étapes 10-15

**Option 2 : 2 demi-journées**
- Jour 1 (4h) : Étapes 1-8 (Setup + Organisms)
- Jour 2 (4h) : Étapes 9-15 (Molecules + Polish)

**Option 3 : 3 sessions**
- Session 1 (2h30) : Étapes 1-5 (Setup + Navbar + Footer + Auth)
- Session 2 (2h30) : Étapes 6-10 (Banners + Cards + Comments)
- Session 3 (2h45) : Étapes 11-15 (Resource + Element + Calendar + Finalize)

---

## 📚 RESSOURCES

### Documentation Bootstrap

- [Bootstrap 5.3 Docs](https://getbootstrap.com/docs/5.3/getting-started/introduction/)
- [Bootstrap Examples](https://getbootstrap.com/docs/5.3/examples/)
- [Bootstrap Icons](https://icons.getbootstrap.com/)

### Inspiration Design

- [Eventbrite](https://www.eventbrite.fr/)
- [Bootswatch Themes](https://bootswatch.com/)
- [Material Design](https://material.io/)

### Atomic Design

- [Atomic Design Methodology](https://atomicdesign.bradfrost.com/)
- [Pattern Lab](https://patternlab.io/)

### Outils

- [CSS Grid Generator](https://cssgrid-generator.netlify.app/)
- [Gradient Generator](https://cssgradient.io/)
- [Color Palette](https://coolors.co/)

---

## ✅ CHECKLIST COMPLÈTE

### Setup
- [ ] Backup créé (`atoms.html`)
- [ ] Dossier `/components/` créé
- [ ] 11 fichiers HTML créés
- [ ] `index.html` réorganisé en 3 sections

### Organisms
- [ ] Navbar complète et responsive
- [ ] Footer 4 colonnes
- [ ] 4 formulaires d'authentification
- [ ] Section commentaires complète
- [ ] Présentation ressource (show page)
- [ ] Listes de cartes (grid + stack)
- [ ] Calendrier événements custom

### Molecules
- [ ] Hero banner
- [ ] Page banner
- [ ] Event card verticale
- [ ] User card horizontale
- [ ] City card
- [ ] Commentaire individuel
- [ ] Présentation élément (image + texte)

### Documentation
- [ ] Previews dans `index.html`
- [ ] Code source dans `/components/`
- [ ] Liens "View source"
- [ ] Table of contents
- [ ] README (optionnel)

### Quality
- [ ] Responsive testé
- [ ] Navigation fonctionne
- [ ] Aucune erreur linter
- [ ] Code commenté
- [ ] Design cohérent

---

## 🎯 PROCHAINES ÉTAPES

Une fois ce projet terminé, tu pourras :

1. **Intégrer dans Rails** (demain)
   - Transformer les composants en partials
   - Utiliser les helpers Rails
   - Dynamic content

2. **Créer d'autres variantes**
   - Dark mode versions
   - Différentes tailles
   - Animations avancées

3. **Étendre le système**
   - Plus de molécules
   - Templates de pages complètes
   - Design tokens

4. **Publier le kit**
   - GitHub Pages
   - NPM package
   - Documentation Storybook

---

## 📝 NOTES

### Best Practices

- ✅ **DRY** : Don't Repeat Yourself (réutilise les classes)
- ✅ **Mobile First** : Design d'abord pour mobile
- ✅ **Accessibility** : ARIA labels, semantic HTML
- ✅ **Performance** : Optimize images, lazy load
- ✅ **Consistency** : Utilise le design system

### Erreurs à éviter

- ❌ Ne pas tester responsive
- ❌ Oublier les ARIA labels
- ❌ Dupliquer du code au lieu de réutiliser
- ❌ Négliger la documentation
- ❌ Sauter les étapes de design (papier)

---

**Créé le** : 2025-10-21  
**Auteur** : Grenoble Roller Team  
**Version** : 1.0  
**Licence** : MIT

---

🚀 **Prêt à commencer ? Let's build something amazing!**

