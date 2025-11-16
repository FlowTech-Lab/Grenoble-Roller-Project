---
title: "Plan d'Action - Quick Wins"
status: "active"
version: "1.0"
created: "2025-11-15"
tags: ["product", "ux", "quick-wins", "plan"]
---

# Plan d'Action - Quick Wins

**Objectif** : Implémenter les Quick Wins prioritaires de manière méthodique  
**Source** : [`ux-improvements-backlog.md`](ux-improvements-backlog.md)

---

## 📊 État Actuel Identifié

### ✅ **Déjà Fait (mais pas coché dans backlog)** :
1. **Astérisques champs obligatoires** ✅
   - Classe `.required` sur labels
   - Légende "Champs obligatoires" avec `*`
   - CSS avec `::after { content: "*" }`
   - **Fichiers** : `app/views/devise/registrations/new.html.erb`, `app/assets/stylesheets/_style.scss`
   - **Status** : ✅ Coché dans backlog

2. **Liens footer masqués** ✅
   - Contact/CGU/Confidentialité masqués avec `<% if false %>`
   - **Fichier** : `app/views/layouts/_footer-simple.html.erb` (lignes 54-61)
   - **Status** : 🟡 Partiellement fait (liens existants corrigés, Contact/CGU/Confidentialité restent `#`)

### ✅ **Terminés Aujourd'hui (2025-11-15)** :
3. **Badge "Nouveau" sur événements** ✅
   - Méthode `recent?` dans modèle Event (7 derniers jours)
   - Badge conditionnel dans `_event_card.html.erb`
   - Style badge "Nouveau" avec `badge-liquid-success`
   - **Fichiers** : `app/models/event.rb`, `app/views/events/_event_card.html.erb`

4. **Compteur d'événements à venir** ✅
   - Compteur en haut de `events/index.html.erb`
   - Utilise `pluralize(@upcoming_events.size, "événement", "événements")`
   - **Fichier** : `app/views/events/index.html.erb`

5. **Bouton "Adhérer" plus clair** ✅
   - Texte changé pour non connecté : "S'inscrire pour adhérer"
   - Utilise `link_to` avec `new_user_registration_path`
   - **Fichier** : `app/views/pages/index.html.erb`

6. **Refactorisation highlighted_event** ✅
   - Suppression de la logique `@highlighted_event` séparée dans le contrôleur
   - Intégration dans la grille avec badge "Prochain" sur le premier événement
   - Badge "Prochain" aligné avec badge de date (`top: 1rem`)
   - Grille Bootstrap fonctionnelle (modals en dehors de la div colonne)
   - **Fichiers** : `app/controllers/events_controller.rb`, `app/views/events/index.html.erb`, `app/views/events/_event_card.html.erb`

### ⏳ **À Faire (par ordre de priorité)** :

---

## 🎯 Plan d'Action Méthodique

### **Phase 1 : Corrections Urgentes (30 min)**

#### 1.1 Vérifier et finaliser liens footer
- [ ] Vérifier que les liens Contact/CGU/Confidentialité sont bien masqués
- [ ] Cocher dans backlog si confirmé
- **Fichier** : `app/views/layouts/_footer-simple.html.erb`

#### 1.2 Cocher astérisques dans backlog
- [ ] Vérifier que tous les formulaires ont les astérisques
- [ ] Cocher dans backlog
- **Fichiers** : `app/views/devise/**/*.html.erb`

---

### **Phase 2 : Quick Wins Faciles (2-3h)**

#### 2.1 Section "À propos" sur homepage
- [ ] Analyser structure actuelle homepage
- [ ] Déterminer emplacement (après hero, avant événements ?)
- [ ] Créer section avec 2-3 lignes + valeurs + lien "En savoir plus"
- [ ] Utiliser données dynamiques (stats depuis DB)
- [ ] Tester responsive
- **Fichier** : `app/views/pages/index.html.erb`
- **Controller** : `app/controllers/pages_controller.rb` (stats déjà disponibles)

