---
title: "Hello Asso - Configuration Polling Automatique"
status: "active"
version: "1.0"
created: "2025-01-26"
tags: ["helloasso", "polling", "cron", "whenever"]
---

# Hello Asso - Configuration Polling Automatique

**Objectif** : Configurer le polling automatique des paiements HelloAsso toutes les 5 minutes.

---

## 🎯 Solution : Whenever Gem

**Pourquoi Whenever ?**
- ✅ Simple et éprouvé
- ✅ Syntaxe Ruby claire
- ✅ Gère les environnements (dev/prod)
- ✅ Intégration facile avec Rails

---

## 📋 INSTALLATION

### 1. Installer la gem

```bash
bundle install
```

La gem `whenever` est déjà dans le `Gemfile`.

### 2. Initialiser Whenever (déjà fait)

Le fichier `config/schedule.rb` est déjà créé avec la configuration.

### 3. Vérifier la configuration

```bash
# Voir la cron générée (sans l'installer)
whenever

# Voir avec les variables d'environnement
whenever --set environment=production
```

---

## 🔧 CONFIGURATION

### Fichier `config/schedule.rb`

```ruby
# Sync HelloAsso payments toutes les 5 minutes
every 5.minutes do
  runner 'Rake::Task["helloasso:sync_payments"].invoke'
end
```

### Déployer la cron

```bash
# En développement (optionnel)
whenever --update-crontab --set environment=development

# En production (OBLIGATOIRE)
whenever --update-crontab --set environment=production
```

⚠️ **IMPORTANT** : À faire sur le serveur de production après chaque déploiement.

---

## 🧪 TEST

### Tester manuellement

```bash
# Tester la rake task
bin/rails helloasso:sync_payments

# Vérifier les logs
tail -f log/development.log | grep Helloasso
```

### Vérifier que la cron est installée

```bash
# Voir les crons de l'utilisateur
crontab -l

# Devrait afficher quelque chose comme :
# */5 * * * * /bin/bash -l -c 'cd /path/to/app && RAILS_ENV=production bundle exec rails runner "Rake::Task[\"helloasso:sync_payments\"].invoke" >> log/cron.log 2>&1'
```

---

## 🔄 AUTO-REFRESH SUR LA PAGE COMMANDE

### Fonctionnalité

Sur la page détail d'une commande `pending`, l'utilisateur voit :
- ✅ **Alerte** : "⏳ Paiement en attente - Vérification automatique en cours..."
- ✅ **Bouton** : "🔄 Vérifier maintenant" (force la vérification)
- ✅ **Auto-poll JS** : Vérifie automatiquement toutes les 10 secondes pendant 1 minute

### Routes ajoutées

- `POST /orders/:id/check-payment` → Force la vérification du paiement
- `GET /orders/:id/payment-status` → Retourne le statut en JSON (pour le polling JS)

### Comportement

1. **Utilisateur paie sur HelloAsso**
2. **Revient sur la page commande** → Voit l'alerte "Paiement en attente"
3. **Auto-poll démarre** → Vérifie toutes les 10s pendant 1 min
4. **Si statut change** → Page se recharge automatiquement
5. **Si pas de changement après 1 min** → Auto-poll s'arrête
6. **Bouton "Vérifier maintenant"** → Force une vérification immédiate

---

## 📊 MONITORING

### Logs

Les logs du polling sont dans :
- `log/cron.log` (cron automatique)
- `log/development.log` ou `log/production.log` (logs Rails)

### Vérifier les paiements en attente

```ruby
# Dans Rails console
Payment.where(provider: 'helloasso', status: 'pending').count
Payment.where(provider: 'helloasso', status: 'pending').where('created_at > ?', 1.day.ago)
```

---

## ⚠️ POINTS D'ATTENTION

### Production

- ✅ **Cron doit être installé** : `whenever --update-crontab` après chaque déploiement
- ✅ **Vérifier les logs** : `tail -f log/cron.log`
- ✅ **Monitoring** : Surveiller les erreurs dans les logs

### Performance

- ✅ **Scope limité** : Seulement les paiements des 24 dernières heures
- ✅ **Gestion d'erreurs** : Continue même si un paiement échoue
- ✅ **Pas de surcharge** : 1 requête API par paiement pending

---

## ✅ CHECKLIST

- [x] Gem `whenever` ajoutée au Gemfile
- [x] `config/schedule.rb` créé
- [x] Rake task `helloasso:sync_payments` fonctionnelle
- [x] Routes `check_payment` et `payment_status` ajoutées
- [x] Actions controller implémentées
- [x] Alerte + bouton + auto-poll JS dans `orders/show.html.erb`
- [ ] **À faire en production** : `whenever --update-crontab`

---

**Dernière mise à jour** : 2025-01-26  
**Version** : 1.0

