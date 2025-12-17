# Prompts Perplexity - Décisions Techniques Panel Admin

**Objectif** : Prompts à copier-coller dans Perplexity pour obtenir des recommandations techniques  
**Usage** : Pour chaque prompt, copier le contenu et demander à Perplexity de fournir plusieurs solutions avec avantages/inconvénients

---

## 🎯 Prompt 1 : Drag-Drop Colonnes Table (Alternative à @dnd-kit)

```
Je développe un panel admin Rails 8 avec Bootstrap 5.3.2 et Stimulus (pas React). 

Problème : Je dois implémenter le réordonnage de colonnes de table par drag-drop. Le plan original mentionnait @dnd-kit mais c'est une librairie React, donc incompatible avec ma stack Stimulus.

Contraintes :
- Stack : Rails 8, Bootstrap 5.3.2, Stimulus (Hotwire), Partials Rails (pas View Components)
- Pas de React, pas de Vue, 100% Rails monolithique
- Accessibilité : Doit être accessible clavier (WCAG 2.1 AA)
- Performance : Tables peuvent avoir jusqu'à 1000 lignes
- Persistence : Sauvegarder l'ordre des colonnes par utilisateur (localStorage ou DB)

Questions :
1. Quelle est la meilleure solution pour drag-drop colonnes avec HTML5 Drag API + Stimulus ?
2. Y a-t-il une alternative simple sans drag-drop (boutons haut/bas) qui serait plus maintenable ?
3. Comment gérer l'accessibilité clavier pour réordonner sans drag-drop ?
4. Quelle librairie JavaScript vanilla/Stimulus recommander pour drag-drop accessible ?

Merci de proposer 2-3 solutions différentes avec avantages/inconvénients, et de recommander la meilleure pour un projet Rails monolithique.
```

---

## 🎯 Prompt 2 : Sidebar Collapsible Bootstrap 5

```
Je développe un panel admin Rails avec Bootstrap 5.3.2 et Stimulus.

Besoin : Sidebar collapsible avec deux états :
- Expanded : 280px de largeur (labels + icons)
- Collapsed : 64px de largeur (icons seulement + tooltips)

Responsive :
- Desktop (≥1200px) : Sidebar expandable à gauche
- Tablet (768px-1200px) : Sidebar collapsed par défaut
- Mobile (<768px) : Sidebar hidden, affichée via hamburger (Bootstrap offcanvas)

Contraintes :
- Bootstrap 5.3.2 disponible (offcanvas, collapse, etc.)
- Stimulus pour l'interactivité
- Persistence état collapsed/expanded (localStorage)
- Animation smooth 300ms
- Accessibilité : ARIA labels, navigation clavier

Questions :
1. Quelle est la meilleure approche Bootstrap 5 pour sidebar collapsible (offcanvas, collapse, ou custom) ?
2. Comment gérer le layout responsive (desktop sidebar fixe, mobile offcanvas) ?
3. Comment implémenter les tooltips sur les icons quand collapsed (Bootstrap tooltips ou custom) ?
4. Quelle structure HTML/Bootstrap recommander pour le menu hiérarchique (expand/collapse par section) ?

Merci de proposer 2-3 approches avec exemples de code Bootstrap 5, et de recommander la meilleure.
```

---

## 🎯 Prompt 3 : Recherche Globale Cmd+K (Stimulus)

```
Je développe un panel admin Rails avec Stimulus (Hotwire).

Besoin : Recherche globale déclenchée par Cmd+K (ou Ctrl+K) avec :
- Modal/searchbar qui s'ouvre au raccourci clavier
- Recherche dans : ressources (Users, Products, Events), pages (Dashboard), utilisateurs récents
- Navigation clavier : flèches haut/bas pour sélectionner, Enter pour naviguer
- Limiter à 10 résultats maximum
- Temps de réponse < 200ms

Contraintes :
- Stimulus controller (pas React)
- Bootstrap 5.3.2 pour le modal
- Recherche côté serveur (Rails controller) ou côté client (JavaScript) ?
- Accessibilité : ARIA live regions, focus management

Questions :
1. Quelle est la meilleure approche : recherche côté serveur (AJAX) ou côté client (filtrage JS) ?
2. Comment gérer le raccourci clavier Cmd+K avec Stimulus (éviter conflits avec navigateur) ?
3. Quelle structure de données recommander pour indexer les résultats (endpoints API, ou données inline) ?
4. Comment implémenter la navigation clavier accessible (flèches, Enter, Escape) ?

Merci de proposer 2-3 solutions avec exemples Stimulus, et de recommander la meilleure pour performance + accessibilité.
```

---

## 🎯 Prompt 4 : Dashboard Widgets Drag-Drop

