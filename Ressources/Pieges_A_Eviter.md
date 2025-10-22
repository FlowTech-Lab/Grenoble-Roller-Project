---
title: "Les 10 Pièges Mortels à Éviter"
type: pattern
status: active
area: ops
tags:
  - "#pattern"
  - "#anti-patterns"
  - "#best-practices"
  - "#methodology"
updated: 2025-10-21
created: 2025-10-21
related:
  - "Méthodologie"
  - "MOC-MCP-Qdrant-Best-Practices"
---

# ⚠️ Les 10 Pièges Mortels à Éviter

## 📋 Vue d'ensemble

Ce document recense les erreurs classiques qui font échouer les projets, basé sur des retours d'expérience de milliers de projets.

**Règle d'or** : Investissez 20% temps en réflexion, 60% développement, 20% tests/déploiement.

---

## 1️⃣ Over-Engineering : L'Ennemi Silencieux

### ❌ Symptômes
- Architecture 10x plus complexe que nécessaire
- Microservices pour 5 utilisateurs
- Kubernetes pour une app statique
- 5 layers d'abstraction pour 1 feature

### 🔴 Causes
- **Optimisation prématurée** : "Ça va scaler à 10M users" (sans utilisateurs actuels)
- **Abstractions excessives** : DRY poussé à l'extrême
- **Hype-driven development** : Vouloir utiliser la techno du moment
- **Manque de requirements clairs** : Coder pour hypothèses futures

### 💥 Conséquences
- **+200% temps de développement**
- Maintenance cauchemardesque
- Onboarding nouveaux devs impossible
- Bugs cachés dans la complexité
- Coûts d'infrastructure explosés

