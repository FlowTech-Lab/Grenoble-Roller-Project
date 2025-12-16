# Plan Agile - Migration Panel Admin

**Objectif** : Remplacer Active Admin par un panel moderne et maintenable  
**Durée** : 6 sprints (12 semaines)  
**Approche** : MVP progressif avec feedback utilisateur

---

## 🎯 Vision & Principes

### Objectifs
- ✅ Panel moderne avec UX 2025
- ✅ Navigation intuitive (sidebar + recherche)
- ✅ Personnalisation (colonnes, dashboard)
- ✅ Responsive complet
- ✅ Performance optimale

### Principes Agile
- **MVP d'abord** : Fonctionnalités essentielles en premier
- **Feedback continu** : Tests utilisateurs à chaque sprint
- **Itération** : Amélioration progressive
- **Simplicité** : Pas de sur-ingénierie

---

## 📊 Vue d'ensemble des sprints

```
Sprint 1-2: Infrastructure & Navigation (4 semaines)
Sprint 3-4: Affichage données & Actions (4 semaines)
Sprint 5-6: Formulaires & Features avancées (4 semaines)
```

**Total** : 12 semaines (6 sprints de 2 semaines)

---

## 🚀 SPRINT 1-2 : Infrastructure & Navigation

**Durée** : 4 semaines  
**Objectif** : Sidebar + Menu + Recherche fonctionnels

### Sprint 1 (Semaines 1-2)

#### User Stories
1. **US-001** : En tant qu'admin, je veux une sidebar collapsible pour gagner de l'espace
   - Sidebar expanded (280px) / collapsed (64px)
   - Toggle avec animation 300ms
   - Persistence localStorage
   - **Critères** : Desktop fonctionnel, responsive tablet

2. **US-002** : En tant qu'admin, je veux un menu hiérarchique pour naviguer facilement
   - Menu par catégories (Utilisateurs, Boutique, Événements, etc.)
   - Expand/collapse par section
   - Icons + labels
   - **Critères** : Toutes les ressources accessibles, max 3 niveaux

3. **US-003** : En tant qu'admin, je veux que la sidebar soit responsive
   - Desktop : expandable
   - Tablet : collapsed par défaut
   - Mobile : drawer avec hamburger
   - **Critères** : Testé sur 3 breakpoints

#### Livrables
- Sidebar component fonctionnel
- Menu hiérarchique avec collapse
- Responsive sur desktop/tablet/mobile
- Tests unitaires sidebar

#### Estimation : 16 points (8j)

---

### Sprint 2 (Semaines 3-4)

#### User Stories
4. **US-004** : En tant qu'admin, je veux rechercher rapidement (Cmd+K)
   - Recherche globale déclenchée par Cmd+K
   - Recherche ressources + pages + utilisateurs
   - Navigation clavier (flèches + Enter)
   - **Critères** : Résultats en <200ms, max 10 résultats

5. **US-005** : En tant qu'admin, je veux un breadcrumb pour savoir où je suis
   - Breadcrumb dynamique selon la page
   - Liens cliquables
   - **Critères** : Visible sur toutes les pages

6. **US-006** : En tant qu'admin, je veux des raccourcis clavier
   - Cmd+K → Recherche
   - Escape → Fermer modals
   - Cmd+S → Sauvegarder formulaire
   - Cmd+? → Aide
   - **Critères** : 5+ raccourcis fonctionnels

#### Livrables
- Recherche globale opérationnelle
- Breadcrumb system
- Raccourcis clavier
- Help modal

#### Estimation : 16 points (8j)

---

## 📋 SPRINT 3-4 : Affichage Données & Actions

**Durée** : 4 semaines  
**Objectif** : Tables + Drag-drop + Batch actions

### Sprint 3 (Semaines 5-6)

