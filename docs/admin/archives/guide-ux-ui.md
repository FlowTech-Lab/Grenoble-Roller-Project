# Guide UX/UI - Panel Admin

**Objectif** : Recommandations complètes pour l'interface du panel admin  
**Approche** : Best practices 2025 avec focus utilisabilité

---

## 🎯 Architecture Recommandée

### Layout Global : Sidebar Collapsible ✅ RECOMMANDÉE

```
┌─────────────────────────────────────────────────────────┐
│  Logo  |  Titre Page  │  Recherche  │  User  │  Settings│
├────────┼──────────────────────────────────────────────────┤
│        │                                                  │
│  MENU  │                 CONTENU PRINCIPAL               │
│  ████  │  ┌──────────────────────────────────────────┐  │
│  ████  │  │  Index / Show / Form / Custom Page        │  │
│  ████  │  │                                          │  │
│        │  └──────────────────────────────────────────┘  │
└────────┴──────────────────────────────────────────────────┘
```

### Dimensions
- **Sidebar collapsed** : 64px (icons seulement + tooltips)
- **Sidebar expanded** : 280px (labels + icons)
- **Breakpoints** :
  - Desktop (1200px+) : expandable sidebar
  - Tablet (768px-1200px) : collapsed par défaut
  - Mobile (<768px) : drawer avec hamburger

---

## 🗂️ Structure Menu Hiérarchique

### Catégories Principales

```
📊 TABLEAU DE BORD
├─ Dashboard
└─ Maintenance Mode

👥 UTILISATEURS  ▼
├─ Utilisateurs
├─ Rôles
├─ Adhésions
└─ Candidatures Organisateurs

🛒 BOUTIQUE  ▼
├─ Produits
├─ Catégories
├─ Variantes
├─ Types d'Options
├─ Valeurs d'Options
└─ Associations

📦 COMMANDES  ▼
├─ Commandes
├─ Articles
└─ Paiements

📅 ÉVÉNEMENTS  ▼
├─ Randos (Events)
├─ Initiations
├─ Participations
└─ Parcours

💬 COMMUNICATION  ▼
├─ Messages de Contact
└─ Partenaires

🔧 MATÉRIEL  ▼
└─ Stock Rollers

🔍 SYSTÈME  ▼
└─ Audit Logs
```

### Règles
- ✅ Max 3 niveaux de profondeur
- ✅ Grouper par domaine métier
- ✅ Accès fréquent vers le haut (Dashboard premier)
- ✅ Actions critiques en évidence

---

## 🔍 Recherche Globale (Cmd+K)

### Implémentation
```
┌─────────────────────────────┐
│  🔍  Rechercher...  Cmd+K   │
└─────────────────────────────┘
      ↓ (après 2 caractères)
┌──────────────────────────────────┐
│ 📋 Ressources                    │
│  • Produits (3 matches)          │
│  • Product Categories (1)        │
├──────────────────────────────────┤
│ 📖 Pages                         │
│  • Dashboard                     │
├──────────────────────────────────┤
│ 👤 Utilisateurs (recent)         │
│  • Marc Dupont                   │
└──────────────────────────────────┘
```

### Features
- ✅ Commande globale (Cmd+K / Ctrl+K)
- ✅ Recherche ressources + pages + utilisateurs
- ✅ Max 8-10 résultats
- ✅ Navigation clavier (Arrow + Enter)
- ✅ Accessibilité (ARIA live regions)

---

## 📋 Layout Index (Tables)

### Structure Standard
```
[Filtres]  [Recherche]  [Actions]  [Affichage options]
┌─────┬────────────┬─────────┬────────┐
│ ☐   │ Nom        │ Email   │ Actions│
├─────┼────────────┼─────────┼────────┤
│ ☑   │ Marc D.    │ m@e.fr  │ ⋮      │
│ ☐   │ Sarah J.   │ s@e.fr  │ ⋮      │
└─────┴────────────┴─────────┴────────┘
3 sélectionnées → [Supprimer] [Exporter] [Assigner]
```

