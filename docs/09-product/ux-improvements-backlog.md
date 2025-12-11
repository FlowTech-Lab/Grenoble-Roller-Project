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

**Statut vérification** : ✅ **Vérification complète effectuée** (2025-01-30)

**Avancement** : **27/41 Quick Wins terminés** (66%) + **2 partiellement faits**

> **Note** : Ce document sert de backlog pour le développement. Les issues GitHub seront créées uniquement quand nécessaire (avant production ou si besoin de tracking avancé).

---

## 🟢 QUICK WINS (Impact Haut, Effort Faible)

### **Parcours 1 : Découverte de l'Association**
- [x] ⚠️ **URGENT : Corriger les liens morts du footer** ✅ **TERMINÉ** - Tous les liens principaux fonctionnent (Contact, CGU, Confidentialité, Mentions Légales, CGV)
- [x] Ajouter une section "À propos" sur la homepage (2-3 lignes avec valeurs + lien "En savoir plus") ✅ **TERMINÉ** (2025-01-30) - Section dédiée "À propos de Grenoble Roller" ajoutée juste après le hero banner avec description concise et CTA vers page complète
- [x] Rendre le bouton "Adhérer" plus clair (Pour non connecté → "S'inscrire pour adhérer") ✅ Implémenté
- [x] Ajouter un compteur social proof ("Rejoignez X membres" ou "X événements organisés") ✅ Bloc "Chiffres clés" (4 stats) sur la homepage et sur `/a-propos`

### **Parcours 2 : Inscription**
- [x] Ajouter astérisques `*` aux champs obligatoires (Visuellement clair) ✅ Déjà implémenté avec classe `.required` et légende
- [x] Améliorer les messages d'erreur Devise (Traduire/customiser) ✅ `devise.fr.yml` créé avec toutes les traductions
- [x] Message de bienvenue après inscription (Toast "Bienvenue [Prénom] ! Découvrez les événements") ✅ Implémenté dans `RegistrationsController`
- [x] Indicateur de force du mot de passe (Barre de progression visuelle) ✅ Ajouté au formulaire d'inscription (2025-11-24)

### **Parcours 3 : Découverte des Événements**
- [x] Ajouter badge "Nouveau" (Pour événements créés dans les 7 derniers jours) ✅ Implémenté
- [x] Améliorer troncature lieu (Augmenter à 50 caractères ou afficher sur 2 lignes) ✅ **TERMINÉ** (2025-01-30) - Troncature passée de 35 à 50 caractères
- [x] Ajouter compteur d'événements ("X événements à venir" visible en haut) ✅ Implémenté
- [x] Refactoriser highlighted_event : intégration dans la grille avec badge "Prochain" ✅ Implémenté (Badge "Prochain" aligné avec badge de date, grille Bootstrap fonctionnelle)
- [x] Lien "Voir tous les événements passés" (Si >6 événements passés) ✅ **TERMINÉ** (2025-01-30) - Lien conditionnel affiché si >6 événements, badge avec compteur total, bouton "Voir moins" pour réduire

### **Parcours 4 : Inscription à un Événement**
- [x] Ajouter résumé dans modal (Afficher date, heure, lieu avant confirmation) ✅ **TERMINÉ** (2025-01-30) - Résumé avec date, heure, lieu, durée, distance + bouton "Ajouter au calendrier"
- [x] Message de succès personnalisé ("Inscription confirmée ! À bientôt le [date] à [heure]") ✅ **TERMINÉ** (2025-01-30) - Message personnalisé avec date et heure de l'événement
- [x] Indicateur de chargement (Spinner/loader pendant soumission) ✅ **TERMINÉ** (2025-01-30) - Spinner Bootstrap avec texte "Inscription en cours..." pendant la soumission
- [x] Alerte "Presque complet" (Si ≤5 places, alerte dans la modal) ✅ **PARTIELLEMENT FAIT** - Badge visible sur card mais pas dans modal