#### User Stories
7. **US-007** : En tant qu'admin, je veux réordonner les colonnes des tableaux
   - Drag-drop des colonnes
   - Sauvegarde préférences utilisateur
   - **Critères** : Ordre persisté, visuel drag handle

8. **US-008** : En tant qu'admin, je veux sélectionner plusieurs lignes pour actions batch
   - Checkboxes par ligne
   - Toolbar actions apparaît sur sélection
   - Actions : Supprimer, Exporter, Assigner
   - **Critères** : Sélection multiple, confirmation destructive

9. **US-009** : En tant qu'admin, je veux trier et filtrer les données
   - Tri par colonne (asc/desc)
   - Filtres en sidebar ou toolbar
   - **Critères** : Tri instantané, filtres combinables

#### Livrables
- Table component avec drag-drop colonnes
- Sélection multiple + batch actions
- Tri et filtres fonctionnels
- Tests E2E table

#### Estimation : 16 points (8j)

---

### Sprint 4 (Semaines 7-8)

#### User Stories
10. **US-010** : En tant qu'admin, je veux des boutons dynamiques selon le contexte
    - Boutons affichés selon statut ressource
    - Configuration en base de données
    - Permissions Pundit respectées
    - **Critères** : Boutons contextuels, permissions OK

11. **US-011** : En tant qu'admin, je veux personnaliser mon dashboard
    - Widgets réordonnables (drag-drop)
    - Sauvegarde positions
    - **Critères** : 8 widgets minimum, positions persistées

12. **US-012** : En tant qu'admin, je veux voir les statistiques importantes
    - Dashboard avec cartes statistiques
    - Liens vers ressources
    - **Critères** : 8 cartes minimum, données temps réel

#### Livrables
- Système boutons dynamiques (DB-driven)
- Dashboard personnalisable
- Widgets drag-drop
- Tests permissions

#### Estimation : 16 points (8j)

---

## 📝 SPRINT 5-6 : Formulaires & Features Avancées

**Durée** : 4 semaines  
**Objectif** : Forms optimisés + Features complexes

### Sprint 5 (Semaines 9-10)

#### User Stories
13. **US-013** : En tant qu'admin, je veux des formulaires organisés en tabs
    - Tabs : Infos | Adresse | Commentaires
    - Lazy loading contenu
    - **Critères** : 3+ ressources avec tabs, navigation fluide

14. **US-014** : En tant qu'admin, je veux voir les données associées dans des panels
    - Panels inline (ex: Inscriptions dans User)
    - Tables dans panels
    - **Critères** : Panels collapsibles, données à jour

15. **US-015** : En tant qu'admin, je veux valider les formulaires en temps réel
    - Validation inline
    - Messages d'erreur clairs
    - **Critères** : Validation avant submit, messages utiles

#### Livrables
- Tab system pour formulaires
- Panels associés fonctionnels
- Validation inline
- Refactoring 3+ ressources

#### Estimation : 16 points (8j)

---

### Sprint 6 (Semaines 11-12)

#### User Stories
16. **US-016** : En tant qu'admin, je veux gérer les présences d'initiations facilement
    - Dashboard présences avec pointage
    - Radio buttons : Présent / Absent / Non pointé
    - Sauvegarde batch
    - **Critères** : Pointage rapide, sauvegarde fiable

17. **US-017** : En tant qu'admin, je veux un dark mode
    - Toggle dark/light
    - Persistence préférence
    - **Critères** : Toutes les pages supportées, transition smooth

18. **US-018** : En tant qu'admin, je veux que le panel soit accessible
    - ARIA labels
    - Navigation clavier complète
    - Contraste couleurs
    - **Critères** : Score a11y ≥90, tests screen reader

#### Livrables
- Dashboard présences initiations
- Dark mode complet
- Accessibilité validée
- Tests E2E complets
- Documentation utilisateur

#### Estimation : 16 points (8j)

---

## ✅ Validation Faisabilité

