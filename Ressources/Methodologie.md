---
title: "Méthodologie de Développement - Shape Up Adapté"
type: pattern
status: active
area: ops
tags:
  - "#pattern"
  - "#methodology"
  - "#shape-up"
  - "#best-practices"
updated: 2025-10-21
created: 2025-10-21
related:
  - "Pieges_A_Eviter"
  - "MOC-MCP-Qdrant-Best-Practices"
---

# 🎯 Méthodologie de Développement - Shape Up Adapté

## 📋 Principes Fondamentaux

### L'Approche Inversée
**Commencez par la fin, pas par le début.**

Avant toute ligne de code, définissez ce que signifie "terminé" et "réussi" pour votre projet. L'approche la plus efficace consiste à penser en termes de :

```
PROBLÈME → SOLUTION → CONTRAINTES
```

Et **PAS** en termes de :
```
TECHNOLOGIE → FONCTIONNALITÉS → ARCHITECTURE ❌
```

### Règle d'Or : MVP First
Les meilleurs tech leads évitent l'over-engineering en validant d'abord le besoin réel avec un **MVP (Minimum Viable Product)** avant d'investir dans une architecture complexe.

---

## 🔄 Pourquoi Shape Up ?

### Shape Up vs. Scrum Classique

| Aspect | Scrum | Shape Up |
|--------|-------|----------|
| **Durée cycle** | 2 semaines (sprints) | 6 semaines (cycles) |
| **Problème** | Fragmentation, context switching | Deep work, features complètes |
| **Estimation** | "Ça prendra combien ?" | "On a 6 semaines" (appetite) |
| **Backlog** | Infini, démotivant | Pas de backlog zombie |
| **Meetings** | Daily standups + reviews | Async updates |
| **Repos** | Pas structuré | Cooldown 2 semaines obligatoire |

### Shape Up vs. Kanban

| Aspect | Kanban | Shape Up |
|--------|--------|----------|
| **Structure** | Flux continu | Time-boxed (deadline fixe) |
| **Risque** | Dispersion, pas de deadline | Focus forcé, shipping garanti |
| **Planification** | Réactive | Proactive (shaping avant betting) |

### Avantages Clés pour Projet Complexe
✅ **Shaping avant betting** : Réflexion structurée évite fausses routes  
✅ **Appetite vs. Estimates** : "On a 6 semaines" plutôt que "ça prendra combien ?"  
✅ **Pas de backlog infini** : Si pas sélectionné → poubelle  
✅ **Équipes autonomes** : Scope flexible pendant building  
✅ **Cooldown built-in** : Évite burn-out, permet innovation  

---

## 🔄 Les 4 Phases du Cycle Shape Up

### Phase 1️⃣ : SHAPING (Semaine -2 à 0)
**Objectif : Définir les limites avant de s'engager**

#### Actions
1. **Identifier le problème utilisateur**
   - Quelle douleur résolvons-nous ?
   - Pourquoi maintenant ?
   - Pour qui spécifiquement ?

