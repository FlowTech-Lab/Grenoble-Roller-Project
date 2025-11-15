# 📋 Plan de Professionnalisation Documentation

**Date** : 2025-11-14  
**Objectif** : Rendre la documentation conforme aux standards 2025 et méthodes agiles modernes

---

## 🎯 Standards 2025 à Appliquer

### 1. **Nommage des Fichiers**
- ✅ **kebab-case** uniquement (pas de MAJUSCULES, pas de underscores)
- ✅ **Descriptif et clair** : `cycle-01-building-log.md` au lieu de `current-cycle.md`
- ✅ **Anglais** pour les fichiers techniques, français pour le produit si nécessaire

### 2. **Structure des Documents**
- ✅ **Frontmatter YAML** avec métadonnées :
  ```yaml
  ---
  title: "Cycle 01 - Building Phase"
  status: "active"
  version: "1.0"
  created: "2025-11-14"
  updated: "2025-11-14"
  authors: ["FlowTech"]
  tags: ["shape-up", "building", "cycle-01"]
  ---
  ```

### 3. **Titres Professionnels**
- ❌ Éviter : `# 🎯 FIL CONDUCTEUR - Projet Site Web`
- ✅ Préférer : `# Cycle 01 - Building Phase` ou `# Project Roadmap`
- ✅ Emojis uniquement dans les listes/checklists, pas dans les titres principaux

### 4. **ADR (Architecture Decision Records)**
- ✅ Format standardisé pour toutes les décisions techniques
- ✅ Numérotation séquentielle : `ADR-001-use-rails-monolith.md`
- ✅ Template dans `11-templates/`

### 5. **Decision Records pour Product**
- ✅ Format similaire pour décisions produit/UX
- ✅ `DR-001-user-journey-prioritization.md`

---

## 📝 Renommages Proposés

### Shape Up
```
current-cycle.md          → cycle-01-building-log.md
phase-2-plan.md          → cycle-01-phase-2-plan.md
methodology.md           → shape-up-methodology.md
implementation-guide.md  → technical-implementation-guide.md
```

### Product
```
user-journeys-and-improvements.md → user-journeys-analysis.md
recap-improvements.md            → ux-improvements-backlog.md
```

---

## ✅ Checklist Professionnalisation

- [ ] Renommer tous les fichiers en kebab-case professionnel
- [ ] Ajouter frontmatter YAML à tous les documents
- [ ] Standardiser les titres (moins d'emojis)
- [ ] Créer templates ADR et Decision Records
- [ ] Mettre à jour tous les liens internes
- [ ] Mettre à jour README avec standards 2025
- [ ] Créer guide de contribution documentation

---

**Prochaine étape** : Exécuter la professionnalisation