```
Je développe un panel admin Rails avec Bootstrap 5.3.2 et Stimulus.

Besoin : Dashboard avec widgets réordonnables (drag-drop) :
- 8 widgets (statistiques, graphiques, listes)
- Réordonnage par drag-drop
- Sauvegarde positions en base de données (par utilisateur)
- Responsive : grille adaptative (4 colonnes desktop, 2 tablet, 1 mobile)

Contraintes :
- Stack : Rails 8, Bootstrap 5.3.2, Stimulus (pas React)
- Pas de @dnd-kit (React), besoin solution HTML5 Drag API ou alternative
- Performance : Widgets peuvent charger des données async
- Accessibilité : Navigation clavier pour réordonner

Questions :
1. Quelle est la meilleure solution : HTML5 Drag API + Stimulus, ou alternative plus simple ?
2. Alternative : Commencer avec ordre fixe, puis ajouter drag-drop après (recommandé pour MVP) ?
3. Comment gérer la grille responsive avec drag-drop (CSS Grid, Flexbox, ou Bootstrap grid) ?
4. Quelle structure DB recommander pour sauvegarder positions (JSON column, ou table séparée) ?

Merci de proposer 2-3 solutions (dont une "simple d'abord"), avec avantages/inconvénients, et de recommander pour un MVP progressif.
```

---

## 🎯 Prompt 5 : Validation Inline Formulaires

```
Je développe un panel admin Rails avec Bootstrap 5.3.2 et Stimulus.

Besoin : Validation inline dans les formulaires :
- Validation en temps réel (sur blur ou input)
- Messages d'erreur clairs (Bootstrap validation classes)
- Désactiver submit jusqu'à correction
- Gestion erreurs serveur (affichage après submit si échec)

Contraintes :
- Bootstrap 5 validation classes (`is-invalid`, `invalid-feedback`)
- Stimulus controller pour logique
- Rails validations côté serveur (ActiveRecord)
- Accessibilité : ARIA attributes, messages d'erreur liés aux champs

Questions :
1. Quelle est la meilleure approche : validation côté client (JS) + serveur (Rails), ou serveur uniquement ?
2. Comment synchroniser validations Rails avec feedback visuel Bootstrap ?
3. Comment gérer les erreurs serveur et les afficher inline (Turbo/Fetch API response) ?
4. Quelle structure Stimulus recommander pour valider multiple champs (controller par formulaire, ou par champ) ?

Merci de proposer 2-3 solutions avec exemples Stimulus + Bootstrap validation, et de recommander la meilleure.
```

---

## 🎯 Prompt 6 : Dark Mode Bootstrap 5 ⚠️ DÉJÀ IMPLÉMENTÉ

**STATUT** : ❌ **NON NÉCESSAIRE** - Le dark mode est déjà complètement implémenté dans le projet.

**Implémentation existante** :
- Toggle dans la navbar (`app/views/layouts/_navbar.html.erb`)
- Fonction `toggleTheme()` dans `app/views/layouts/application.html.erb`
- Persistence localStorage (`theme`)
- Bootstrap 5 `data-bs-theme="dark"` sur `<html>`
- CSS custom avec `[data-bs-theme=dark]` dans `_style.scss`

**Pour le panel admin** :
- ✅ Réutiliser le même système (toggle déjà dans navbar globale)
- ✅ Layout admin hérite automatiquement du thème via `data-bs-theme` sur `<html>`
- ✅ Classes Bootstrap supportent déjà le dark mode
- ✅ Classes Liquid custom ont déjà support dark mode (`[data-bs-theme=dark]`)

**Action requise** : Aucune, juste s'assurer que le layout admin utilise le même `<html data-bs-theme>`.
```

---

## 📝 Instructions d'Usage

1. **Copier le prompt** qui correspond à votre question
2. **Coller dans Perplexity** avec le contexte suivant en préfixe :
   > "Je développe un panel admin Rails 8 avec Bootstrap 5.3.2 et Stimulus (Hotwire). Voici ma question :"
3. **Demander explicitement** : "Merci de proposer 2-3 solutions avec avantages/inconvénients, code d'exemple si possible, et de recommander la meilleure pour mon contexte."
4. **Prendre en compte** : Les réponses doivent être compatibles avec Rails monolithique, pas de React/Vue/API séparée

---

## 🎯 Priorisation des Questions

### Priorité 1 (MVP - Sprints 1-2)
- **Prompt 2** : Sidebar Collapsible (US-001, US-003)
- **Prompt 3** : Recherche Globale (US-004)
- ~~**Prompt 6** : Dark Mode (US-017)~~ ✅ Déjà implémenté, réutiliser

### Priorité 2 (Features Avancées - Sprints 3-5)
- **Prompt 1** : Drag-Drop Colonnes (US-007) - Alternative simple d'abord
- **Prompt 4** : Dashboard Widgets (US-011) - Ordre fixe d'abord
- **Prompt 5** : Validation Inline (US-015)

---

**Document créé le** : 2025-01-27  
**Dernière mise à jour** : 2025-01-27  
**Version** : 1.0

