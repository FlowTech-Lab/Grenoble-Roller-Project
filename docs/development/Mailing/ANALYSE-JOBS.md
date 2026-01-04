# 📊 Analyse des Jobs Récurrents - Nécessité et État

**Date** : 2025-01-13  
**Objectif** : Vérifier si les jobs récurrents sont nécessaires et s'ils fonctionnent correctement

---

## 📋 État Actuel des Jobs

### ✅ Jobs Configurés dans `config/recurring.yml` (SolidQueue)

| Job | Nécessaire ? | Fonctionne ? | Utilité |
|-----|--------------|--------------|---------|
| **EventReminderJob** | ✅ **OUI** | ✅ Oui (si SolidQueue tourne) | Envoie des rappels 24h avant les événements |
| **clear_solid_queue_finished_jobs** | ✅ **OUI** | ✅ Oui (si SolidQueue tourne) | Nettoie les jobs terminés (évite croissance DB) |

---

### ⚠️ Jobs Existant MAIS PAS dans `recurring.yml` (Migration nécessaire)

| Job | Nécessaire ? | Fonctionne ? | Utilité | Action |
|-----|--------------|--------------|---------|--------|
| **SyncHelloAssoPaymentsJob** | ✅ **OUI** | ❌ Non (pas dans recurring.yml) | Synchronise les paiements HelloAsso toutes les 5 min | ⚠️ **À AJOUTER** |
| **UpdateExpiredMembershipsJob** | ✅ **OUI** | ❌ Non (pas dans recurring.yml) | Met à jour les adhésions expirées (minuit) | ⚠️ **À AJOUTER** |
| **SendRenewalRemindersJob** | ✅ **OUI** | ❌ Non (pas dans recurring.yml) | Envoie rappels renouvellement (9h) | ⚠️ **À AJOUTER** |

---

## 🔍 Analyse Détaillée

### 1. EventReminderJob ✅ **NÉCESSAIRE**

**Utilité** :
- Envoie des rappels email 24h avant les événements
- Respecte les préférences utilisateur (`wants_reminder`)
- Groupe les attendances par utilisateur (évite emails multiples)

**Impact si désactivé** :
- ❌ Les participants ne reçoivent plus de rappels
- ❌ Risque d'oubli d'événements
- ❌ Expérience utilisateur dégradée

**Status** : ✅ Configuré dans `recurring.yml` (19h quotidien)

---

### 2. clear_solid_queue_finished_jobs ✅ **NÉCESSAIRE**

**Utilité** :
- Nettoie les jobs terminés de la table `solid_queue_jobs`
- Évite la croissance infinie de la base de données
- S'exécute toutes les heures

**Impact si désactivé** :
- ⚠️ La table `solid_queue_jobs` grandit indéfiniment
- ⚠️ Performance dégradée au fil du temps
- ⚠️ Espace disque consommé

**Status** : ✅ Configuré dans `recurring.yml` (toutes les heures)

---

### 3. SyncHelloAssoPaymentsJob ⚠️ **NÉCESSAIRE MAIS PAS CONFIGURÉ**

**Utilité** :
- Synchronise les paiements HelloAsso en attente toutes les 5 minutes
- Active automatiquement les adhésions payées
- Met à jour le statut des paiements (`pending` → `paid`)

**Impact si désactivé** :
- ❌ Les paiements HelloAsso ne sont pas synchronisés automatiquement
- ❌ Les adhésions payées ne sont pas activées automatiquement
- ❌ Intervention manuelle nécessaire pour chaque paiement

**Status** : ⚠️ Job existe (`app/jobs/sync_hello_asso_payments_job.rb`) mais **PAS dans `recurring.yml`**

**Solution** : Ajouter dans `config/recurring.yml` :
```yaml
production:
  sync_helloasso_payments:
    class: SyncHelloAssoPaymentsJob
    queue: default
    schedule: every 5 minutes
```

---

### 4. UpdateExpiredMembershipsJob ⚠️ **NÉCESSAIRE MAIS PAS CONFIGURÉ**

**Utilité** :
- Met à jour les adhésions expirées (statut `active` → `expired`)
- Envoie un email d'expiration aux membres
- S'exécute tous les jours à minuit

**Impact si désactivé** :
- ❌ Les adhésions expirées restent en statut `active`
- ❌ Pas d'email d'expiration envoyé
- ❌ Confusion pour les membres (adhésion expirée mais toujours active)

**Status** : ⚠️ Job existe (`app/jobs/update_expired_memberships_job.rb`) mais **PAS dans `recurring.yml`**

