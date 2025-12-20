# 📚 Documentation - Développement en Cours

**Section** : Documentation des fonctionnalités en cours de développement, plans d'implémentation, audits et améliorations à venir.

---

## 📋 Vue d'Ensemble

Cette section contient toute la documentation liée aux **fonctionnalités en développement**, aux **plans d'implémentation**, aux **audits nécessitant des actions**, et aux **améliorations planifiées**.

**Principe** : Les fichiers sont organisés par **domaine fonctionnel** pour faciliter la navigation et la maintenance.

---

## 📁 Structure par Domaine

### 📧 Mailing & Notifications
**Dossier** : Fichier principal dans `development/`

Documentation complète du système de mailing automatique :
- Mailers et leurs méthodes
- Jobs automatiques (rappels, renouvellements)
- Préférences utilisateur
- Configuration SMTP
- Tests et sécurité

**Fichiers** :
- `mailing-system-complete.md` - Documentation complète du système de mailing (18 emails, 4 jobs, configuration, tests)

---

### 🎨 UX & Améliorations
**Dossier** : [`ux-improvements/`](ux-improvements/)

Backlog d'améliorations UX et plans d'action :
- Analyses de parcours utilisateur
- Quick wins identifiés
- Améliorations prioritaires

**Fichiers** :
- `ux-improvements-backlog.md` - Backlog complet (119 améliorations identifiées)
- `todo-restant.md` - Récapitulatif des tâches restantes
- `quick-wins-helloasso.md` - Quick wins et intégration HelloAsso

---

### ⚙️ Admin Panel
**Dossier** : [`admin-panel/`](admin-panel/)

Documentation stratégique et plans d'amélioration pour l'admin panel :
- Analyses stratégiques
- Plans d'implémentation

**Fichiers** :
- `admin-panel-strategic-analysis.md` - Analyse stratégique complète

---

### ♿ Accessibilité
**Dossier** : [`accessibility/`](accessibility/)

Audits et plans d'action pour l'accessibilité :
- Audits d'accessibilité
- Plans d'action Lighthouse
- Guides de test

**Fichiers** :
- `accessibility-audit.md` - Audit complet d'accessibilité
- `lighthouse-action-plan.md` - Plan d'action Lighthouse
- `a11y-testing.md` - Guide de test d'accessibilité

---

### 🚀 Phase 2
**Dossier** : [`phase2/`](phase2/)

Documentation des fonctionnalités Phase 2 (non encore implémentées) :
- Plans de développement
- Migrations et modèles prévus

**Fichiers** :
- `cycle-01-phase-2-plan.md` - Plan Phase 2 (Events & Admin)
- `phase2-migrations-models.md` - Migrations et modèles Phase 2

---

### 🧪 Testing
**Dossier** : [`testing/`](testing/)

Documentation des tests en cours ou à améliorer :
- Roadmaps de tests
- Todolists de corrections

**Fichiers** :
- `ROADMAP.md` - Roadmap des tests RSpec
- `TODOLIST.md` - Todolist des corrections de tests

---

### 🏗️ Infrastructure
**Dossier** : [`infrastructure/`](infrastructure/)

Documentation infrastructure en développement (pour l'instant vide, prêt pour futurs fichiers).

---

## 🔄 Cycle de Vie des Documents

### Quand un document entre dans `development/` ?
- ✅ Fonctionnalité **en cours de développement** (WIP, EN COURS)
- ✅ Plan d'implémentation **non terminé**
- ✅ Audit avec **actions à réaliser**
- ✅ Backlog d'améliorations **non implémentées**
- ✅ Spécifications **non finalisées**

### Quand un document sort de `development/` ?
- ✅ Fonctionnalité **terminée et validée** → Déplacer vers section appropriée
- ✅ Plan **complètement implémenté** → Archiver ou déplacer vers section complétée
- ✅ Audit **toutes actions réalisées** → Déplacer vers section appropriée

---

## 📝 Conventions

### Nommage
- **kebab-case** uniquement
- **Descriptif** : Utiliser des noms descriptifs (ex: `ux-improvements-backlog.md` pas `backlog.md`)

### Frontmatter
Tous les documents doivent avoir un frontmatter YAML :
```yaml
---
title: "Document Title"
status: "wip|planned|in-review|blocked"
version: "1.0"
created: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
authors: ["Author Name"]
tags: ["tag1", "tag2"]
---
```

### Statuts possibles
- `wip` : En cours de développement actif
- `planned` : Planifié mais pas encore commencé
- `in-review` : En cours de revue/validation
- `blocked` : Bloqué (dépendance externe, décision en attente)
- `deprecated` : Déprécié, ne plus utiliser

---

## 🔗 Liens Utils

- **Documentation principale** : [`../README.md`](../README.md)
- **Shape Up** : [`../02-shape-up/`](../02-shape-up/)
- **Architecture** : [`../03-architecture/`](../03-architecture/)
- **Product** : [`../09-product/`](../09-product/)

---

**Dernière mise à jour** : 2025-12-20
