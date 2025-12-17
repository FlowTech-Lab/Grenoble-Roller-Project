# 🚀 Panel Admin - Guide de Démarrage

**Bienvenue !** Ce fichier est votre point d'entrée pour développer le nouveau panel admin.

**Approche** : Implémenter fonctionnalité par fonctionnalité, simple et efficace.

---

## 📋 Vue d'Ensemble

**Objectif** : Créer un panel admin moderne et maintenable, fonctionnalité par fonctionnalité.

**Stack** : Rails 8.1.1, Bootstrap 5.3.2, Stimulus, PostgreSQL 16, Pundit

**Principe** : Simple d'abord, améliorations ensuite.

---

## 🎯 Par Où Commencer ?

### 1️⃣ Base UX-UI : Layout, Sidebar, Dashboard

**Guide** : [ressources/decisions/BASE_UX_UI_PANEL.md](ressources/decisions/BASE_UX_UI_PANEL.md)

**Objectif** : Mettre en place la base du panel admin (layout, sidebar, routes, dashboard).

**Étapes** :
1. Créer layout admin avec sidebar
2. Configurer routes (`/admin-panel`)
3. Créer BaseController et DashboardController
4. Implémenter dashboard simple
5. Ajouter lien dans navbar

**Approche** : Classes Bootstrap de base uniquement pour l'instant.

---

## 📚 Références Essentielles

### Stack & Outils
- **Classes CSS** : [ressources/references/reference-css-classes.md](ressources/references/reference-css-classes.md)
- **Dark mode** : [ressources/references/reutilisation-dark-mode.md](ressources/references/reutilisation-dark-mode.md) (déjà implémenté)

### Décisions Techniques
- **Base UX-UI** : [ressources/decisions/BASE_UX_UI_PANEL.md](ressources/decisions/BASE_UX_UI_PANEL.md) ⭐ **COMMENCER ICI**
- **Dashboard** : [ressources/decisions/DASHBOARD.md](ressources/decisions/DASHBOARD.md)
- **Sidebar** : [ressources/decisions/sidebar_guide_bootstrap5.md](ressources/decisions/sidebar_guide_bootstrap5.md)
- **Validation** : [ressources/decisions/form-validation-guide.md](ressources/decisions/form-validation-guide.md)

### Documentation Complète
- **Index** : [ressources/RESSOURCES.md](ressources/RESSOURCES.md) - Toutes les ressources organisées

---

## ⚠️ Points d'Attention

### À Réutiliser
- ✅ **Dark mode** : Déjà implémenté, hérite automatiquement
- ✅ **Classes Liquid** : `card-liquid`, `btn-liquid-primary`, etc.
- ✅ **Bootstrap 5.3.2** : Toutes les classes standards

### À Ne Pas Utiliser
- ❌ **Tailwind CSS** → Bootstrap 5.3.2
- ❌ **View Components** → Partials Rails
- ❌ **Nouvelles dépendances inutiles** → Réutiliser au maximum

---

## 📝 Workflow Simple

1. **Choisir une fonctionnalité** à implémenter
2. **Consulter le guide** correspondant dans `ressources/decisions/`
3. **Vérifier les classes CSS** disponibles
4. **Implémenter** avec Bootstrap + Stimulus
5. **Tester** et passer à la fonctionnalité suivante

---

## 🔗 Liens Utiles

- [Bootstrap 5.3 Documentation](https://getbootstrap.com/docs/5.3/)
- [Bootstrap Icons](https://icons.getbootstrap.com/)
- [Stimulus Handbook](https://stimulus.hotwired.dev/)

---

## 📚 Résumé du Contenu

Ce fichier contient :
- **Vue d'ensemble** : Objectif et approche du panel admin
- **Point de départ** : Base UX-UI (layout, sidebar, dashboard)
- **Références essentielles** : Liens vers les guides et documentation
- **Points d'attention** : Ce qu'il faut réutiliser/éviter
- **Workflow** : Processus simple pour implémenter une fonctionnalité

**Guides disponibles** :
- [BASE_UX_UI_PANEL.md](ressources/decisions/BASE_UX_UI_PANEL.md) - Base UX-UI complète
- [ESSENTIEL.md](ESSENTIEL.md) - Liste des fichiers essentiels

---

**Dernière mise à jour** : 2025-01-27  
**Version** : 3.0 (Simplifié - Approche fonctionnalité par fonctionnalité)
