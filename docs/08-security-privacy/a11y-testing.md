---
title: "Guide Tests Accessibilité Automatisés"
status: "active"
version: "1.0"
created: "2025-11-14"
tags: ["accessibility", "a11y", "testing", "automation"]
---

# Guide Tests Accessibilité Automatisés

## 📋 Prérequis

1. **Application Rails en cours d'exécution**
   ```bash
   # En local
   bin/dev
   # Ou en Docker
   docker compose -f ops/dev/docker-compose.yml up
   ```

2. **Node.js et npm installés**
   ```bash
   node --version
   npm --version
   ```

3. **Outils installés** (déjà fait)
   ```bash
   npm install
   ```

4. **Dépendances système pour Chrome/Puppeteer** (Linux uniquement)
   ```bash
   # Ubuntu/Debian
   sudo apt-get install -y \
     libatk1.0-0 \
     libatk-bridge2.0-0 \
     libcups2 \
     libdrm2 \
     libxkbcommon0 \
     libxcomposite1 \
     libxdamage1 \
     libxfixes3 \
     libxrandr2 \
     libgbm1 \
     libasound2
   ```
   
   **Note** : Si vous êtes en Docker, ces dépendances doivent être installées dans le conteneur.

## 🚀 Utilisation

### Test complet (Pa11y + Lighthouse)

```bash
npm run test:a11y
```

### Tests individuels

#### Pa11y uniquement
```bash
npm run test:a11y:pa11y
```

#### Lighthouse uniquement
```bash
npm run test:a11y:lighthouse
```

## 📊 Résultats

Les rapports sont sauvegardés dans :
```
docs/08-security-privacy/a11y-reports/
```

- **Pa11y** : `pa11y-YYYYMMDD_HHMMSS.txt`
- **Lighthouse** : `lighthouse-{page}-{timestamp}.json`

## ⚙️ Configuration

### URLs testées

Par défaut, les tests vérifient :
- `http://localhost:3000` (Homepage)
- `http://localhost:3000/association`
- `http://localhost:3000/shop`
- `http://localhost:3000/events`
- `http://localhost:3000/users/sign_in`
- `http://localhost:3000/users/sign_up`

### Changer l'URL de base

```bash
BASE_URL=http://localhost:3001 npm run test:a11y
```

### Configuration Pa11y

Fichier : `.pa11yci.json`
- Standard : WCAG2AA
- Timeout : 10s
- Wait : 1s

## 🔍 Interprétation des résultats

### Lighthouse
- **Score ≥ 90** : ✅ Excellent
- **Score 80-89** : ⚠️ Bon, améliorations possibles
- **Score < 80** : ❌ À améliorer

### Pa11y
- **0 erreurs** : ✅ Conforme
- **Erreurs** : Voir détails dans le rapport

## 📝 Notes

- Les tests nécessitent que l'application soit accessible
- Lighthouse nécessite Chrome/Chromium
- Les rapports JSON Lighthouse peuvent être visualisés sur https://googlechrome.github.io/lighthouse/viewer/