### ✅ Faisable (Priorité 1)
- Sidebar collapsible : **Standard**, librairies disponibles
- Menu hiérarchique : **Simple**, structure claire
- Recherche globale : **Moyen**, nécessite endpoint backend
- Drag-drop colonnes : **Moyen**, @dnd-kit recommandé
- Batch actions : **Simple**, logique standard
- Formulaires tabs : **Simple**, composants réutilisables
- Dark mode : **Simple**, CSS variables

### ⚠️ Attention (Priorité 2)
- Boutons dynamiques DB : **Complexe**, nécessite migration + API
- Dashboard widgets drag-drop : **Moyen**, gestion état complexe
- Présences initiations : **Moyen**, logique métier spécifique

### 🔄 Itératif (Priorité 3)
- Accessibilité complète : **Itératif**, amélioration continue
- Optimisations performance : **Itératif**, profiling nécessaire

---

## 📈 Critères de Succès

### Technique
- ✅ Toutes les fonctionnalités Active Admin migrées
- ✅ Performance : Temps de chargement <2s
- ✅ Accessibilité : Score a11y ≥90
- ✅ Tests : Couverture ≥80%

### Utilisateur
- ✅ Navigation intuitive (temps de découverte <30s)
- ✅ Personnalisation fonctionnelle
- ✅ Responsive sur tous devices
- ✅ Satisfaction utilisateurs ≥4/5

---

## 🎯 Priorisation MVP

### MVP (Sprints 1-3)
1. Sidebar + Menu
2. Recherche globale
3. Tables avec tri/filtres
4. Formulaires basiques

### Phase 2 (Sprints 4-5)
5. Drag-drop colonnes
6. Boutons dynamiques
7. Dashboard personnalisable
8. Formulaires tabs

### Phase 3 (Sprint 6)
9. Présences initiations
10. Dark mode
11. Accessibilité
12. Polish final

---

## 📊 Estimation Totale

```
Sprint 1-2: Infrastructure & Navigation    32 points (16j)
Sprint 3-4: Affichage & Actions             32 points (16j)
Sprint 5-6: Formulaires & Avancé            32 points (16j)
─────────────────────────────────────────────────────
TOTAL:                                      96 points (48j)

Avec 1 dev full-time:  12 semaines (3 mois)
Avec 2 devs:            6-8 semaines
```

---

## 🚦 Go/No-Go Checklist

### Avant Sprint 1
- [ ] Rails 8+ configuré
- [ ] View Components ou React setup
- [ ] Tailwind CSS v3+ installé
- [ ] Staging environment prêt
- [ ] Backup BD actuel
- [ ] Branche git créée
- [ ] CI/CD fonctionnel

### Avant chaque Sprint
- [ ] Review sprint précédent
- [ ] Feedback utilisateurs collecté
- [ ] Priorités ajustées si besoin
- [ ] Tests passants

---

## 📝 Notes Importantes

### Approche Progressive
- **Ne pas tout migrer d'un coup** : Ressource par ressource
- **Tester avec utilisateurs** : Feedback à chaque sprint
- **Itérer** : Améliorer selon retours

### Risques Identifiés
- **Complexité drag-drop** : Utiliser librairie éprouvée (@dnd-kit)
- **Performance tables** : Virtualisation si >1000 lignes
- **Permissions** : Tester Pundit sur chaque feature

### Décisions Techniques
- **Frontend** : Stimulus + View Components (Rails natif) OU React
- **Drag-drop** : @dnd-kit (recommandé)
- **Styling** : Tailwind CSS
- **Tests** : RSpec + Capybara pour E2E

---

## 🎯 Prochaines Actions

1. **Valider ce plan** avec l'équipe
2. **Créer branche** `feature/admin-panel-2025`
3. **Setup infrastructure** (Sprint 1, Jour 1)
4. **Démarrer Sprint 1** : Sidebar component

**Prêt à démarrer ?** 🚀