#### 2.2 Badge "Nouveau" sur événements ✅ TERMINÉ
- [x] Ajouter méthode `recent?` dans modèle Event (créé dans les 7 derniers jours)
- [x] Ajouter badge conditionnel dans `_event_card.html.erb`
- [x] Style badge "Nouveau" (couleur distincte `badge-liquid-success`)
- **Fichiers** : `app/models/event.rb`, `app/views/events/_event_card.html.erb`
- **Date** : 2025-11-15

#### 2.3 Compteur d'événements à venir ✅ TERMINÉ
- [x] Ajouter compteur en haut de `events/index.html.erb`
- [x] Utiliser `pluralize(@upcoming_events.size, "événement", "événements")`
- [x] Style cohérent avec design (badge badge-liquid-primary)
- **Fichier** : `app/views/events/index.html.erb`
- **Date** : 2025-11-15

---

### **Phase 3 : Quick Wins Moyens (3-4h)**

#### 3.1 Message de bienvenue après inscription
- [ ] Créer/customiser `RegistrationsController` si nécessaire
- [ ] Ajouter flash message après `create`
- [ ] Personnaliser avec prénom utilisateur
- [ ] Style toast/notification
- [ ] Tester redirection
- **Fichiers** : `app/controllers/registrations_controller.rb` (ou Devise), `app/views/layouts/_flash.html.erb`

#### 3.2 Bouton "Adhérer" plus clair ✅ TERMINÉ
- [x] Analyser logique actuelle (ligne 33-36 de `index.html.erb`)
- [x] Changer texte pour non connecté : "S'inscrire pour adhérer"
- [x] Utiliser `link_to` avec `new_user_registration_path`
- **Fichier** : `app/views/pages/index.html.erb`
- **Date** : 2025-11-15

#### 3.3 Compteur social proof
- [ ] Ajouter compteur membres/événements sur homepage
- [ ] Utiliser stats depuis `PagesController#about` (déjà disponibles)
- [ ] Style discret mais visible
- [ ] Placement : dans hero ou section dédiée
- **Fichier** : `app/views/pages/index.html.erb`
- **Controller** : `app/controllers/pages_controller.rb`

---

## 📋 Checklist d'Implémentation

### Avant de commencer chaque tâche :
- [ ] Lire le code existant
- [ ] Comprendre la structure
- [ ] Identifier les dépendances
- [ ] Vérifier les conventions de code

### Pendant l'implémentation :
- [ ] Suivre les conventions existantes
- [ ] Tester visuellement
- [ ] Vérifier responsive
- [ ] Vérifier accessibilité (contraste, focus, ARIA)

### Après chaque tâche :
- [ ] Cocher dans backlog
- [ ] Tester fonctionnalité
- [ ] Vérifier pas de régression
- [ ] Documenter si nécessaire

---

## 🎯 Ordre d'Exécution Recommandé

1. **Vérifications rapides** (5 min)
   - Cocher astérisques ✅
   - Cocher liens footer masqués ✅

2. **Quick Wins très faciles** (1-2h)
   - Badge "Nouveau" événements
   - Compteur événements à venir

3. **Quick Wins faciles** (2-3h)
   - Section "À propos" homepage
   - Bouton "Adhérer" plus clair

4. **Quick Wins moyens** (3-4h)
   - Message bienvenue inscription
   - Compteur social proof

---

## 📝 Notes Importantes

- **Cohérence** : Respecter le design system existant (liquid, glassmorphism)
- **Accessibilité** : Vérifier contrastes, focus states, ARIA
- **Responsive** : Tester mobile/tablette/desktop
- **Performance** : Éviter requêtes N+1, utiliser `includes` si nécessaire

---

**Dernière mise à jour** : 2025-11-15  
**Version** : 1.1 (Mise à jour avec Quick Wins terminés aujourd'hui)

