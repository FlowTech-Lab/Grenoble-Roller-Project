# 📋 Plan de Consolidation Documentation

**Date** : 2025-11-14  
**Objectif** : Consolider la documentation dispersée dans `/docs/run-plan/` et `/docs/09-product/` selon la structure numérotée existante

---

## 🔍 État Actuel

### Structure existante (bien organisée)
```
/docs/
├── 00-overview/
├── 01-ways-of-working/
├── 02-shape-up/          ← Vide (juste dossiers betting, building, cooldown, shaping)
├── 03-architecture/
├── 04-rails/
├── 05-testing/
├── 06-infrastructure/
├── 07-ops/
├── 08-security-privacy/
├── 09-product/          ← Analyses UX récentes (user-journeys, recap-improvements)
├── 10-decisions-and-changelog/
└── 11-templates/
```

### Documentation dispersée (à consolider)
```
/docs/run-plan/
├── FIL_CONDUCTEUR_PROJET.md      (747 lignes - Planning général)
├── GUIDE_SHAPE_UP.md             (394 lignes - Méthodologie Shape Up)
├── GUIDE_IMPLEMENTATION.md      (708 lignes - Guide technique)
├── PLAN_PHASE2.md                (713 lignes - Planning Phase 2)
└── Watchdog/                     (Déploiement)
```

---

## 🎯 Plan de Consolidation

### **Étape 1 : Créer `/docs/02-shape-up/README.md`**
**Objectif** : Point d'entrée pour toute la méthodologie Shape Up

**Contenu** :
- Vue d'ensemble de la méthodologie Shape Up
- Références vers les cycles en cours
- Liens vers les guides détaillés
- Structure des dossiers (shaping, betting, building, cooldown)

---

### **Étape 2 : Migrer `/docs/run-plan/` vers `/docs/02-shape-up/`**

#### 2.1 Méthodologie Shape Up
```
/docs/run-plan/GUIDE_SHAPE_UP.md
  → /docs/02-shape-up/methodology.md
```

#### 2.2 Cycles et Planning
```
/docs/run-plan/FIL_CONDUCTEUR_PROJET.md
  → /docs/02-shape-up/building/current-cycle.md
  (ou cycle-XX.md selon le cycle actuel)

/docs/run-plan/PLAN_PHASE2.md
  → /docs/02-shape-up/building/phase-2-plan.md
```

#### 2.3 Guide Technique
```
/docs/run-plan/GUIDE_IMPLEMENTATION.md
  → /docs/02-shape-up/implementation-guide.md
  (ou /docs/04-rails/implementation-guide.md si plus technique)
```

#### 2.4 Watchdog (Déploiement)
```
/docs/run-plan/Watchdog/
  → /docs/07-ops/runbooks/watchdog/
  (déjà dans la bonne catégorie Ops)
```

---

### **Étape 3 : Organiser `/docs/09-product/`**

**Déjà bien placé** : `/docs/09-product/` est dans la bonne structure.

**Améliorations** :
- Créer `/docs/09-product/README.md` avec index
- Organiser par type : personas, journeys, improvements, roadmap

**Structure proposée** :
```
/docs/09-product/
├── README.md                          (Index + vue d'ensemble)
├── personas.md                        (Personas identifiés)
├── user-journeys-and-improvements.md  (Analyse détaillée)
├── recap-improvements.md              (Synthèse + plan d'action)
└── roadmap.md                         (Roadmap consolidée depuis recap)
```

---

### **Étape 4 : Mettre à jour les références**

**Fichiers à mettre à jour** :
- `/docs/README.md` : Ajouter références vers `/docs/02-shape-up/`
- `/docs/02-shape-up/README.md` : Références croisées
- `/docs/09-product/README.md` : Références croisées
- Tous les fichiers migrés : Mettre à jour les liens internes

---

## 📊 Structure Finale Proposée

```
/docs/
├── 00-overview/
├── 01-ways-of-working/
├── 02-shape-up/
│   ├── README.md                      ← NOUVEAU (index Shape Up)
│   ├── methodology.md                 ← Migré de GUIDE_SHAPE_UP.md
│   ├── implementation-guide.md        ← Migré de GUIDE_IMPLEMENTATION.md
│   ├── shaping/
│   │   └── (cycles shaping)
│   ├── betting/
│   │   └── (betting table)
│   ├── building/
│   │   ├── current-cycle.md          ← Migré de FIL_CONDUCTEUR_PROJET.md
│   │   ├── phase-2-plan.md           ← Migré de PLAN_PHASE2.md
│   │   └── cycle-XX-build-log.md      (logs de build)
│   └── cooldown/
│       └── (cooldown logs)
├── 03-architecture/
├── 04-rails/
├── 05-testing/
├── 06-infrastructure/
├── 07-ops/
│   └── runbooks/
│       └── watchdog/                  ← Migré de /docs/run-plan/Watchdog/
├── 08-security-privacy/
├── 09-product/
│   ├── README.md                      ← NOUVEAU (index product)
│   ├── personas.md                    (extrait de user-journeys)
│   ├── user-journeys-and-improvements.md
│   ├── recap-improvements.md
│   └── roadmap.md                    (extrait de recap-improvements)
├── 10-decisions-and-changelog/
└── 11-templates/
```

---

## ✅ Checklist de Consolidation

### Phase 1 : Préparation
- [ ] Créer `/docs/02-shape-up/README.md`
- [ ] Créer `/docs/09-product/README.md`
- [ ] Analyser toutes les références croisées dans les fichiers

### Phase 2 : Migration
- [ ] Migrer `GUIDE_SHAPE_UP.md` → `02-shape-up/methodology.md`
- [ ] Migrer `FIL_CONDUCTEUR_PROJET.md` → `02-shape-up/building/current-cycle.md`
- [ ] Migrer `PLAN_PHASE2.md` → `02-shape-up/building/phase-2-plan.md`
- [ ] Migrer `GUIDE_IMPLEMENTATION.md` → `02-shape-up/implementation-guide.md`
- [ ] Migrer `Watchdog/` → `07-ops/runbooks/watchdog/`

### Phase 3 : Mise à jour
- [ ] Mettre à jour tous les liens internes dans les fichiers migrés
- [ ] Mettre à jour `/docs/README.md` avec nouvelles références
- [ ] Vérifier que tous les liens fonctionnent

### Phase 4 : Nettoyage
- [ ] Supprimer `/docs/run-plan/` après vérification
- [ ] Commit avec message clair : "docs: Consolidation documentation Shape Up et Product"

---

## 🎯 Avantages de cette Consolidation

1. **Structure cohérente** : Tout suit la numérotation 00-11
2. **Navigation claire** : README.md dans chaque section principale
3. **Pas de duplication** : Un seul endroit pour chaque type de doc
4. **Shape Up centralisé** : Toute la méthodologie dans `/docs/02-shape-up/`
5. **Product organisé** : Analyses UX dans `/docs/09-product/` avec index

---

## ⚠️ Points d'Attention

1. **Références croisées** : Vérifier tous les liens après migration
2. **Historique Git** : Utiliser `git mv` pour préserver l'historique
3. **Tests** : Vérifier que tous les liens fonctionnent après migration
4. **Communication** : Informer l'équipe du changement de structure

---

**Prochaine étape** : Valider ce plan puis exécuter la consolidation.