### Features Drag-Drop Colonnes
- ✅ Réordonnage : Drag header → repositionner
- ✅ Masquage : Menu colonne → toggle visibility
- ✅ Largeur : Resize handles entre headers
- ✅ Persistence : Sauvegarder préférences utilisateur

### Toolbar Actions Dynamiques
- Actions batch visibles seulement si sélection
- Filtres combinables
- Tri par colonne (asc/desc)

---

## 📝 Layout Formulaires

### Structure avec Tabs
```
┌─ Tabs: Infos | Adresse | Commentaires
│
├─ Section 1
│  └─ [Champ] [Champ]
│  └─ [Champ long]
│
├─ Divider
│
├─ Section 2
│  └─ [Champ] [Champ]
│
├─ Panels associés
│  └─ [Tableau avec données liées]
│
└─ Actions
   └─ [← Retour] [Annuler] [Sauvegarder]
```

### Panels Associés (Inline)
```
Utilisateur: Marc Dupont (ID: 42)

─── Inscriptions aux Événements ───────────────────
┌─────┬────────────────┬────────┬─────────┬──────┐
│ ID  │ Événement      │ Statut │ Paiement│ Date │
├─────┼────────────────┼────────┼─────────┼──────┤
│ 101 │ Rando Charteux │ Active │ Payé    │ 1/12 │
└─────┴────────────────┴────────┴─────────┴──────┘
```

---

## 🚀 Cas d'Usage Critiques

### A) Gestion Événements

**UX Optimisée** :
1. Index avec scopes rapides : [À venir] [Publiés] [À valider]
2. Page Show avec tabs :
   - **Détails** : Infos + édition rapide
   - **Inscriptions** : Tableau avec filtres + actions batch
   - **Liste d'attente** : Position | Personne | Statut | Actions
   - **Documents** : Upload GPX, certificat
3. Actions inline : Toast success après validation

### B) Gestion Initiations (Présences)

**Dashboard Présences** :
```
Initiation: Samedi 10h15 - Gymnase Ampère

Bénévoles (8 total)
┌────────────────┬──────────┬──────────────────┐
│ Personne       │ Statut   │ Actions          │
├────────────────┼──────────┼──────────────────┤
│ Marc D.        │ ✓ Présent│ ☐ À pointer      │
│ Sarah J.       │ ? Non pt │ ○ Absent  ✓ Prés│
└────────────────┴──────────┴──────────────────┘

Participants (25/30)
┌────────────────┬──────────┬──────────────────┐
│ Personne       │ Statut   │ Matériel         │
├────────────────┼──────────┼──────────────────┤
│ Alice (enfant) │ ✓ Présent│ Rollers 38EU     │
└────────────────┴──────────┴──────────────────┘

[Sauvegarder présences]  [Exporter liste]
```

**Interaction** : Radio buttons par ligne (À pointer / Présent / Absent)

### C) Gestion Adhésions (Multi-panels)

**Adhésion Personnelle** :
- Panel "Infos Adhésion" : Type, Catégorie, Statut, Dates, Montant
- Panel "Questionnaire de Santé" : Statut, Certificat (téléchargement)
- Panel "Consentements" : RGPD, Mentions légales, Partage FFRS

**Adhésion Enfant** (sections supplémentaires) :
- Panel "Informations Enfant" : Prénom, Nom, Date naissance, Âge
- Panel "Parent/Tuteur" : Nom, Email, Téléphone, Autorisation

---

## 🎨 Design Tokens

### Palette Couleurs
```css
Primary:   #0066cc (bleu)
Success:   #10b981 (vert)
Warning:   #f59e0b (orange)
Error:     #ef4444 (rouge)
Info:      #3b82f6 (bleu clair)

BG Primary:   #ffffff (light) / #111827 (dark)
BG Secondary: #f9fafb (light) / #1f2937 (dark)
Text Primary: #1f2937 (light) / #f9fafb (dark)
Border:       #e5e7eb (light) / #4b5563 (dark)
```

### Spacing
```css
xs:  4px    md:  16px
sm:  8px    lg:  24px
     12px   xl:  32px
```

### Typography
```css
Body:     14px / 1.5
Headings: 16px, 18px, 20px, 24px
Mono:     12px (logs, codes)
```

---

## 📱 Responsive Design

