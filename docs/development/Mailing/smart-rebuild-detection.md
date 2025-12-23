# 🧠 Détection Intelligente Rebuild vs Restart - Guide Complet

**Date** : 2025-12-30  
**Dernière mise à jour** : 2025-12-30 (ajout relance automatique `compose up -d`)  
**Objectif** : Éviter les rebuilds inutiles en détectant les restarts internes vs vrais besoins de rebuild + relance automatique en cas d'échec

---

## ✅ Fonctionnalités Implémentées

### 1. Détection de Restart Interne

**Fonction** : `detect_internal_restart(container_name, max_age)`

**Logique** :
- Vérifie si le conteneur a été redémarré/arrêté récemment (< 5 minutes)
- Compare `StartedAt` ou `FinishedAt` avec l'heure actuelle
- Retourne `0` si restart interne, `1` sinon

**Utilisation** :
```bash
if detect_internal_restart "grenoble-roller-staging" 300; then
    # Restart interne détecté → pas besoin de rebuild
    docker compose restart
else
    # Vrai problème → rebuild nécessaire
    force_rebuild_without_cache
fi
```

### 2. Détection Intelligente du Besoin de Rebuild

**Fonction** : `needs_rebuild(container_name)`

**Vérifications** :
1. **Conteneur n'existe pas** → Rebuild nécessaire
2. **Restart interne récent** → Pas besoin de rebuild
3. **Changements critiques** dans :
   - `Gemfile`, `Gemfile.lock`
   - `Dockerfile`, `Dockerfile.dev`
   - `package.json`, `package-lock.json`, `yarn.lock`
   - `config/database.yml`
   - `config/solid_queue.yml`
   - `bin/docker-entrypoint`
4. **Image ancienne** (> 24h) → Rebuild recommandé
5. **Nouvelles migrations** → Rebuild nécessaire

### 3. Confirmation Interactive avec Timeout

**Fonction** : `prompt_with_timeout(message, timeout, default)`

**Comportement** :
- **Staging** : Défaut `NON`, timeout 120s
- **Production** : Défaut `OUI`, timeout 120s
- **Mode non-interactif** : Utilise la valeur par défaut automatiquement
- **Timeout atteint** : Utilise la valeur par défaut

**Exemple** :
```bash
# Staging
prompt_with_timeout "Voulez-vous rebuild ?" 120 "no"
# → (o/N, timeout: 120s, défaut: NON) : 

# Production
prompt_with_timeout "Voulez-vous rebuild ?" 120 "yes"
# → (O/n, timeout: 120s, défaut: OUI) : 
```

---

## 📋 Flux de Décision

### Scénario 1 : Restart Interne Détecté

```
1. Conteneur s'arrête/redémarre récemment (< 5 min)
2. needs_rebuild() détecte restart interne
3. → Pas besoin de rebuild
4. → Redémarrage simple du conteneur
```

### Scénario 2 : Changements Critiques Détectés

```
1. Changements dans Gemfile, Dockerfile, database.yml, etc.
2. needs_rebuild() détecte changements critiques
3. → Rebuild nécessaire
4. → Demande confirmation (défaut selon environnement)
5. → Rebuild si confirmé, restart sinon
```

### Scénario 3 : Conteneur N'Existe Pas

```
1. Conteneur n'existe pas
2. needs_rebuild() détecte absence
3. → Rebuild obligatoire (pas de confirmation)
4. → Rebuild complet
```

### Scénario 4 : Pas de Changements

```
1. Pas de changements critiques
2. Pas de restart interne récent
3. needs_rebuild() retourne false
4. → Redémarrage simple du conteneur
```

---

## 🔧 Configuration par Environnement

### Staging

**Comportement** :
- Détection intelligente activée
- Confirmation demandée si rebuild nécessaire
- **Défaut : NON** (évite rebuilds inutiles)
- Timeout : 120 secondes

**Exemple** :
```bash
./ops/staging/deploy.sh

# Si rebuild nécessaire :
# → "Voulez-vous effectuer un rebuild complet sans cache ?"
# → (o/N, timeout: 120s, défaut: NON) : 
# → Si pas de réponse → NON (redémarrage simple)
```

### Production

**Comportement** :
- Détection intelligente activée
- Confirmation demandée si rebuild nécessaire
- **Défaut : OUI** (sécurité en production)
- Timeout : 120 secondes

**Exemple** :
```bash
./ops/production/deploy.sh

# Si rebuild nécessaire :
# → "Voulez-vous effectuer un rebuild complet sans cache ?"
# → (O/n, timeout: 120s, défaut: OUI) : 
# → Si pas de réponse → OUI (rebuild complet)
```

---

## 🎯 Avantages

### 1. Évite Rebuilds Inutiles

**Avant** :
- Rebuild systématique même pour restart interne
- 5-10 minutes perdues inutilement

**Après** :
- Détection intelligente des restarts internes
- Redémarrage simple si pas de changements
- **Gain de temps : 5-10 minutes par déploiement**

### 2. Sécurité en Production

**Avant** :
- Rebuild automatique sans confirmation
- Risque de downtime non contrôlé

**Après** :
- Confirmation demandée (défaut OUI)
- Timeout de 120s pour éviter blocage
- Contrôle opérateur

### 3. Flexibilité en Staging

**Avant** :
- Rebuild systématique
- Pas de choix

**Après** :
- Confirmation demandée (défaut NON)
- Possibilité de skip rebuild si pas nécessaire
- **Gain de temps en staging**

---

## ⚠️ Cas Particuliers

### 1. Mode Non-Interactif

**Comportement** :
- Si `-t 0` ou `-t 1` (pas de terminal)
- Utilise automatiquement la valeur par défaut
- Pas de blocage