### **Parcours 5 : Gestion de Mes Inscriptions**
- [x] Séparer événements à venir et passés (Section "À venir" et "Passés" avec compteurs) ✅ **TERMINÉ** (2025-01-30) - Sections séparées avec compteurs et badges distinctifs
- [x] Badge "Passé" (Badge distinctif pour les événements passés) ✅ **TERMINÉ** (2025-01-30) - Badge `badge-liquid-secondary` appliqué via paramètre `past: true`
- [x] Indicateur rappel dans la liste (Badge "Rappel activé" / "Rappel désactivé" sur chaque card) ✅ **TERMINÉ** (2025-01-30) - Badge affiché sur chaque card dans "Mes sorties" avec icône et couleur distincte (vert activé, gris désactivé)
- [x] Compteur d'inscriptions ("X sorties à venir" visible en haut) ✅ **TERMINÉ** (2025-01-30) - Compteurs "X sorties" affichés dans chaque section (À venir / Passés)

### **Parcours 6 : Création d'un Événement**
- [x] Sauvegarde automatique (localStorage) (Sauvegarder les champs pendant la saisie) ✅ **TERMINÉ** (2025-01-30) - Sauvegarde automatique conforme RGPD avec cookies (si consentement) ou localStorage, durée 7 jours, restauration et nettoyage automatiques
- [ ] Validation en temps réel (Vérifier les champs au blur)
- [ ] Indicateur de progression (Barre "Étape 1/1" ou compteur de champs remplis)
- [ ] Message de confirmation avant soumission ("Votre événement sera en attente de validation. Continuer ?")