### ✅ Mitigation
- **Règle YAGNI** (You Ain't Gonna Need It) : Coder pour aujourd'hui, pas pour hypothèses
- Commencer **monolithe**, splitter si besoin réel prouvé
- **Benchmarker AVANT d'optimiser** (pas après)
- 80% du code doit être **simple**, 20% peut être complexe si justifié
- **3-rule** : Généraliser seulement après 3 cas d'usage identiques

### 📊 Exemple Concret
❌ **Mauvais** : Kubernetes + microservices + event sourcing pour MVP 10 users  
✅ **Bon** : Docker Compose + monolithe modulaire sur 1 serveur

> **Vous n'avez PAS besoin de Kubernetes** si <10 services et <1000 req/s.  
> Docker Compose sur Proxmox suffit largement !

---

## 2️⃣ Scope Creep : La Mort Lente

### ❌ Symptômes
- Features ajoutées en continu sans validation business
- "Et si on ajoutait aussi X, Y, Z ?"
- MVP jamais livré (toujours "presque prêt")

### 🔴 Causes
- Pas de définition claire du "Done"
- Stakeholders non alignés
- Peur de dire "Non" aux demandes
- Absence de priorisation stricte

### 💥 Conséquences
- MVP jamais livré
- Équipe épuisée, démotivée
- Budget explosé
- Opportunité de marché perdue

### ✅ Mitigation
- **Document "Out-of-Scope"** aussi important que "In-Scope"
- **Processus formel** de change requests (RFC obligatoire)
- **Priorisation ruthless** : 1 feature ajoutée = 1 feature retirée
- **Shape Up "appetite" fixe** : 6 semaines max, scope flexible
- Répéter comme un mantra : **"Pas dans le MVP"**

### 📊 Exemple Concret
❌ **Mauvais** : MVP avec auth + upload + analyse + viz + collab + export + API publique  
✅ **Bon** : MVP = auth + upload + analyse basique. Reste = Phase 2

---

## 3️⃣ Sous-estimation Chronique

### ❌ Symptômes
- "Ça prendra 2 jours" → 2 semaines réelles
- Deadlines systématiquement manquées
- Crunch permanent en fin de sprint

### 🔴 Causes
- **Oubli du temps** : testing, debugging, documentation
- **Optimisme bias** naturel humain
- Pas de données historiques (vélocité)
- Complexité cachée sous-estimée

### 💥 Conséquences
- Confiance équipe/stakeholders perdue
- Qualité sacrifiée pour tenir deadlines
- Burn-out équipe
- Technical debt accumulée

### ✅ Mitigation
- **Loi de Hofstadter** : Multiplier estimations par 2-3
- **Buffer 20-30%** pour imprévus systématiquement
- Estimer en **points** (complexité) pas en temps
- **Tracker vélocité réelle** pour calibrer futures estimations
- Inclure dans estimation : code + tests + review + doc + déploiement

### 📊 Formule Réaliste
```
Temps réel = (Estimation optimiste × 2,5) + buffer 30%
```

---

## 4️⃣ Ignorer la Gestion des Risques

### ❌ Symptômes
- "On verra bien, ça devrait aller"
- Découverte de bloqueurs en milieu de projet
- Pas de plan B pour points critiques

### 🔴 Exemples Classiques
- **Vendor lock-in** : API externe change pricing → projet bloqué
- **Dépendance technique** : Lib obsolète découverte tard
- **Régulation RGPD** ignorée jusqu'au dernier moment
- **Performance** : Découverte que DB ne scale pas en prod

### 💥 Conséquences
- Pivot forcé coûteux en milieu de projet
- Deadlines explosées
- Architecture à refaire
- Perte de données/argent

### ✅ Mitigation
- **Risk register** dès jour 1 (probabilité × impact)
- **Review hebdomadaire** des risques top 5
- **Plan B** pour chaque risque critique
- **FMEA** (Failure Mode Effect Analysis) : brainstorm "Qu'est-ce qui peut foirer ?"
- **Spikes techniques** pour valider hypothèses critiques

### 📊 Template Risk Register
| Risque | Prob. | Impact | Score | Mitigation | Plan B |
|--------|-------|--------|-------|------------|--------|
| API X devient payante | Moyen | Élevé | 6 | Monitorer pricing | Implémenter provider alternatif |
| PostgreSQL ne scale pas | Faible | Critique | 8 | Load testing early | Migration TimescaleDB |

---

## 5️⃣ Communication Défaillante

### ❌ Symptômes
- "Je croyais que tu faisais ça"
- "Personne m'a dit"
- Réinvention de la roue (2 devs codent la même chose)
- Décisions contradictoires

### 🔴 Causes
- Pas de canaux clairs
- Meetings inefficaces ou absents
- Documentation inexistante
- Pas de single source of truth

### 💥 Conséquences
- Travail dupliqué
- Conflits git constants
- Frustration équipe
- Deadlines manquées

### ✅ Mitigation
- **RACI matrix** : Responsible, Accountable, Consulted, Informed (si >3 personnes)
- **Daily async updates** (pas forcément sync meetings)
- **Single source of truth** documenté (Confluence, Notion, wiki)
- **Décisions importantes toujours écrites** (ADR !)
- Canaux Slack/Discord structurés : #dev, #product, #ops

### 📊 Exemple Communication Async
```
Daily update (Slack #dev, 5min/jour) :
- Hier : Fini API upload, PR #123
- Aujourd'hui : Tests intégration upload
- Bloqueurs : Besoin review @tech-lead sur architecture cache
```

---

## 6️⃣ Négliger les Dépendances

### ❌ Symptômes
- Feature A bloquée car attend Feature B non commencée
- Effet domino : 1 retard → tout retardé
- Découverte tardive d'incompatibilités

### 💥 Conséquences
- Deadlines explosées
- Équipe bloquée (idle time)
- Frustration majeure

### ✅ Mitigation
- **Dependency graph visuel** (Gantt chart, PERT)
- **Critical path analysis** : identifier chemin le plus long
- **Prioriser features** avec moins de dépendances (quick wins)
- **Vertical slicing** : features end-to-end indépendantes
- **Mocking/stubbing** pour développer en parallèle

---

## 7️⃣ Sauter les Tests

### ❌ Symptômes
- "On testera plus tard" (spoiler : jamais)
- Bugs en prod, hot fixes paniques
- Peur de refactorer (risque de casser)

### 💥 Conséquences
- **Coût fix bug prod = 10-100x** coût fix bug dev
- Perte confiance utilisateurs
- Technical debt exponentiel
- Vélocité en chute libre

### ✅ Mitigation
- **Tests AVANT code** (TDD light : au moins scénarios critiques)
- **CI pipeline** bloque merge si tests fail
- **Coverage minimum 70%** (pas 100%, pragmatique)
- **Tests E2E** pour user flows critiques uniquement (coût maintenance élevé)
- **Test pyramid** : Beaucoup unit, quelques intégration, peu E2E

### 📊 Test Pyramid
```
         /\
        /E2E\        ← Peu, lents, fragiles (5%)
       /──────\
      /Intégra.\     ← Moyennement (25%)
     /──────────\
    /  Unit Tests \  ← Beaucoup, rapides, fiables (70%)
   /──────────────\
```

---

## 8️⃣ Architecture Avant Besoins

### ❌ Symptômes
- "On va faire microservices avec event sourcing et CQRS"
- AVANT de valider le besoin utilisateur
- Impossible de pivoter avec architecture rigide

### 💥 Conséquences
- **70% startups échouent** par manque market fit, pas problème technique
- Coût développement 3-5x supérieur
- Pivot impossible sans tout refaire
- Over-engineering garantie

### ✅ Mitigation
- **Toujours** : Problème → MVP → Validation → Architecture robuste
- **"Make it work, make it right, make it fast"** (dans cet ordre)
- **Monolithe modulaire >> microservices** prématurés
- **3 mois max** pour avoir feedback utilisateurs réels
- Architecturer pour **changement**, pas pour "parfait"

### 📊 Ordre Correct
1. Valider problème existe (interviews, landing page)
2. MVP monolithe rapide (2-6 semaines)
3. Feedback utilisateurs réels
4. Itérer fonctionnel
5. Puis seulement : architecture scale si besoin prouvé

---

## 9️⃣ Documentation Vivante Négligée

### ❌ Symptômes
- "Le code documente le code" (spoiler : non)
- Décisions passées oubliées
- Bus factor = 1 (si dev clé part, projet meurt)

### 💥 Conséquences
- **Onboarding nouveau dev = 4 semaines** au lieu de 1
- Décisions passées oubliées → **erreurs répétées**
- Maintenance cauchemardesque
- Vélocité en chute si turnover

### ✅ Mitigation
- **ADR** pour décisions importantes (immuables)
- **README.md complet** avec quick start 5 min
- **Architecture diagrams à jour** (C4 model)
- **Runbooks** pour ops courantes (déploiement, rollback)
- **Documentation comme code** (versionnée Git, reviewed)

### 📊 Docs Essentiels (Minimum Vital)
- README.md : Setup en <30 min
- CONTRIBUTING.md : Process contribution
- /docs/adr/ : Décisions architecturales
- /docs/runbooks/ : Ops courantes
- API docs auto-générées (Swagger/OpenAPI)

---

## 🔟 Oublier le Post-MVP

### ❌ Symptômes
- Livrer MVP puis sprint suivant immédiatement
- Pas de temps pour feedback utilisateurs
- Technical debt jamais remboursée

### 💥 Conséquences
- Pas de temps pour **feedback utilisateurs**
- **Technical debt** accumulée jamais remboursée
- Équipe **burn-out**
- Code spaghetti ingérable

### ✅ Mitigation : Cooldown Shape Up
- **2 semaines après chaque cycle 6 semaines**
- Utilisées pour :
  - Bug fixes
  - Technical debt
  - R&D perso
  - Formation
- **Pas de pression delivery** → créativité & innovation
- Rétrospective équipe : qu'améliorer process ?

---

## 📊 Checklist Anti-Pièges

Avant de démarrer, vérifier :

### Stratégie
- [ ] Problème clairement défini (pas solution)
- [ ] MVP scopé strictement (<10 features)
- [ ] Out-of-scope documenté
- [ ] Risques top 5 identifiés avec mitigations

### Architecture
- [ ] Commencer simple (monolithe modulaire)
- [ ] Benchmarker avant d'optimiser
- [ ] Valider hypothèses critiques (spikes)
- [ ] Plan B pour dépendances externes

### Processus
- [ ] Estimations × 2,5 + buffer 30%
- [ ] Tests obligatoires (coverage >70%)
- [ ] Documentation vivante en place
- [ ] Communication async structurée

### Équipe
- [ ] Cooldown prévu après chaque cycle
- [ ] Single source of truth documenté
- [ ] RACI défini (qui décide quoi)
- [ ] Culture "OK de dire Non"

---

## 💡 Règles d'Or

1. **YAGNI** : You Ain't Gonna Need It
2. **KISS** : Keep It Simple, Stupid
3. **DRY avec modération** : Don't Repeat Yourself (mais pas à l'excès)
4. **Fail fast** : Découvrir problèmes tôt, pas tard
5. **Ship early, ship often** : Feedback > perfection
6. **Santé équipe > features** : Pas de burn-out

---

*"Weeks of programming can save you hours of planning." - Anonymous*

*Investissez dans la réflexion. C'est toujours moins cher que refaire.*