**Exemple** :
```bash
# Dans un script automatique
./ops/production/deploy.sh
# → Mode non-interactif détecté
# → Utilise défaut: OUI (production)
# → Rebuild automatique
```

### 2. Timeout Atteint

**Comportement** :
- Si pas de réponse après 120s
- Utilise la valeur par défaut
- Continue le déploiement

**Exemple** :
```bash
# Staging, timeout atteint
# → "⏱️  Timeout atteint (120s), utilisation de la valeur par défaut: NON"
# → Redémarrage simple
```

### 3. Restart Interne Après Migrations

**Comportement** :
- Si conteneur s'arrête après migrations
- Détection si restart interne (< 5 min)
- Redémarrage automatique si restart interne
- Rebuild si problème réel

---

## 📊 Tableau Récapitulatif

| Situation | Détection | Action | Confirmation |
|-----------|-----------|--------|--------------|
| Restart interne récent | `detect_internal_restart()` | Redémarrage simple | Non |
| Changements critiques | `needs_rebuild()` | Rebuild nécessaire | Oui (défaut selon env) |
| Conteneur n'existe pas | `needs_rebuild()` | Rebuild obligatoire | Non |
| Pas de changements | `needs_rebuild()` | Redémarrage simple | Non |
| Image ancienne (>24h) | `needs_rebuild()` | Rebuild recommandé | Oui (défaut selon env) |

---

## 🔍 Détails Techniques

### Fonction `detect_internal_restart()`

**Paramètres** :
- `container_name` : Nom du conteneur
- `max_restart_age` : Âge maximum en secondes (défaut: 300 = 5 min)

**Logique** :
1. Vérifie si conteneur existe
2. Récupère `State.Status` (running/exited)
3. Si `running` : compare `StartedAt` avec maintenant
4. Si `exited` : compare `FinishedAt` avec maintenant
5. Si âge < `max_restart_age` → restart interne

### Fonction `needs_rebuild()`

**Vérifications dans l'ordre** :
1. Conteneur existe ? → Rebuild si non
2. Restart interne ? → Pas de rebuild si oui
3. Changements critiques ? → Rebuild si oui
4. Image ancienne ? → Rebuild si oui
5. Nouvelles migrations ? → Rebuild si oui
6. Sinon → Pas de rebuild

### Fonction `prompt_with_timeout()`

**Paramètres** :
- `message` : Message à afficher
- `timeout_seconds` : Timeout en secondes (défaut: 120)
- `default_answer` : "yes" ou "no" (défaut: "no")

**Comportement** :
- Affiche message avec valeur par défaut
- Attend réponse avec timeout
- Si timeout → utilise défaut
- Si réponse vide → utilise défaut
- Si réponse invalide → utilise défaut

---

## 🔄 Relance Automatique de `docker compose up -d`

### Sécurité Ajoutée

**Problème** : Parfois, après un `docker compose up -d`, un conteneur peut échouer silencieusement ou ne pas démarrer correctement.

**Solution** : Relance automatique de `docker compose up -d` à chaque détection d'échec.

### Points de Relance

1. **Après `force_rebuild_without_cache()`**
   - Vérifie que tous les services (web, db, minio) sont `running`
   - Si un service échoue → relance `compose up -d`
   - Si le `compose up` initial échoue → relance une fois

2. **Après vérification migrations**
   - Si conteneur pas stable après 120s → relance `compose up -d`

3. **Après healthcheck**
   - Si conteneur pas healthy après restart → relance `compose up -d`
   - Si conteneur s'arrête (pas restart interne) → relance `compose up -d`

4. **Avant migrations**
   - Si conteneur pas running → relance `compose up -d` avant migrations

5. **Après migrations**
   - Si conteneur s'arrête après migrations → relance `compose up -d`
   - Si restart échoue → dernière tentative avec `compose up -d`

### Logique de Sécurité

```
1. compose up -d initial
   ↓
2. Vérification état conteneur
   ↓
3. Si échec détecté
   ↓
4. Relance compose up -d (sécurité)
   ↓
5. Nouvelle vérification
   ↓
6. Si toujours échec → rollback
```

### Exemple de Log

```
✅ Tous les services démarrés avec succès
🔍 Vérification que tous les conteneurs sont bien démarrés...
⚠️  Service web n'est pas running (status: exited)
⚠️  Certains services ont échoué, relance de 'docker compose up -d' pour être sûr...
✅ Services redémarrés avec succès
✅ Tous les services sont running
```

---

## ✅ Checklist de Vérification

- [x] Fonction `detect_internal_restart()` implémentée
- [x] Fonction `needs_rebuild()` implémentée
- [x] Fonction `prompt_with_timeout()` implémentée
- [x] Logique intégrée dans `ops/deploy.sh`
- [x] Staging : défaut NON, timeout 120s
- [x] Production : défaut OUI, timeout 120s
- [x] Gestion mode non-interactif
- [x] Gestion timeout
- [x] Redémarrage automatique si restart interne
- [x] Relance automatique `compose up -d` après échecs
- [x] Vérification services après `force_rebuild_without_cache`
- [x] Points de relance multiples dans `deploy.sh`
- [ ] Tests en staging
- [ ] Tests en production

---

## 📚 Références

- Document : `docs/development/Mailing/solid-queue-deployment-fix.md`
- Document : `docs/development/Mailing/solid-queue-migration-order.md`
- Script : `ops/lib/core/utils.sh` (fonctions utilitaires)
- Script : `ops/deploy.sh` (logique de déploiement)

---

**Date de mise à jour** : 2025-12-30  
**Statut** : ✅ **IMPLÉMENTATION COMPLÈTE**
