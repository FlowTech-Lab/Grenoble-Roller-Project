---
title: "Audit Fichiers Obsolètes, Mal Placés et Mal Nommés"
status: "active"
version: "1.0"
created: "2025-01-30"
updated: "2025-01-30"
tags: ["audit", "documentation", "cleanup", "organization"]
---

# Audit Fichiers Obsolètes, Mal Placés et Mal Nommés

**Date de l'audit** : 2025-01-30  
**Objectif** : Identifier tous les fichiers à renommer, déplacer ou consolider

---

## 🔴 Fichiers Mal Nommés (Majuscules)

**Convention** : kebab-case uniquement, pas de majuscules

### À la racine de `docs/`

| Fichier Actuel | Nom Correct | Action |
|---------------|-------------|--------|
| `BUGFIX-DEPLOY-SCRIPT.md` | `bugfix-deploy-script.md` | ⚠️ Renommer |
| `BUGFIX-MAINTENANCE-MODE.md` | `bugfix-maintenance-mode.md` | ⚠️ Renommer |
| `DEPLOY-VPS.md` | `deploy-vps.md` | ⚠️ Renommer |
| `DEPLOYMENT.md` | `deployment.md` | ⚠️ Renommer |
| `MAINTENANCE-CONFORMITY.md` | `maintenance-conformity.md` | ⚠️ Renommer |
| `MAINTENANCE-MODE.md` | `maintenance-mode.md` | ⚠️ Renommer |

### Dans `docs/08-security-privacy/`

| Fichier Actuel | Nom Correct | Action |
|---------------|-------------|--------|
| `A11Y_TESTING.md` | `a11y-testing.md` | ⚠️ Renommer (majuscules + underscore) |

**Total** : 7 fichiers mal nommés

---

## 📁 Fichiers Mal Placés (À la racine de `docs/`)

**Convention** : Tous les fichiers doivent être dans des sous-dossiers organisés (00-overview, 07-ops, etc.)

### Fichiers Ops à Déplacer vers `07-ops/`

| Fichier Actuel | Nouvelle Location | Raison |
|---------------|-------------------|--------|
| `BUGFIX-DEPLOY-SCRIPT.md` | `07-ops/bugfix-deploy-script.md` | Bugfix déploiement = ops |
| `BUGFIX-MAINTENANCE-MODE.md` | `07-ops/bugfix-maintenance-mode.md` | Bugfix maintenance = ops |
| `DEPLOY-VPS.md` | `07-ops/deploy-vps.md` | Déploiement VPS = ops |
| `DEPLOYMENT.md` | `07-ops/deployment.md` | Déploiement = ops |
| `MAINTENANCE-CONFORMITY.md` | `07-ops/maintenance-conformity.md` | Maintenance = ops |
| `MAINTENANCE-MODE.md` | `07-ops/maintenance-mode.md` | Maintenance = ops |

**Total** : 6 fichiers à déplacer vers `07-ops/`

---

## 📦 Fichiers à Consolider

### 1. Fichiers Turnstile (9 fichiers)

**Emplacement** : `docs/04-rails/setup/`

**Liste** :
1. `turnstile-setup.md` (document principal)
2. `turnstile-test-guide.md`
3. `turnstile-debug-steps.md`
4. `turnstile-errors-cloudflare.md`
5. `turnstile-troubleshooting.md`
6. `turnstile-verification-problem.md`
7. `turnstile-test-verification.md`
8. `turnstile-test-simple.md`
9. `turnstile-debug-commands.md`

**Problème** : 9 fichiers pour un seul sujet (Turnstile)

**Recommandation** : Consolider en 2-3 fichiers maximum :
- `turnstile-setup.md` (principal)
- `turnstile-troubleshooting.md` (debug + errors + verification problems)
- `turnstile-testing.md` (tous les guides de test)

**Action** : ⚠️ À consolider

---

### 2. Fichiers .txt dans `a11y-reports/`

**Emplacement** : `docs/08-security-privacy/a11y-reports/`

**Fichiers** :
- `pa11y-20251115_032122.txt` (rapport brut)
- `pa11y-validation-20251115_032756.txt` (rapport brut)

**Problème** : Fichiers .txt (rapports bruts) au lieu de .md

**Recommandation** : 
- Garder uniquement les .md (résumés)
- Déplacer les .txt vers un dossier `reports/raw/` ou les supprimer

**Action** : ⚠️ À nettoyer

---

## 🔍 Fichiers Potentiellement Obsolètes

### À Vérifier

1. **`docs/prompts/perplexity-email-confirmation-method.md`**
   - Prompts pour Perplexity (outil externe)
   - **Question** : Est-ce de la documentation technique ou juste des prompts ?
   - **Recommandation** : Déplacer vers `ressources/` ou supprimer si obsolète

2. **`docs/04-rails/setup/devise-email-security-guide.md`**
   - Guide très long (1930 lignes)
   - **Question** : Est-ce encore utilisé ou remplacé par `email-confirmation.md` ?
   - **Action** : ⚠️ À vérifier si encore nécessaire

---

## 📊 Résumé par Catégorie

### Mal Nommés (Majuscules)
- **Total** : 7 fichiers
- **Statut** : ✅ **COMPLETÉ** - Tous renommés en kebab-case

### Mal Placés (Racine docs/)
- **Total** : 6 fichiers
- **Statut** : ✅ **COMPLETÉ** - Tous déplacés vers `07-ops/`

### À Consolider
- **Turnstile** : 9 fichiers → 1 fichier consolidé ✅
  - **Créé** : `turnstile-troubleshooting-consolidated.md`
  - **Action** : Les 8 anciens fichiers peuvent être supprimés (conservés pour référence historique)
- **a11y-reports** : 2 fichiers .txt
  - **Fichiers** : `pa11y-20251115_032122.txt`, `pa11y-validation-20251115_032756.txt`
  - **Recommandation** : Conserver (rapports bruts de tests) OU déplacer vers `a11y-reports/raw/`
  - **Statut** : ⚠️ À décider

### À Vérifier
- **Prompts** : 1 fichier (`prompts/perplexity-email-confirmation-method.md`)
  - **Recommandation** : Déplacer vers `ressources/` ou supprimer si obsolète
  - **Statut** : ⚠️ À vérifier
- **Devise guide** : 1 fichier (`devise-email-security-guide.md`)
  - **Recommandation** : Vérifier si remplacé par `email-confirmation.md`
  - **Statut** : ⚠️ À vérifier

---

## 🎯 Plan d'Action Recommandé

### Phase 1 : Renommage (Priorité Haute)
1. Renommer les 7 fichiers avec majuscules en kebab-case
2. Mettre à jour toutes les références dans les autres fichiers

### Phase 2 : Déplacement (Priorité Haute)
1. Déplacer les 6 fichiers ops vers `07-ops/`
2. Mettre à jour les références

### Phase 3 : Consolidation (Priorité Moyenne)
1. Consolider les fichiers Turnstile (9 → 2-3)
2. Nettoyer les fichiers .txt dans a11y-reports

### Phase 4 : Vérification (Priorité Basse)
1. Vérifier et décider pour `prompts/perplexity-email-confirmation-method.md`
2. Vérifier si `devise-email-security-guide.md` est encore nécessaire

---

## 📝 Notes

- **Références à mettre à jour** : Après renommage/déplacement, chercher toutes les références avec `grep`
- **Git** : Utiliser `git mv` pour préserver l'historique
- **README.md** : Mettre à jour après chaque changement

---

**Version** : 1.0  
**Dernière mise à jour** : 2025-01-30

