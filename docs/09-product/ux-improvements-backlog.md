---
title: "UX Improvements Backlog"
status: "active"
version: "1.1"
created: "2025-11-14"
updated: "2025-11-14"
authors: ["FlowTech"]
tags: ["product", "ux", "backlog", "improvements", "prioritization"]
---

# UX Improvements Backlog

**Document Type** : Complete synthesis of all improvements identified during user journey analysis  
**Status** : Complete backlog ready for implementation  
**Source** : Detailed analysis in [`user-journeys-analysis.md`](user-journeys-analysis.md)

---

## 📋 Vue d'Ensemble

**9 parcours utilisateur analysés** avec identification de **points de friction** et **améliorations possibles**.

**Total des améliorations identifiées** :
- 🟢 **Quick Wins** : 38 améliorations (Impact Haut, Effort Faible) - **+3 URGENTES (liens footer)**
- 🟡 **Améliorations Importantes** : 48 améliorations (Impact Haut, Effort Moyen) - **+6 (pages footer)**
- 🔴 **Améliorations Futures** : 33 améliorations (Impact Moyen, Effort Élevé) - **+3 (blog, carrières)**

**Total** : **119 améliorations** identifiées (**+12 nouvelles** liées au footer)

> **Note** : Ce document sert de backlog pour le développement. Les issues GitHub seront créées uniquement quand nécessaire (avant production ou si besoin de tracking avancé).

---

## 🟢 QUICK WINS (Impact Haut, Effort Faible)

### **Parcours 1 : Découverte de l'Association**
- [ ] ⚠️ **URGENT : Corriger les liens morts du footer** (Remplacer `#` par routes fonctionnelles ou masquer temporairement)
- [ ] Ajouter une section "À propos" sur la homepage (2-3 lignes avec valeurs + lien "En savoir plus")
- [ ] Rendre le bouton "Adhérer" plus clair (Pour non connecté → "S'inscrire pour adhérer")
- [ ] Ajouter un compteur social proof ("Rejoignez X membres" ou "X événements organisés")

### **Parcours 2 : Inscription**
- [ ] Ajouter astérisques `*` aux champs obligatoires (Visuellement clair)
- [ ] Améliorer les messages d'erreur Devise (Traduire/customiser)
- [ ] Message de bienvenue après inscription (Toast "Bienvenue [Prénom] ! Découvrez les événements")
- [ ] Indicateur de force du mot de passe (Barre de progression visuelle)

### **Parcours 3 : Découverte des Événements**
- [ ] Ajouter badge "Nouveau" (Pour événements créés dans les 7 derniers jours)
- [ ] Améliorer troncature lieu (Augmenter à 50 caractères ou afficher sur 2 lignes)
- [ ] Ajouter compteur d'événements ("X événements à venir" visible en haut)
- [ ] Lien "Voir tous les événements passés" (Si >6 événements passés)

### **Parcours 4 : Inscription à un Événement**
- [ ] Ajouter résumé dans modal (Afficher date, heure, lieu avant confirmation)
- [ ] Message de succès personnalisé ("Inscription confirmée ! À bientôt le [date] à [heure]")
- [ ] Indicateur de chargement (Spinner/loader pendant soumission)
- [ ] Alerte "Presque complet" (Si ≤5 places, alerte dans la modal)

### **Parcours 5 : Gestion de Mes Inscriptions**
- [ ] Séparer événements à venir et passés (Section "À venir" et "Passés" avec compteurs)
- [ ] Badge "Passé" (Badge distinctif pour les événements passés)
- [ ] Indicateur rappel dans la liste (Badge "Rappel activé" / "Rappel désactivé" sur chaque card)
- [ ] Compteur d'inscriptions ("X sorties à venir" visible en haut)