### Desktop (1200px+)
- Sidebar expandable
- Tous filtres en ligne
- Grille complète

### Tablet (768px-1200px)
- Sidebar collapsed par défaut
- Filtres en drawer
- Grille 3-4 colonnes

### Mobile (<768px)
- Sidebar hidden (hamburger)
- Grille 1-2 colonnes
- Fullwidth forms
- Bottom action buttons

---

## 🎯 Interactions Clés

### États Chargement
- Skeleton loaders pour tables
- Spinner pour formulaires
- Toast notifications pour actions

### Confirmations
- **Destructive** : Modal avec double confirmation
- **Reversible** : Toast simple suffisant
- **Batch action** : Confirmation avec nombre items

### Validations
- Inline errors : messages visibles immédiatement
- Submit disabled : jusqu'à correction
- Server errors : toast rouge + highlight champ

---

## 🎯 Top 5 Priorités

### 1️⃣ Sidebar Collapsible (Fondamental)
- État expanded (280px) : Labels + icons
- État collapsed (64px) : Icons seulement + tooltips
- Smooth animation : 300ms transition
- Responsive toggle : Hamburger sur mobile
- Persist préférence : localStorage ou DB

### 2️⃣ Menu Hiérarchique
- Expand/collapse par section
- Max 3 niveaux de nesting
- Icons + Labels pour lisibilité
- Chevron (▼) indique expansion

### 3️⃣ Recherche Globale (Cmd+K)
- Déclenché après 2 caractères
- Max 8-10 résultats
- Navigation clavier (↓↑ + Enter)
- Searchable : ressources + pages + users récents

### 4️⃣ Drag-Drop Colonnes
- Réordonnage colonnes par drag
- Masquage colonnes via menu
- Largeur colonnes resizable
- Ordre + visibility sauvegardé par utilisateur

### 5️⃣ Boutons Dynamiques
- Affichés selon statut ressource
- Configuration en base de données
- Permissions Pundit respectées
- Exemples :
  - Events "pending" → [Valider] [Refuser] [Modifier]
  - Memberships "pending" → [Activer] [Rejeter] [Contacter]

---

## ✅ Checklist Implémentation

### Week 1-2: Infrastructure
- [ ] Sidebar component (expanded/collapsed)
- [ ] Menu structure (hierarchical, collapsible)
- [ ] Dark mode toggle
- [ ] Responsive layout

### Week 3-4: Navigation
- [ ] Breadcrumb
- [ ] Search global (Cmd+K)
- [ ] Keyboard shortcuts
- [ ] Active state styling

### Week 5-6: Data Display
- [ ] Table component base
- [ ] Sorting + filtering UI
- [ ] Column reordering (drag-drop)
- [ ] Row selection + batch actions

### Week 7-8: Forms
- [ ] Tab system
- [ ] Form sections + dividers
- [ ] Inline validation
- [ ] Panel system (associated data)

### Week 9-10: Advanced
- [ ] Dynamic buttons (DB-driven)
- [ ] Dashboard widgets drag-drop
- [ ] Presence management (Initiations)
- [ ] Polish + accessibility

---

## 🚀 Wins à Attendre

### Performance
- ✅ Moins de scrolling (sidebar collapsed)
- ✅ Chargement plus rapide (virtualisation tables)
- ✅ Moins de clics (recherche globale)

### Usability
- ✅ Découverte facile (menu hiérarchique)
- ✅ Personnalisation (colonnes, sidebar)
- ✅ Actions claires (boutons contextuels)

### Mobile
- ✅ Responsive complète
- ✅ Touch-friendly interactions
- ✅ Optimized formulaires

---

## 🔗 Références Croisées

- **[START_HERE.md](START_HERE.md)** - Guide de démarrage complet
- **[plan-implementation.md](plan-implementation.md)** - Plan d'implémentation avec user stories
- **[reference-css-classes.md](reference-css-classes.md)** - Classes CSS pour implémenter ce guide
- **[descisions/](descisions/)** - Guides techniques détaillés pour chaque fonctionnalité

---

**Ce guide sert de référence pour l'implémentation. Consulter `plan-implementation.md` pour le planning détaillé.**