**Solution** : Ajouter dans `config/recurring.yml` :
```yaml
production:
  update_expired_memberships:
    class: UpdateExpiredMembershipsJob
    queue: default
    schedule: every day at 12:00am
```

---

### 5. SendRenewalRemindersJob ⚠️ **NÉCESSAIRE MAIS PAS CONFIGURÉ**

**Utilité** :
- Envoie des rappels de renouvellement 30 jours avant expiration
- Aide les membres à renouveler à temps
- S'exécute tous les jours à 9h

**Impact si désactivé** :
- ❌ Pas de rappel de renouvellement
- ❌ Risque d'oubli de renouvellement
- ❌ Perte de membres potentiels

**Status** : ⚠️ Job existe (`app/jobs/send_renewal_reminders_job.rb`) mais **PAS dans `recurring.yml`**

**Solution** : Ajouter dans `config/recurring.yml` :
```yaml
production:
  send_renewal_reminders:
    class: SendRenewalRemindersJob
    queue: default
    schedule: every day at 9:00am
```

---

## 🚨 Problème Identifié

### Duplication Rake Tasks vs Jobs

**Situation actuelle** :
- Les **jobs** existent (`app/jobs/*.rb`) ✅
- Les **rake tasks** existent (`lib/tasks/*.rake`) ✅
- Les jobs **ne sont PAS** dans `recurring.yml` ❌
- Les rake tasks sont dans `config/schedule.rb` (Supercronic) ⚠️ Mais Supercronic ne tourne pas

**Problème** :
- Les jobs sont créés mais jamais exécutés automatiquement
- Les rake tasks sont configurées pour Supercronic (qui ne tourne pas)
- **Aucun job ne s'exécute réellement** ❌

---

## ✅ Solution Recommandée

### Étape 1 : Ajouter les jobs manquants dans `config/recurring.yml`

```yaml
production:
  clear_solid_queue_finished_jobs:
    command: "SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)"
    schedule: every hour at minute 12

  event_reminder:
    class: EventReminderJob
    queue: default
    schedule: every day at 7:00pm

  sync_helloasso_payments:
    class: SyncHelloAssoPaymentsJob
    queue: default
    schedule: every 5 minutes

  update_expired_memberships:
    class: UpdateExpiredMembershipsJob
    queue: default
    schedule: every day at 12:00am

  send_renewal_reminders:
    class: SendRenewalRemindersJob
    queue: default
    schedule: every day at 9:00am
```

### Étape 2 : Vérifier que Solid Queue charge `recurring.yml`

```bash
# Vérifier que les jobs récurrents sont chargés
docker exec grenoble-roller-production bin/rails runner "puts SolidQueue::RecurringTask.count"

# Doit retourner le nombre de jobs configurés (ex: 5)
```

### Étape 3 : Vérifier l'exécution

```bash
# Vérifier les jobs récurrents enregistrés
docker exec grenoble-roller-production bin/rails runner "SolidQueue::RecurringTask.all.each { |t| puts \"#{t.key}: #{t.schedule}\" }"
```

---

## 📊 Résumé

| Job | Nécessaire | Configuré | Fonctionne | Action |
|-----|------------|-----------|------------|--------|
| EventReminderJob | ✅ OUI | ✅ Oui | ✅ Oui | ✅ OK |
| clear_solid_queue_finished_jobs | ✅ OUI | ✅ Oui | ✅ Oui | ✅ OK |
| SyncHelloAssoPaymentsJob | ✅ OUI | ❌ Non | ❌ Non | ⚠️ **À AJOUTER** |
| UpdateExpiredMembershipsJob | ✅ OUI | ❌ Non | ❌ Non | ⚠️ **À AJOUTER** |
| SendRenewalRemindersJob | ✅ OUI | ❌ Non | ❌ Non | ⚠️ **À AJOUTER** |

---

## 🎯 Conclusion

**Tous les jobs sont nécessaires** pour le bon fonctionnement de l'application :

1. ✅ **EventReminderJob** : Essentiel pour l'expérience utilisateur
2. ✅ **clear_solid_queue_finished_jobs** : Essentiel pour la maintenance DB
3. ✅ **SyncHelloAssoPaymentsJob** : Essentiel pour l'activation automatique des paiements
4. ✅ **UpdateExpiredMembershipsJob** : Essentiel pour la gestion des adhésions
5. ✅ **SendRenewalRemindersJob** : Essentiel pour la rétention des membres

**Action requise** : Ajouter les 3 jobs manquants dans `config/recurring.yml` pour qu'ils s'exécutent automatiquement via Solid Queue.

---

**Dernière mise à jour** : 2025-01-13