### **Parcours 7 : Achat en Boutique**
- [x] Filtres par catégories (Sidebar ou tabs avec catégories) ✅ **TERMINÉ** (2025-01-30) - Sidebar avec filtres par catégorie, compteurs, filtre actif mis en évidence
- [ ] Barre de recherche (Recherche par nom produit - AJAX) ❌ **DÉPRIORISÉ** - Peu de produits (~6-7)
- [x] Améliorer image par défaut (Image placeholder plus attrayante si pas d'image_url) ✅ **DÉJÀ GÉRÉ** - Image obligatoire (validation `presence: true`)
- [ ] Zoom sur image produit (Lightbox pour agrandir l'image au clic) ⚠️ **PRIORITÉ MOYENNE** - Pas de lightbox actuellement
- [x] Message "Article ajouté" plus visible (Toast/notification persistante) ✅ **TERMINÉ** (2025-01-20)
- [x] **UX Liste commandes : Bouton "Payer" visible** ✅ **TERMINÉ** (2025-01-26)
  - Bouton "Payer" directement dans la liste pour commandes `pending`
  - Suppression bouton "Annuler" de la liste (réduit annulations accidentelles)
- [x] **UX Page détail : Optimisation actions** ✅ **TERMINÉ** (2025-01-26)
  - Alerte redondante supprimée
  - Bouton "Finaliser le paiement" comme CTA principal
  - "Annuler" dans dropdown (friction élevée)
- [x] **Intégration don dans commande** ✅ **TERMINÉ** - Don stocké dans `Order.donation_cents` et intégré au checkout HelloAsso

### **Parcours 8 : Administration**
- [x] Dashboard avec statistiques basiques (Cards avec compteurs : Événements à valider, Utilisateurs, Commandes, Revenus)
- [x] Actions rapides dans liste Events (Boutons "Refuser", "Voir", "Accepter" directement dans Actions)
- [x] Vue "À valider" améliorée (Panel dédié sur dashboard avec liste - actions rapides retirées à la demande)
- [x] Exports CSV basiques (Bouton "Exporter CSV" sur chaque resource - ActiveAdmin natif) ✅ **NATIF ACTIVEADMIN** - CSV configuré dans `config/initializers/active_admin.rb`, bouton disponible par défaut

### **Parcours 9 : Navigation via Footer** ⚠️ NOUVEAU
- [x] ⚠️ **URGENT : Masquer temporairement sections non implémentées** ✅ **TERMINÉ** - Sections masquées avec `if false` (Équipe, Carrières, Blog, Catégories, Villes)
- [x] ⚠️ **URGENT : Corriger liens existants** ✅ **TERMINÉ** - Tous les liens principaux fonctionnent (Contact, CGU, Confidentialité, Mentions Légales, CGV)
- [x] Désactiver newsletter temporairement (Masquer ou message "Bientôt disponible") ✅ **TERMINÉ** - Newsletter masquée avec `if false` (ligne 198)

---

## 🟡 AMÉLIORATIONS IMPORTANTES (Impact Haut, Effort Moyen)

### **Parcours 1 : Découverte de l'Association**
- [x] Créer les pages manquantes du footer (Pages statiques : FAQ, Contact, CGU, Confidentialité, Qui sommes-nous, Équipe) ✅ **PARTIELLEMENT FAIT** - Contact, CGU, Confidentialité, Mentions Légales, CGV existent. FAQ, Équipe à créer
- [ ] Implémenter newsletter fonctionnelle (Formulaire footer + backend avec service email) ⚠️ **À FAIRE** - Newsletter masquée actuellement
- [x] Lier réseaux sociaux (Ajouter vraies URLs dans variables d'environnement) ✅ **TERMINÉ** - Facebook et Instagram avec vraies URLs
- [ ] Section "Pourquoi nous rejoindre ?" (3-4 cards avec valeurs + icônes)
- [ ] Section "Derniers événements" (Carrousel ou grille avec 3-4 derniers événements passés)
- [ ] Section "Tarifs d'adhésion" (Tableau simple avec 3 tarifs + CTA)
- [ ] Améliorer le message vide (Si aucun événement, proposer actions selon rôle)

### **Parcours 2 : Inscription**
- [ ] Validation email en temps réel (Vérifier si email existe déjà via AJAX) ⚠️ **À FAIRE** - Pas de validation AJAX
- [ ] Page de bienvenue après inscription (Redirection vers `/welcome` avec guide "Prochaines étapes") ⚠️ **À FAIRE** - Message toast seulement
- [x] Activation validation email (Devise :confirmable - Envoyer email de confirmation) ✅ **TERMINÉ** - `:confirmable` activé dans User model, email envoyé automatiquement
- [ ] Améliorer la validation téléphone (Format français avec masque de saisie) ⚠️ **À FAIRE** - Pas de masque, juste placeholder
- [ ] Indicateur de progression du formulaire (Barre "Étape 1/1" pour préparer futures étapes) ⚠️ **À FAIRE** - Pas d'indicateur

### **Parcours 3 : Découverte des Événements**
- [ ] Barre de recherche (Recherche par titre, description, lieu - AJAX) ⚠️ **À FAIRE** - Pas de recherche
- [ ] Filtres basiques (Filtres par date, route, niveau) ⚠️ **À FAIRE** - Pas de filtres
- [ ] Pagination (Pagination avec Kaminari/Pagy - 10-15 événements par page) ⚠️ **À FAIRE** - Pas de pagination (limite 6 pour passés)
- [ ] Tri personnalisé (Dropdown "Trier par" : Date, Popularité, Distance, Nouveautés) ⚠️ **À FAIRE** - Tri fixe par date seulement
- [ ] Vue calendrier (Toggle vue liste/calendrier avec FullCalendar - vue mensuelle) ⚠️ **À FAIRE** - Vue liste uniquement
- [ ] Filtres avancés (Filtres combinés avec tags actifs visibles) ⚠️ **À FAIRE** - Pas de filtres avancés

### **Parcours 4 : Inscription à un Événement**
- [ ] Prévisualisation email (Aperçu de l'email de confirmation dans la modal) ⚠️ **À FAIRE** - Pas de prévisualisation
- [ ] Conditions d'annulation claires (Mentionner "Vous pouvez annuler jusqu'à [X heures] avant") ⚠️ **À FAIRE** - Message générique seulement
- [ ] Confirmation en deux étapes (Étape 1 modal → Étape 2 page de confirmation) ⚠️ **À FAIRE** - Modal directe seulement
- [ ] Rappel des informations GPS (Si coordonnées GPS, rappeler dans la modal avec liens) ⚠️ **À FAIRE** - Pas de rappel GPS dans modal
- [ ] Notification push (optionnel) (Demander permission pour notifications push) ⚠️ **À FAIRE** - Pas de notifications push

### **Parcours 5 : Gestion de Mes Inscriptions**
- [ ] Filtres basiques (Filtres par date, statut rappel) ⚠️ **À FAIRE** - Pas de filtres
- [ ] Pagination (Pagination avec Kaminari/Pagy - 10-15 événements par page) ⚠️ **À FAIRE** - Pas de pagination
- [ ] Vue calendrier (Toggle vue liste/calendrier avec FullCalendar) ⚠️ **À FAIRE** - Vue liste uniquement
- [ ] Actions en masse (Checkbox pour sélectionner plusieurs événements et désinscription en masse) ⚠️ **À FAIRE** - Pas d'actions en masse
- [x] Export calendrier global (Export iCal de toutes ses inscriptions en une fois) ✅ **PARTIELLEMENT FAIT** - Export iCal par événement disponible (`ical_event_path`), pas d'export global
- [ ] Tri personnalisé (Dropdown "Trier par" : Date, Nom, Distance) ⚠️ **À FAIRE** - Pas de tri

### **Parcours 6 : Création d'un Événement**
- [ ] Formulaire en plusieurs étapes (Étape 1 Infos de base → Étape 2 Détails → Étape 3 Options) ⚠️ **À FAIRE** - Formulaire unique
- [ ] Prévisualisation événement (Bouton "Aperçu" qui montre la card événement) ⚠️ **À FAIRE** - Pas de prévisualisation
- [ ] Création route depuis formulaire (Modal "Créer un nouveau parcours" directement) ⚠️ **À FAIRE** - Sélection route existante seulement
- [x] Intégration Google Maps (Carte interactive pour sélectionner coordonnées GPS) ✅ **PARTIELLEMENT FAIT** - Coordonnées GPS saisissables manuellement, lien vers Google Maps pour trouver coordonnées, mais pas de carte interactive intégrée
- [ ] Duplication d'événement (Bouton "Dupliquer" sur événement existant) ⚠️ **À FAIRE** - Pas de duplication
- [ ] Templates d'événements (Templates pré-remplis : "Rando vendredi soir", etc.) ⚠️ **À FAIRE** - Pas de templates
- [ ] Validation côté client (Validation HTML5 + JavaScript avant soumission) ⚠️ **À FAIRE** - Validation HTML5 basique seulement

### **Parcours 7 : Achat en Boutique**
- [ ] Tri des produits (Dropdown "Trier par" : Prix, Nom, Popularité) ⚠️ **À FAIRE** - Pas de tri actuellement
- [ ] Galerie d'images (Carrousel avec plusieurs images par produit) ⚠️ **À FAIRE** - Une seule image par produit actuellement
- [ ] Panier persistant pour utilisateurs connectés (Sauvegarder panier en DB, fusionner avec session) ⚠️ **À FAIRE** - Panier en session uniquement
- [ ] Sauvegarde panier avant déconnexion (Sauvegarder automatiquement le panier en DB) ⚠️ **À FAIRE** - Pas de sauvegarde automatique
- [ ] Récapitulatif avant paiement (Page intermédiaire "Récapitulatif" avec adresse de livraison) ⚠️ **À FAIRE** - Pas de page récapitulatif
- [x] Intégration don dans commande (Le don doit être enregistré dans la commande) ✅ **TERMINÉ** - Don stocké dans `Order.donation_cents` et intégré au checkout HelloAsso
- [ ] Suggestions produits ("Produits similaires" ou "Autres clients ont aussi acheté") ⚠️ **À FAIRE** - Pas de suggestions

### **Parcours 8 : Administration**
- [ ] Bulk actions (Sélectionner plusieurs événements → "Publier en masse", "Refuser en masse") ⚠️ **À FAIRE** - Pas d'actions en masse
- [x] Dashboard complet (Graphiques : événements par mois, inscriptions, revenus) ✅ **PARTIELLEMENT FAIT** - Statistiques basiques (compteurs) présentes, mais pas de graphiques
- [ ] Recherche globale (Barre de recherche qui cherche dans Events, Users, Orders) ⚠️ **À FAIRE** - Pas de recherche globale
- [ ] Regroupement menu (Menu groupé : "Événements" → Events, Routes, Attendances) ⚠️ **À FAIRE** - Menu plat actuellement
- [ ] Exports avancés (Exports CSV personnalisés avec colonnes choisies, exports PDF) ⚠️ **À FAIRE** - CSV natif seulement, pas de personnalisation ni PDF
- [ ] Filtres sauvegardés (Permettre de sauvegarder des filtres fréquents) ⚠️ **À FAIRE** - Pas de sauvegarde de filtres

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
- [ ] Carte interactive (Carte avec points des événements, filtrage par zone géographique) ⚠️ **À FAIRE** - Pas de carte interactive
- [ ] Suggestions personnalisées ("Événements qui pourraient vous intéresser" basé sur historique) ⚠️ **À FAIRE** - Pas de suggestions
- [ ] Filtres sauvegardés (Permettre de sauvegarder des filtres favoris) ⚠️ **À FAIRE** - Pas de filtres sauvegardés
- [x] Export calendrier global (Export iCal de tous les événements à venir) ✅ **PARTIELLEMENT FAIT** - Export iCal par événement disponible, pas d'export global de tous les événements

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
- [ ] Éditeur WYSIWYG pour description (Éditeur riche : Trix, TinyMCE) ⚠️ **À FAIRE** - Textarea simple seulement
- [x] Upload image direct (Upload d'image depuis l'ordinateur - Active Storage) ✅ **TERMINÉ** - `has_one_attached :cover_image` avec variants optimisés (hero, card, thumb)
- [ ] Planification récurrente (Créer plusieurs événements à la fois : tous les vendredis du mois) ⚠️ **À FAIRE** - Pas de planification récurrente
- [ ] Aide contextuelle avancée (Tooltips avec exemples concrets pour chaque champ) ⚠️ **À FAIRE** - Aide basique seulement (form-text)
- [ ] Historique de modifications (Voir l'historique des modifications d'un événement) ⚠️ **À FAIRE** - Pas d'historique

### **Parcours 7 : Achat en Boutique**
- [ ] Comparaison de produits (Permettre de comparer 2-3 produits côte à côte)
- [ ] Liste de souhaits (Wishlist) (Permettre d'ajouter des produits à une liste de souhaits)
- [ ] Avis clients (Système d'avis et notes sur les produits)
- [ ] Historique de navigation ("Produits récemment consultés")
- [ ] Notifications stock ("Me prévenir quand ce produit sera de nouveau en stock")
- [ ] Codes promo (Système de codes promotionnels)

### **Parcours 8 : Administration**
- [ ] Tableau de bord personnalisable (Admin peut choisir quels widgets afficher) ⚠️ **À FAIRE** - Dashboard fixe
- [ ] Notifications admin (Alertes pour événements à valider, commandes en attente) ⚠️ **À FAIRE** - Pas de notifications (compteurs visibles seulement)
- [ ] Workflow de modération (Interface dédiée pour modérer avec commentaires) ⚠️ **À FAIRE** - Modération via liste Events seulement
- [ ] Rapports automatiques (Génération automatique de rapports par email) ⚠️ **À FAIRE** - Pas de rapports automatiques
- [x] Audit trail visuel (Voir l'historique des modifications avec qui/quand) ✅ **PARTIELLEMENT FAIT** - Modèle `AuditLog` existe avec `actor_user`, mais pas d'interface visuelle dans ActiveAdmin

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

1. **⚠️ URGENT : Corriger liens morts du footer** (Parcours 9) ✅ **TERMINÉ**
   - Impact : Très haut (frustration majeure utilisateurs)
   - Effort : Très faible (masquer sections ou corriger liens existants)
   - **Status** : Tous les liens principaux fonctionnent (Contact, CGU, Confidentialité, Mentions Légales, CGV). Sections non implémentées masquées (Équipe, Carrières, Blog, Catégories, Villes). Newsletter masquée.

2. **Dashboard admin avec statistiques** (Parcours 8) ✅ **TERMINÉ**
   - Impact : Très haut (admin voit l'état de l'app en un coup d'œil)
   - Effort : Faible (cards simples avec compteurs)
   - **Status** : Dashboard complet avec stats Événements, Utilisateurs, Commandes, Revenus, Boutique

3. **Section "À propos" sur homepage** (Parcours 1) ✅ **TERMINÉ** (2025-01-30)
   - Impact : Haut (visiteurs comprennent mieux l'association)
   - Effort : Faible (2-3 lignes + lien)
   - **Status** : Section ajoutée juste après le hero banner avec description concise et lien vers page complète

4. **Astérisques champs obligatoires** (Parcours 2) ✅ **TERMINÉ**
   - Impact : Haut (clarté immédiate pour utilisateurs)
   - Effort : Très faible (ajout `*` dans labels)
   - **Status** : Classe `.required` sur labels + légende "Champs obligatoires" avec `*`

5. **Séparer événements à venir/passés** (Parcours 5) ✅ **TERMINÉ** (2025-01-30)
   - Impact : Haut (organisation claire de "Mes sorties")
   - Effort : Faible (2 sections avec filtres)
   - **Status** : Sections "À venir" et "Passés" séparées avec compteurs et badges distinctifs

6. **Filtres par catégories boutique** (Parcours 7) ✅ **TERMINÉ** (2025-01-30)
   - Impact : Haut (navigation facilitée dans le catalogue)
   - Effort : Faible (sidebar ou tabs avec catégories existantes)
   - **Status** : Sidebar avec filtres par catégorie, compteurs de produits, filtre actif mis en évidence, bouton "Effacer le filtre", gestion des catégories vides

7. **Résumé dans modal inscription** (Parcours 4) ✅ **TERMINÉ** (2025-01-30)
   - Impact : Haut (rassure l'utilisateur avant confirmation)
   - Effort : Faible (afficher date/heure/lieu dans modal)
   - **Status** : Résumé complet avec date, heure, lieu, durée, distance + bouton "Ajouter au calendrier" (iCal)

8. **Message de bienvenue après inscription** (Parcours 2) ✅ **TERMINÉ** (2025-01-30)
   - Impact : Haut (première impression positive)
   - Effort : Faible (toast/alerte avec message personnalisé)
   - **Status** : Message personnalisé avec prénom, type 'success', et positionnement des toasts sous la navbar

9. **Badge "Nouveau" sur événements** (Parcours 3) ✅ **TERMINÉ**
   - Impact : Moyen-Haut (mise en avant des nouveautés)
   - Effort : Très faible (badge conditionnel)
   - **Status** : Méthode `recent?` (7 derniers jours) + badge `badge-liquid-success` dans `_event_card.html.erb`

10. **Actions rapides dans liste Events admin** (Parcours 8) ✅ **TERMINÉ**
   - Impact : Très haut (gain de temps pour modération)
   - Effort : Faible (boutons "Publier"/"Refuser" dans colonne Actions)
   - **Status** : Boutons "Refuser", "Voir", "Accepter" dans colonne Actions de la liste Events

11. **Sauvegarde automatique formulaire événement** (Parcours 6) ✅ **TERMINÉ** (2025-01-30)
    - Impact : Haut (évite perte de données)
    - Effort : Faible (localStorage JavaScript)
    - **Status** : Sauvegarde automatique conforme RGPD avec cookies (si consentement) ou localStorage, durée limitée 7 jours, restauration automatique, nettoyage après soumission

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
- Séparer événements à venir/passés ✅
- Filtres catégories boutique ✅
- Résumé dans modal inscription ✅
- Actions rapides admin ✅
- Sauvegarde automatique formulaire ✅

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
- **Méthodologie Shape Up** : [`../02-shape-up/shape-up-methodology.md`](../02-shape-up/shape-up-methodology.md)

---

**Document créé le** : 2025-11-14  
**Dernière mise à jour** : 2025-01-30  
**Version** : 1.9 (Quick Win #7 implémentée - Résumé modal + Ajout calendrier)

**Points déjà implémentés identifiés** :
- ✅ Validation email Devise (`:confirmable` activé)
- ✅ Export iCal par événement (liens `ical_event_path` disponibles)
- ✅ Upload image événement (Active Storage avec variants)
- ✅ Coordonnées GPS (saisie manuelle + lien Google Maps)
- ✅ Dashboard admin avec statistiques (compteurs, pas de graphiques)
- ✅ Audit trail (modèle `AuditLog` existe, interface à améliorer)

**Avancement actuel** :
- ✅ **23 Quick Wins terminés (56%)** : Dashboard admin, Actions rapides Events, Vue "À valider", **Liens footer (tous fonctionnels)** ✅, Astérisques champs obligatoires, Badge "Nouveau", Compteur événements, Bouton "Adhérer" plus clair, Refactorisation highlighted_event avec badge "Prochain", **Message "Article ajouté" plus visible** (2025-01-20), **UX Liste commandes : Bouton "Payer" visible** (2025-01-26), **UX Page détail : Optimisation actions** (2025-01-26), **Intégration don dans commande** ✅, **Exports CSV ActiveAdmin** ✅ (natif), **Newsletter masquée** ✅, **Réseaux sociaux liés** ✅, **Résumé dans modal inscription + Ajout calendrier** ✅ (2025-01-30), **Améliorer troncature lieu** ✅ (2025-01-30), **Séparer événements à venir/passés** ✅ (2025-01-30), **Badge "Passé"** ✅ (2025-01-30), **Compteur d'inscriptions** ✅ (2025-01-30), **Message de succès personnalisé** ✅ (2025-01-30), **Indicateur de chargement** ✅ (2025-01-30), **Section "À propos" homepage** ✅ (2025-01-30), **Message de bienvenue après inscription** ✅ (2025-01-30), **Sauvegarde automatique formulaire événement** ✅ (2025-01-30)
- 🟡 **2 partiellement faits** : Alerte "Presque complet" (badge sur card mais pas dans modal), Pages footer (FAQ et Équipe manquantes)
- ⏳ **16 Quick Wins en attente (44%)**

**Phases globales** :
- ✅ **Phase 0 (Accessibilité)** : 100% - Corrections critiques terminées
- ⏳ **Phase 1 (Quick Wins)** : 56% - 23/41 terminés, 2 partiellement faits
- ✅ **Phase 2 (HelloAsso)** : 90% - Checkout & polling fonctionnels
- ✅ **Phase 3 (Adhésions)** : 95% - Formulaire multi-étapes complet
- ✅ **Phase 4 (Événements)** : 95% - Fonctionnalités core complètes
- ✅ **Phase 5 (Lighthouse)** : 100% - Quick wins SEO/accessibilité terminés
- ⏳ **Phase 6 (Performance)** : 50% - Bullet configuré, audit à finaliser