### **Parcours 6 : Création d'un Événement**
- [ ] Sauvegarde automatique (localStorage) (Sauvegarder les champs pendant la saisie)
- [ ] Validation en temps réel (Vérifier les champs au blur)
- [ ] Indicateur de progression (Barre "Étape 1/1" ou compteur de champs remplis)
- [ ] Message de confirmation avant soumission ("Votre événement sera en attente de validation. Continuer ?")

### **Parcours 7 : Achat en Boutique**
- [ ] Filtres par catégories (Sidebar ou tabs avec catégories)
- [ ] Barre de recherche (Recherche par nom produit - AJAX)
- [ ] Améliorer image par défaut (Image placeholder plus attrayante si pas d'image_url)
- [ ] Zoom sur image produit (Lightbox pour agrandir l'image au clic)
- [ ] Message "Article ajouté" plus visible (Toast/notification persistante)

### **Parcours 8 : Administration**
- [ ] Dashboard avec statistiques basiques (Cards avec compteurs : Événements à valider, Utilisateurs, Commandes, Revenus)
- [ ] Actions rapides dans liste Events (Boutons "Publier", "Refuser" directement dans Actions)
- [ ] Vue "À valider" améliorée (Panel dédié sur dashboard avec liste + actions rapides)
- [ ] Exports CSV basiques (Bouton "Exporter CSV" sur chaque resource - ActiveAdmin natif)

### **Parcours 9 : Navigation via Footer** ⚠️ NOUVEAU
- [ ] ⚠️ **URGENT : Masquer temporairement sections non implémentées** (Liens morts vers `#`)
- [ ] ⚠️ **URGENT : Corriger liens existants** ("Parcourir" → `/events`, "Créer événement" → `/events/new`)
- [ ] Désactiver newsletter temporairement (Masquer ou message "Bientôt disponible")

---

## 🟡 AMÉLIORATIONS IMPORTANTES (Impact Haut, Effort Moyen)

### **Parcours 1 : Découverte de l'Association**
- [ ] Créer les pages manquantes du footer (Pages statiques : FAQ, Contact, CGU, Confidentialité, Qui sommes-nous, Équipe)
- [ ] Implémenter newsletter fonctionnelle (Formulaire footer + backend avec service email)
- [ ] Lier réseaux sociaux (Ajouter vraies URLs dans variables d'environnement)
- [ ] Section "Pourquoi nous rejoindre ?" (3-4 cards avec valeurs + icônes)
- [ ] Section "Derniers événements" (Carrousel ou grille avec 3-4 derniers événements passés)
- [ ] Section "Tarifs d'adhésion" (Tableau simple avec 3 tarifs + CTA)
- [ ] Améliorer le message vide (Si aucun événement, proposer actions selon rôle)

### **Parcours 2 : Inscription**
- [ ] Validation email en temps réel (Vérifier si email existe déjà via AJAX)
- [ ] Page de bienvenue après inscription (Redirection vers `/welcome` avec guide "Prochaines étapes")
- [ ] Activation validation email (Devise :confirmable - Envoyer email de confirmation)
- [ ] Améliorer la validation téléphone (Format français avec masque de saisie)
- [ ] Indicateur de progression du formulaire (Barre "Étape 1/1" pour préparer futures étapes)

### **Parcours 3 : Découverte des Événements**
- [ ] Barre de recherche (Recherche par titre, description, lieu - AJAX)
- [ ] Filtres basiques (Filtres par date, route, niveau)
- [ ] Pagination (Pagination avec Kaminari/Pagy - 10-15 événements par page)
- [ ] Tri personnalisé (Dropdown "Trier par" : Date, Popularité, Distance, Nouveautés)
- [ ] Vue calendrier (Toggle vue liste/calendrier avec FullCalendar - vue mensuelle)
- [ ] Filtres avancés (Filtres combinés avec tags actifs visibles)

### **Parcours 4 : Inscription à un Événement**
- [ ] Prévisualisation email (Aperçu de l'email de confirmation dans la modal)
- [ ] Conditions d'annulation claires (Mentionner "Vous pouvez annuler jusqu'à [X heures] avant")
- [ ] Confirmation en deux étapes (Étape 1 modal → Étape 2 page de confirmation)
- [ ] Rappel des informations GPS (Si coordonnées GPS, rappeler dans la modal avec liens)
- [ ] Notification push (optionnel) (Demander permission pour notifications push)

### **Parcours 5 : Gestion de Mes Inscriptions**
- [ ] Filtres basiques (Filtres par date, statut rappel)
- [ ] Pagination (Pagination avec Kaminari/Pagy - 10-15 événements par page)
- [ ] Vue calendrier (Toggle vue liste/calendrier avec FullCalendar)
- [ ] Actions en masse (Checkbox pour sélectionner plusieurs événements et désinscription en masse)
- [ ] Export calendrier global (Export iCal de toutes ses inscriptions en une fois)
- [ ] Tri personnalisé (Dropdown "Trier par" : Date, Nom, Distance)

### **Parcours 6 : Création d'un Événement**
- [ ] Formulaire en plusieurs étapes (Étape 1 Infos de base → Étape 2 Détails → Étape 3 Options)
- [ ] Prévisualisation événement (Bouton "Aperçu" qui montre la card événement)
- [ ] Création route depuis formulaire (Modal "Créer un nouveau parcours" directement)
- [ ] Intégration Google Maps (Carte interactive pour sélectionner coordonnées GPS)
- [ ] Duplication d'événement (Bouton "Dupliquer" sur événement existant)
- [ ] Templates d'événements (Templates pré-remplis : "Rando vendredi soir", etc.)
- [ ] Validation côté client (Validation HTML5 + JavaScript avant soumission)

### **Parcours 7 : Achat en Boutique**
- [ ] Tri des produits (Dropdown "Trier par" : Prix, Nom, Popularité)
- [ ] Galerie d'images (Carrousel avec plusieurs images par produit)
- [ ] Panier persistant pour utilisateurs connectés (Sauvegarder panier en DB, fusionner avec session)
- [ ] Sauvegarde panier avant déconnexion (Sauvegarder automatiquement le panier en DB)
- [ ] Récapitulatif avant paiement (Page intermédiaire "Récapitulatif" avec adresse de livraison)
- [ ] Intégration don dans commande (Le don doit être enregistré dans la commande)
- [ ] Suggestions produits ("Produits similaires" ou "Autres clients ont aussi acheté")

### **Parcours 8 : Administration**
- [ ] Bulk actions (Sélectionner plusieurs événements → "Publier en masse", "Refuser en masse")
- [ ] Dashboard complet (Graphiques : événements par mois, inscriptions, revenus)
- [ ] Recherche globale (Barre de recherche qui cherche dans Events, Users, Orders)
- [ ] Regroupement menu (Menu groupé : "Événements" → Events, Routes, Attendances)
- [ ] Exports avancés (Exports CSV personnalisés avec colonnes choisies, exports PDF)
- [ ] Filtres sauvegardés (Permettre de sauvegarder des filtres fréquents)

### **Parcours 9 : Navigation via Footer** ⚠️ NOUVEAU
- [ ] Créer pages statiques essentielles (FAQ, Contact avec formulaire, CGU, Confidentialité RGPD)
- [ ] Créer pages "À propos" (Qui sommes-nous → `/association` ou section dédiée, Équipe si applicable)
- [ ] Gérer liens "Carrières" et "Villes" (Masquer si non applicables ou créer pages placeholder)
- [ ] Créer page Blog (Si blog prévu, créer structure de base ou masquer le lien)

---

## 🔴 AMÉLIORATIONS FUTURES (Impact Moyen, Effort Élevé)

### **Parcours 1 : Découverte de l'Association**
- [ ] Témoignages membres (Section avec 2-3 témoignages + photos)
- [ ] Galerie photos (Carrousel avec photos d'événements passés)
- [ ] Carte interactive (Carte avec points de départ des événements récurrents)

### **Parcours 2 : Inscription**
- [ ] Inscription en plusieurs étapes (Étape 1 identité → Étape 2 profil → Étape 3 préférences)
- [ ] Inscription via réseaux sociaux (OAuth : Google, Facebook)
- [ ] Vérification téléphone (SMS) (Optionnel pour sécurité renforcée)
- [ ] Onboarding interactif (Tour guidé de l'application après première connexion)

### **Parcours 3 : Découverte des Événements**
- [ ] Carte interactive (Carte avec points des événements, filtrage par zone géographique)
- [ ] Suggestions personnalisées ("Événements qui pourraient vous intéresser" basé sur historique)
- [ ] Filtres sauvegardés (Permettre de sauvegarder des filtres favoris)
- [ ] Export calendrier global (Export iCal de tous les événements à venir)

### **Parcours 4 : Inscription à un Événement**
- [ ] Inscription avec paiement (Si événement payant, intégrer le paiement dans le flux)
- [ ] Inscription groupée (Permettre d'inscrire plusieurs personnes en une fois)
- [ ] Liste d'attente (Si événement complet, proposer de s'inscrire sur liste d'attente)
- [ ] QR code de confirmation (Générer un QR code unique pour chaque inscription)

### **Parcours 5 : Gestion de Mes Inscriptions**
- [ ] Statistiques personnelles (Graphique "Nombre de sorties par mois", "Kilomètres parcourus")
- [ ] Historique complet (Voir toutes les sorties y compris annulées avec filtre par statut)
- [ ] Rappels personnalisés (Paramètres globaux pour rappels : toujours activer, désactiver)
- [ ] Partage de ses sorties (Lien public pour partager sa liste de sorties à venir)

### **Parcours 6 : Création d'un Événement**
- [ ] Éditeur WYSIWYG pour description (Éditeur riche : Trix, TinyMCE)
- [ ] Upload image direct (Upload d'image depuis l'ordinateur - Active Storage)
- [ ] Planification récurrente (Créer plusieurs événements à la fois : tous les vendredis du mois)
- [ ] Aide contextuelle avancée (Tooltips avec exemples concrets pour chaque champ)
- [ ] Historique de modifications (Voir l'historique des modifications d'un événement)

### **Parcours 7 : Achat en Boutique**
- [ ] Comparaison de produits (Permettre de comparer 2-3 produits côte à côte)
- [ ] Liste de souhaits (Wishlist) (Permettre d'ajouter des produits à une liste de souhaits)
- [ ] Avis clients (Système d'avis et notes sur les produits)
- [ ] Historique de navigation ("Produits récemment consultés")
- [ ] Notifications stock ("Me prévenir quand ce produit sera de nouveau en stock")
- [ ] Codes promo (Système de codes promotionnels)

### **Parcours 8 : Administration**
- [ ] Tableau de bord personnalisable (Admin peut choisir quels widgets afficher)
- [ ] Notifications admin (Alertes pour événements à valider, commandes en attente)
- [ ] Workflow de modération (Interface dédiée pour modérer avec commentaires)
- [ ] Rapports automatiques (Génération automatique de rapports par email)
- [ ] Audit trail visuel (Voir l'historique des modifications avec qui/quand)

### **Parcours 9 : Navigation via Footer** ⚠️ NOUVEAU
- [ ] Système de blog complet (Si blog prévu : articles, catégories, commentaires)
- [ ] Page Carrières (Si recrutement prévu : offres d'emploi)
- [ ] Filtres "Catégories" et "Villes" (Si filtres événements prévus : pages dédiées)
- [ ] Newsletter avancée (Segmentation, templates, analytics)

---

## 📊 Statistiques par Parcours

| Parcours | Quick Wins | Importantes | Futures | **Total** |
|----------|------------|-------------|---------|-----------|
| **Parcours 1** : Découverte Association | 3 | 4 | 3 | **10** |
| **Parcours 2** : Inscription | 4 | 5 | 4 | **13** |
| **Parcours 3** : Découverte Événements | 4 | 6 | 4 | **14** |
| **Parcours 4** : Inscription Événement | 4 | 5 | 4 | **13** |
| **Parcours 5** : Mes Inscriptions | 4 | 6 | 4 | **14** |
| **Parcours 6** : Création Événement | 4 | 7 | 5 | **16** |
| **Parcours 7** : Achat Boutique | 5 | 7 | 6 | **18** |
| **Parcours 8** : Administration | 4 | 6 | 5 | **15** |
| **Parcours 9** : Navigation Footer | 3 | 4 | 3 | **10** |
| **TOTAL** | **38** | **48** | **33** | **119** |

---

## 🎯 Priorisation Globale (Top 11 Quick Wins)

### **Top 11 des Quick Wins à implémenter en priorité** :

1. **⚠️ URGENT : Corriger liens morts du footer** (Parcours 9)
   - Impact : Très haut (frustration majeure utilisateurs)
   - Effort : Très faible (masquer sections ou corriger liens existants)

2. **Dashboard admin avec statistiques** (Parcours 8)
   - Impact : Très haut (admin voit l'état de l'app en un coup d'œil)
   - Effort : Faible (cards simples avec compteurs)

3. **Section "À propos" sur homepage** (Parcours 1)
   - Impact : Haut (visiteurs comprennent mieux l'association)
   - Effort : Faible (2-3 lignes + lien)

4. **Astérisques champs obligatoires** (Parcours 2)
   - Impact : Haut (clarté immédiate pour utilisateurs)
   - Effort : Très faible (ajout `*` dans labels)

5. **Séparer événements à venir/passés** (Parcours 5)
   - Impact : Haut (organisation claire de "Mes sorties")
   - Effort : Faible (2 sections avec filtres)

6. **Filtres par catégories boutique** (Parcours 7)
   - Impact : Haut (navigation facilitée dans le catalogue)
   - Effort : Faible (sidebar ou tabs avec catégories existantes)

7. **Résumé dans modal inscription** (Parcours 4)
   - Impact : Haut (rassure l'utilisateur avant confirmation)
   - Effort : Faible (afficher date/heure/lieu dans modal)

8. **Message de bienvenue après inscription** (Parcours 2)
   - Impact : Haut (première impression positive)
   - Effort : Faible (toast/alerte avec message personnalisé)

9. **Badge "Nouveau" sur événements** (Parcours 3)
   - Impact : Moyen-Haut (mise en avant des nouveautés)
   - Effort : Très faible (badge conditionnel)

10. **Actions rapides dans liste Events admin** (Parcours 8)
   - Impact : Très haut (gain de temps pour modération)
   - Effort : Faible (boutons "Publier"/"Refuser" dans colonne Actions)

11. **Sauvegarde automatique formulaire événement** (Parcours 6)
    - Impact : Haut (évite perte de données)
    - Effort : Faible (localStorage JavaScript)

---

## 📈 Matrice Impact vs Effort (Synthèse)

### **🟢 Zone Quick Wins (Priorité 1)**
**38 améliorations** - À implémenter en premier (**+3 URGENTES footer**)
- Impact : Haut à Très Haut
- Effort : Faible
- ROI : Très élevé

### **🟡 Zone Importantes (Priorité 2)**
**48 améliorations** - À planifier après Quick Wins (**+6 pages footer**)
- Impact : Haut
- Effort : Moyen
- ROI : Élevé

### **🔴 Zone Futures (Priorité 3)**
**33 améliorations** - À considérer selon besoins (**+3 blog/carrières**)
- Impact : Moyen
- Effort : Élevé
- ROI : Variable

---

## 🎯 Plan d'Action Recommandé

### **🔴 SPRINT 0 : Audit & Fondations Accessibilité (1 semaine) - NOUVEAU**
**Objectif** : Établir baseline de conformité + corriger critiques  
**Priorité** : 🔴 CRITIQUE - À faire AVANT Phase 1

**Jour 1-2 : Audit automatisé complet**
- WAVE, Axe DevTools, Lighthouse sur toutes les pages principales
- Focus : Footer, Header, Forms, Navigation, Events, Shop
- Identification problèmes critiques (contrastes, focus, navigation clavier)

**Jour 3 : Corrections critiques**
- ✅ Footer : Liens morts corrigés (déjà fait)
- ✅ Footer : Focus states ajoutés (déjà fait)
- ✅ Footer : Contraste couleurs amélioré (déjà fait)
- 🔴 **Footer : Variables dual-theme mode clair/sombre** (à finaliser - voir section CSS ci-dessous)
- 🔴 Header/Navigation : Audit contraste + focus states
- 🔴 Formulaires : Labels, focus, erreurs accessibles

**Jour 4 : Infrastructure tests continus**
- Setup CI/CD accessibilité (Axe, Lighthouse, Pa11y)
- Definition of Done accessibilité documentée
- Checklist développeur accessibilité créée

**Jour 5 : Documentation + formation**
- Rapport d'audit complet
- Guide accessibilité pour développeurs
- Formation équipe sur bonnes pratiques

**Livrables** :
- ✅ Baseline conformité WCAG 2.1 AA établie
- ✅ Corrections critiques appliquées
- ✅ Infrastructure tests automatisés opérationnelle
- ✅ Documentation accessibilité complète

---

### **Phase 1 : Quick Wins (2-3 semaines)**
**Objectif** : Implémenter les 10-15 Quick Wins les plus impactants  
**Accessibilité** : Tests intégrés à chaque sprint (15-20% du temps)

**Sprint 1 (Semaine 1)** :
**Développement** (3-4 jours) :
- Dashboard admin avec statistiques
- Section "À propos" homepage
- Astérisques champs obligatoires
- Message de bienvenue après inscription

**Tests A11y intégrés** (1 jour) :
- Contraste couleurs dashboard
- Navigation clavier complète
- Labels descriptifs statistiques
- Test lecteur d'écran section "À propos"

**Sprint 2 (Semaine 2)** :
**Développement** (3-4 jours) :
- Séparer événements à venir/passés
- Filtres catégories boutique
- Résumé dans modal inscription
- Actions rapides admin
- Sauvegarde automatique formulaire

**Tests A11y intégrés** (1 jour) :
- Navigation au clavier dans filtres
- Annonces ARIA pour sections dynamiques
- Modal accessible (focus trap, Esc pour fermer)
- Labels filtres descriptifs

**Sprint 3 (Semaine 3)** :
**Développement** (2-3 jours) :
- Améliorer messages d'erreur Devise
- Indicateur force mot de passe
- Compteurs d'événements/inscriptions
- Zoom sur image produit
- Exports CSV admin

**Tests A11y intégrés** (1 jour) :
- Indicateur mot de passe accessible (annonces ARIA live)
- Compteurs avec labels sémantiques
- Boutons export avec labels descriptifs

**Validation finale Phase 1** (1 jour) :
- Audit complet nouvelles fonctionnalités
- Régression testing (vérifier que rien n'a cassé)
- Mise à jour rapport conformité

---

### **Phase 2 : Améliorations Importantes (4-6 semaines)**
**Objectif** : Implémenter les améliorations à impact élevé  
**Accessibilité** : Tests continus (15-20% temps) + audit intermédiaire

**Sprints 4-9 : Améliorations Importantes**
**Chaque sprint** (1-2 semaines) :
- Développement fonctionnalités (70-80% temps)
- Tests A11y intégrés (15-20% temps)
- Tests régression (5-10% temps)

**Focus fonctionnel** :
- Filtres et recherche (Parcours 3, 5, 7)
- Pagination (Parcours 3, 5)
- Panier persistant (Parcours 7)
- Bulk actions admin (Parcours 8)
- Dashboard admin complet (Parcours 8)

**Audit intermédiaire** (après Sprint 6 - mi-Phase 2) :
- Durée : 2-3 jours
- Objectif : Vérifier conformité globale avant fin Phase 2
- Actions : Audit automatisé + tests manuels parcours complets

**Validation finale Phase 2** (après Sprint 9) :
- Audit complet toutes fonctionnalités
- Tests utilisateurs avec technologies d'assistance
- Rapport conformité final

---

### **Phase 3 : Améliorations Futures (Selon besoins)**
**Objectif** : Implémenter selon retours utilisateurs et priorités business  
**Accessibilité** : Intégrée dès la conception (15-20% temps)

**Pour chaque nouvelle feature** :
1. **Design accessible** dès le wireframe
   - Vérifier contrastes couleurs
   - Prévoir focus states
   - Planifier navigation clavier

2. **Développement avec tests continus**
   - Linters accessibilité actifs
   - Tests automatisés CI/CD
   - Validation développeur avant PR

3. **Validation A11y avant mise en prod**
   - Tests manuels complets
   - Validation lecteur d'écran
   - Vérification WCAG 2.1 AA

**Audits périodiques** :
- Tous les 6-12 mois après lancement
- Tests utilisateurs avec personnes en situation de handicap
- Mise à jour documentation accessibilité

---

## ♿ Accessibilité : Approche Transversale

### **Stratégie d'Intégration**
L'accessibilité n'est **PAS une phase distincte**, c'est une **pratique continue** intégrée à chaque sprint.

### **Répartition du Temps Accessibilité**

| Phase | Durée totale | Temps A11y | % du temps | Activités A11y |
|-------|--------------|------------|-------------|---------------|
| **Sprint 0** : Audit initial | 1 semaine | 5 jours | 100% | Audit complet + corrections critiques |
| **Phase 1** : Quick Wins | 3 semaines | 3 jours | 20% | Tests continus + validation finale |
| **Phase 2** : Importantes | 6 semaines | 6-8 jours | 15-20% | Tests continus + audit intermédiaire |
| **Phase 3** : Futures | Variable | 15-20% | 15-20% | Tests continus + audits périodiques |
| **Maintenance** | Permanent | 1-2 jours/6 mois | N/A | Audits semestriels + monitoring |

### **Definition of Done - Accessibilité**
Une user story est "Done" quand :
- ✅ **Contraste** : Tous ratios ≥ 4.5:1 (texte normal) ou ≥ 3:1 (texte large)
- ✅ **Focus** : Outline visible 2px minimum sur tous éléments interactifs
- ✅ **Clavier** : Navigation complète au clavier (Tab, Shift+Tab, Enter, Esc)
- ✅ **ARIA** : Labels descriptifs sur éléments interactifs et annonces live si dynamique
- ✅ **Sémantique** : HTML sémantique correct (headings, landmarks, listes)
- ✅ **Tests auto** : Passage Axe, Lighthouse (score ≥90), Pa11y sans erreur
- ✅ **Test manuel** : Validation navigation clavier + lecteur d'écran (NVDA)
- ✅ **Responsive** : Fonctionnel à 200% zoom, cibles tactiles ≥44×44px mobile

### **Infrastructure Accessibilité**
- **CI/CD** : Tests automatisés (Axe, Lighthouse, Pa11y) sur chaque PR
- **Outils** : WAVE Extension, Axe DevTools, WebAIM Contrast Checker
- **Monitoring** : Audits automatisés hebdomadaires + rapports

### **ROI Accessibilité**
- ✅ **Réduction coûts** : Corriger un bug A11y après lancement coûte 10x plus cher
- ✅ **Conformité légale** : Éviter amendes EAA (jusqu'à 4% CA)
- ✅ **Qualité code** : Code sémantique = code maintenable
- ✅ **UX améliorée** : Bénéficie à 100% des utilisateurs
- ✅ **Moins de dette technique** : Pas de gros chantier de remédiation plus tard

### **🔴 Corrections CSS Critiques - Sprint 0**

**Problème identifié** : Variables CSS non optimisées pour mode clair ET sombre simultanément

**Corrections à appliquer** :

1. **Variables dual-theme pour footer** :
   ```scss
   /* Mode clair - valeurs corrigées */
   :root {
     --gr-muted: #5a6268;        /* Corrigé de #6c757d - meilleur contraste */
     --gr-primary: #0056b3;      /* Corrigé de #007bff - meilleur contraste */
   }
   
   /* Mode sombre - overrides complets */
   [data-bs-theme="dark"] {
     --gr-muted-dark: #a0a0a0;   /* Ratio 6.66:1 - conforme ✅ */
     --gr-primary-dark: #4d94ff; /* Ratio 5.80:1 - conforme ✅ */
     --gr-text-dark: #e5e5e5;    /* Texte principal */
   }
   
   /* Footer mode sombre avec couleurs corrigées */
   [data-bs-theme="dark"] .footer-grenoble-roller {
     background: #0a0a0a; /* Near-black, pas pure black */
     color: var(--gr-text-dark);
   }
   
   [data-bs-theme="dark"] .footer-grenoble-roller .text-muted {
     color: var(--gr-muted-dark) !important;
   }
   
   [data-bs-theme="dark"] .footer-grenoble-roller .footer-link {
     color: var(--gr-text-dark);
   }
   
   [data-bs-theme="dark"] .footer-grenoble-roller .footer-link:hover,
   [data-bs-theme="dark"] .footer-grenoble-roller .footer-link:focus-visible {
     color: var(--gr-primary-dark);
     outline-color: var(--gr-primary-dark);
   }
   ```

2. **Audit systématique autres sections** (Semaine 2-3) :
   - Navigation principale (header/navbar)
   - Boutons et CTAs
   - Formulaires
   - Cards et conteneurs
   - Texte de contenu principal

3. **Design system cohérent** (Moyen terme) :
   - Variables CSS systématiques pour tous les composants
   - Documentation des ratios de contraste
   - Tests automatisés de contraste en CI/CD

**Priorité** : 🔴 CRITIQUE - À faire en Sprint 0 (Jour 3)

---

## 📝 Notes Importantes

### **Points d'Attention**
- **Cohérence** : Maintenir la cohérence visuelle entre tous les parcours
- **Accessibilité** : ✅ **Intégrée transversalement** - Tests A11y à chaque sprint (15-20% temps)
- **Performance** : S'assurer que les améliorations ne dégradent pas les performances
- **Tests** : Ajouter des tests pour chaque amélioration implémentée

### **Méthodologie Shape Up**
- **Appetite fixe** : 2-3 semaines pour Phase 1 (Quick Wins)
- **Scope flexible** : Si pas fini → réduire scope, pas étendre deadline
- **Cooldown** : Prévoir cooldown après Phase 1 pour intégrer retours utilisateurs
- **Accessibilité** : Sprint 0 obligatoire AVANT Phase 1 (audit + fondations)

---

## 🔗 Références

- **Detailed analysis** : [`user-journeys-analysis.md`](user-journeys-analysis.md)
- **Méthodologie** : [`../02-shape-up/`](../02-shape-up/)
- **Pièges à éviter** : [`../../ressources/Pieges_A_Eviter.md`](../../ressources/Pieges_A_Eviter.md)

---

**Document créé le** : 2025-11-14  
**Dernière mise à jour** : 2025-11-14  
**Version** : 1.1 (Intégration accessibilité transversale)