2. **Définir l'appetite**
   - Combien de temps sommes-nous prêts à investir ?
   - Options : 2 semaines / 6 semaines / 3 mois
   - **Appetite fixe, scope flexible** (pas l'inverse !)

3. **Breadboarding & Fat Marker Sketching**
   - Solutions visuelles **grossières** sans détails esthétiques
   - But : Explorer sans s'enfermer dans les détails
   - Outils : Excalidraw, papier-crayon, whiteboard

4. **Identifier les rabbit holes**
   - Quels aspects pourraient déraper en complexité infinie ?
   - Exemple : "Internationalisation complète" = rabbit hole pour MVP
   - Documenter explicitement ce qu'on ne fera **PAS**

5. **Écrire le pitch** (1 page A4 max)
   - Problème
   - Solution proposée
   - Rabbit holes à éviter
   - Appetite
   - No-Gos (out-of-scope)

#### Output
→ **3-5 pitches prêts** pour betting table

---

### Phase 2️⃣ : BETTING TABLE (Semaine 0)
**Objectif : Priorisation brutale et engagement**

#### Actions
1. **Présenter chaque pitch** (15 min par pitch)
2. **Questions/débat** collectif
3. **Vote** : Quels projets pour le cycle suivant ?
4. **Rejeter** les pitches non sélectionnés
   - ⚠️ Pas de "backlog" ! Si rejeté → poubelle
   - Si vraiment important → reproposer cycle suivant

#### Participants
- Tech Lead
- Product Owner
- Stakeholders clés
- (Équipe dev si petite structure)

#### Output
→ **1-2 projets validés** pour le cycle de 6 semaines

---

### Phase 3️⃣ : BUILDING (Semaine 1-6)
**Objectif : Livrer une feature shippable**

#### Semaine 1-2 : Get One Piece Done
- Implémenter **une tranche verticale complète** (front + back + DB)
- Exemple : "Upload d'un fichier CSV + affichage résultat" (bout-en-bout)
- Éviter : "Faire toute la DB" puis "Faire tout le back" puis "Faire tout le front"

#### Semaine 2-4 : Map Scopes
- Découvrir progressivement la complexité réelle
- Regrouper tâches liées en "scopes" cohérents
- Ajuster le scope si nécessaire (pas la deadline !)

#### Semaine 4-6 : Downhill Execution
- Utiliser **Hill Chart** pour tracking
  - **Uphill** (montée) = Découverte, incertitude
  - **Downhill** (descente) = Exécution, certitude
- Si encore "uphill" en S5 → **ALARME** : revoir scope

#### Règles
- ✅ Pas de daily standup obligatoire → Async updates (Slack, Linear)
- ✅ Deadline **fixe** : Si pas fini S6 → Scope down ou reporter
- ✅ Feature **shippable** = déployable en prod (pas "almost done")

#### Output
→ **Feature complète déployée** en production

---

### Phase 4️⃣ : COOLDOWN (Semaine 7-8)
**Objectif : Repos, amélioration, innovation**

#### Actions (Non Négociables)
1. **Bug fixes prioritaires** signalés par utilisateurs
2. **Technical debt paydown**
   - Refactoring code douteux
   - Ajout tests manquants
   - Mise à jour dépendances
3. **R&D personnel**
   - Explorer nouvelles libs/frameworks
   - POCs techniques
4. **Formation**
   - Apprendre nouvelle techno
   - Partage de connaissances en équipe
5. **Rétrospective**
   - Qu'améliorer dans le process ?
   - Qu'est-ce qui a bien/mal marché ?
6. **Pré-shaping informel**
   - Réfléchir aux prochaines features (sans pression)

#### Règles
- ❌ **AUCUNE nouvelle feature** pendant cooldown
- ❌ **PAS de pression delivery**
- ✅ Temps pour créativité & innovation
- ✅ Santé mentale de l'équipe = priorité

#### Output
→ **Équipe reposée + learnings documentés**

---

## 🔧 Adaptation pour Solo / Petite Équipe (<5 personnes)

Si vous êtes seul ou en très petite équipe :

### Shaping
- **2-3 jours** au lieu de 2 semaines
- Pitch simplifié (1/2 page suffit)

### Betting Table
- Pas de vote formel si solo
- **Mais** : Discipline de documenter le "pourquoi" (traçabilité)
- Écrire décision même si seul décideur

### Building
- **Cycles 2-3 semaines** au lieu de 6 semaines (appetite réduit)
- Même principe : deadline fixe, scope flexible

### Cooldown
- **3-5 jours minimum** (proportionnel)
- **Non négociable** pour éviter burn-out

---

## 📊 Workflow Visuel

```
┌─────────────────────────────────────────────────────┐
│  Semaine -2 à 0 : SHAPING                           │
│  ─────────────────────────────────────────          │
│  • Identifier problème utilisateur                  │
│  • Définir appetite (2 sem, 6 sem, 3 mois ?)        │
│  • Breadboard solution (wireframe grossier)         │
│  • Identifier rabbit holes (risques techniques)     │
│  • Écrire pitch (1 page A4 max)                     │
│    → Output : 3-5 pitches pour betting              │
└─────────────────────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────┐
│  Semaine 0 : BETTING TABLE                          │
│  ─────────────────────────────────────              │
│  • Présenter pitches (15 min chacun)                │
│  • Questions/débat équipe                           │
│  • Vote : quels projets pour cycle suivant ?        │
│  • Rejeter pitches non sélectionnés (!!!!)          │
│    → Output : 1-2 projets validés pour cycle        │
└─────────────────────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────┐
│  Semaine 1-6 : BUILDING                             │
│  ─────────────────────────────────────              │
│  • Semaine 1-2 : Get one piece done (vertical       │
│    slice complet front+back)                        │
│  • Semaine 2-4 : Map scopes (découverte graduelle   │
│    complexité, grouper tâches liées)                │
│  • Semaine 4-6 : Hill chart tracking (uphill =      │
│    découverte, downhill = exécution)                │
│  • Pas de daily standup obligatoire (async updates) │
│  • Deadline fixe : si pas fini S6 → scope down      │
│    → Output : Feature shippable en prod             │
└─────────────────────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────┐
│  Semaine 7-8 : COOLDOWN                             │
│  ─────────────────────────────────────              │
│  • Bug fixes prioritaires utilisateurs              │
│  • Technical debt paydown (refacto, tests)          │
│  • R&D perso (explorer nouvelles libs)              │
│  • Formation (apprendre nouvelle techno)            │
│  • Rétro : améliorer process Shape Up               │
│  • Pré-shaping idées futures (informal)             │
│    → Output : Équipe reposée + learnings            │
└─────────────────────────────────────────────────────┘
                          ▼
                   (Repeat cycle)
```

---

## 🛠️ Outils Recommandés

### Shaping & Pitching
- **Excalidraw** / draw.io : wireframes rapides
- **Notion** / Confluence : écrire pitches structurés
- **Template pitch** : Problème | Solution | Rabbit Holes | Appetite | No-Gos

### Building
- **Linear** / Jira : tracking scopes (**pas** user stories !)
- **Hill chart** : plugin custom ou spreadsheet simple
- **Loom** : vidéos async pour montrer progrès (remplace meetings)

### Documentation
- **GitHub/GitLab** : ADR en markdown dans `/docs/adr/`
- **Mermaid** : diagrammes as code versionnés
- **OpenAPI** : specs API auto-générées

---

## 💡 Conseils Pratiques

### ✅ À Faire
- Documenter **pourquoi** pas juste **quoi**
- Scope down quand deadline approche (pas extend deadline)
- Cooldown **non négociable** (santé > feature)
- Pitch rejeté = supprimé (pas backlog zombie)

### ❌ À Éviter
- Sprints de 2 semaines fragmentés
- Backlog infini démotivant
- Estimation en heures/jours (utiliser appetite)
- Daily standups si équipe <10 personnes (async suffit)
- Sauter le cooldown "pour gagner du temps"

---

## 📚 Ressources

### Livre Officiel (Gratuit)
- [Shape Up](https://basecamp.com/shapeup) - Ryan Singer, Basecamp

### Exemples Publics
- [Basecamp Blog](https://basecamp.com/articles)
- [37signals Dev Blog](https://dev.37signals.com/)

---

*Adaptez cette méthodologie à votre contexte. L'objectif n'est pas de suivre dogmatiquement, mais de livrer de la valeur avec une équipe saine et motivée.*

