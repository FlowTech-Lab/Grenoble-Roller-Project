# ⏰ Système Cron - Documentation Complète

**Date** : 2025-12-22  
**Dernière mise à jour** : 2025-12-22  
**Statut** : ✅ Actif (Supercronic) | 🔄 Migration vers Solid Queue prévue  
**Version** : 1.0

---

## 📋 Vue d'Ensemble

Ce document décrit le système de tâches planifiées (cron) de l'application Grenoble Roller, actuellement basé sur **Supercronic** et **Whenever**, avec un plan de migration vers **Solid Queue** (Rails 8).

### Architecture Actuelle

- **Whenever** : Génère le crontab depuis `config/schedule.rb` (DSL Ruby)
- **Supercronic** : Lit le fichier `config/crontab` dans le conteneur Docker
- **Docker** : Les tâches s'exécutent dans le conteneur Rails
- **Logs** : `log/cron.log` (configuré dans `schedule.rb`)

---

## 📊 Tâches Cron Actuelles

| Tâche | Fréquence | Job/Task | Utilité | Status |
|-------|-----------|----------|---------|--------|
| **Sync HelloAsso** | Toutes les 5 min | `helloasso:sync_payments` | Synchroniser les paiements HelloAsso | ✅ Actif |
| **Rappels événements** | Quotidien 19h | `EventReminderJob` | Rappels 24h avant événements | ✅ Actif |
| **Rapport initiation** | Quotidien 7h (prod) | `InitiationParticipantsReportJob` | Rapport participants du jour | ✅ Actif |
| **Adhésions expirées** | Quotidien 00:00 | `memberships:update_expired` | Marquer adhésions expirées | ✅ Actif |
| **Rappels renouvellement** | Quotidien 9h | `memberships:send_renewal_reminders` | Rappels 30 jours avant expiration | ✅ Actif |

### Détails des Tâches

#### 1. Sync HelloAsso Payments (`helloasso:sync_payments`)

**Fichier** : [`lib/tasks/helloasso.rake`](../../lib/tasks/helloasso.rake)  
**Fréquence** : Toutes les 5 minutes  
**Utilité** : Synchroniser les paiements HelloAsso depuis leur API pour activer automatiquement les adhésions payées.

**Configuration** :
```ruby
every 5.minutes do
  runner 'Rails.application.load_tasks; Rake::Task["helloasso:sync_payments"].invoke'
end
```

**Note** : `Rails.application.load_tasks` est **obligatoire** car `rails runner` ne charge pas automatiquement les tâches Rake.

---

#### 2. Rappels Événements (`EventReminderJob`)

**Fichier** : [`app/jobs/event_reminder_job.rb`](../../app/jobs/event_reminder_job.rb)  
**Fréquence** : Tous les jours à 19h  
**Utilité** : Envoyer des rappels par email 24h avant chaque événement aux participants qui ont coché "rappels".

**Configuration** :
```ruby
every 1.day, at: "7:00 pm" do
  runner "EventReminderJob.perform_now"
end
```

**Filtres appliqués** :
- `wants_reminder: true` (préférence par inscription)
- Pour initiations : `wants_initiation_mail: true` (préférence globale utilisateur)
- Attendances actives uniquement (scope `.active`)
- Événements publiés et à venir uniquement
- Événements du lendemain uniquement

**Mailer** : `EventMailer.event_reminder(attendance)`

**Documentation complète** : Voir [`docs/development/Mailing/mailing-system-complete.md`](../Mailing/mailing-system-complete.md#event_reminder)

---

#### 3. Rapport Participants Initiation (`InitiationParticipantsReportJob`)

**Fichier** : [`app/jobs/initiation_participants_report_job.rb`](../../app/jobs/initiation_participants_report_job.rb)  
**Fréquence** : Tous les jours à 7h (production uniquement)  
**Utilité** : Envoyer un rapport à `contact@grenoble-roller.org` avec la liste des participants et le matériel demandé pour chaque initiation du jour.

**Configuration** :
```ruby
every 1.day, at: "7:00 am" do
  runner 'InitiationParticipantsReportJob.perform_now'
end
```

**Note** : Timing à 7h le jour même car les personnes peuvent s'inscrire jusqu'à la dernière minute.

**Mailer** : `EventMailer.initiation_participants_report(initiation)`

**Documentation complète** : Voir [`docs/development/Mailing/mailing-system-complete.md`](../Mailing/mailing-system-complete.md#initiation_participants_report)

---

#### 4. Adhésions Expirées (`memberships:update_expired`)

**Fichier** : [`lib/tasks/memberships.rake`](../../lib/tasks/memberships.rake)  
**Fréquence** : Tous les jours à minuit (00:00)  
**Utilité** : Marquer comme expirées les adhésions dont la date d'expiration est passée et envoyer un email de notification.

**Configuration** :
```ruby
every 1.day, at: "12:00 am" do
  runner 'Rails.application.load_tasks; Rake::Task["memberships:update_expired"].invoke'
end
```

**Actions** :
- Met à jour `status: 'expired'` pour les adhésions expirées
- Envoie `MembershipMailer.expired(membership)` pour chaque adhésion expirée

**Mailer** : `MembershipMailer.expired(membership)`

---

#### 5. Rappels Renouvellement (`memberships:send_renewal_reminders`)

**Fichier** : [`lib/tasks/memberships.rake`](../../lib/tasks/memberships.rake)  
**Fréquence** : Tous les jours à 9h  
**Utilité** : Envoyer des rappels aux membres dont l'adhésion expire dans 30 jours.

**Configuration** :
```ruby
every 1.day, at: "9:00 am" do
  runner 'Rails.application.load_tasks; Rake::Task["memberships:send_renewal_reminders"].invoke'
end
```

**Actions** :
- Filtre les adhésions expirant dans 30 jours
- Envoie `MembershipMailer.renewal_reminder(membership)` pour chaque adhésion

**Mailer** : `MembershipMailer.renewal_reminder(membership)`

---

## 🛠️ Configuration

### Fichier `config/schedule.rb`

Le fichier [`config/schedule.rb`](../../config/schedule.rb) définit toutes les tâches cron en utilisant la syntaxe DSL de **Whenever**.

**Syntaxe importante** :

```ruby
# ❌ ERREUR : Rails n'est pas chargé lors de la génération du crontab
every 1.day, at: "7:00 am" do
  runner "InitiationParticipantsReportJob.perform_now" if Rails.env.production?
end

# ✅ CORRECT : Vérification dans le job lui-même
every 1.day, at: "7:00 am" do
  runner 'InitiationParticipantsReportJob.perform_now'
end
```

**Pour les tâches Rake** :

```ruby
# ❌ ERREUR : Rake::Task n'est pas disponible sans chargement explicite
every 5.minutes do
  runner 'Rake::Task["helloasso:sync_payments"].invoke'
end

# ✅ CORRECT : Charger explicitement les tâches Rake
every 5.minutes do
  runner 'Rails.application.load_tasks; Rake::Task["helloasso:sync_payments"].invoke'
end
```

### Génération du Crontab

Le crontab est généré automatiquement lors du déploiement via [`ops/lib/deployment/cron.sh`](../../ops/lib/deployment/cron.sh) :

```bash
# Génération depuis le conteneur
bundle exec whenever --set 'environment=production' > config/crontab
```

**Emplacement** : `/rails/config/crontab` dans le conteneur (lu par Supercronic)

### Supercronic

**Supercronic** est un daemon cron-like conçu pour les conteneurs Docker. Il lit le fichier `/rails/config/crontab` et exécute les tâches selon la planification.

**Installation** : Déjà présent dans le Dockerfile (package système)

**Démarrage** : Démarre automatiquement avec le conteneur (voir `bin/docker-entrypoint`)

---

## 🚀 Déploiement

### Installation Automatique

Le crontab est **automatiquement installé/mis à jour** lors de chaque déploiement :

1. Build Docker
2. Migrations
3. Health checks
4. **Installation crontab** ← Ici
5. Validation finale

**Script** : [`ops/lib/deployment/cron.sh`](../../ops/lib/deployment/cron.sh) - fonction `install_crontab()`

### Installation Manuelle

Si besoin d'installer manuellement :

```bash
# Depuis la racine du projet
./ops/scripts/update-crontab.sh production
# ou
./ops/scripts/update-crontab.sh staging
```

---

## 🔍 Vérification et Dépannage

### Voir le crontab généré

```bash
# Depuis le conteneur
docker exec grenoble-roller-staging bundle exec whenever --set 'environment=staging'
```

### Voir le crontab installé

```bash
# Depuis le conteneur
docker exec grenoble-roller-staging cat /rails/config/crontab
```

### Vérifier que Supercronic tourne

```bash
# Vérifier les processus
docker exec grenoble-roller-staging ps aux | grep supercronic

# Vérifier les logs
docker exec grenoble-roller-staging tail -f log/cron.log
```

### Tester une tâche manuellement

```bash
# Tester EventReminderJob
docker exec grenoble-roller-staging bundle exec rails runner "EventReminderJob.perform_now"

# Tester une tâche Rake
docker exec grenoble-roller-staging bundle exec rails runner "Rails.application.load_tasks; Rake::Task['helloasso:sync_payments'].invoke"
```

### Problèmes Courants

#### ❌ "Échec de la génération du crontab"

**Cause** : Erreur dans `config/schedule.rb` (utilisation de `Rails.env` ou `Rake::Task` sans chargement)

**Solution** : Vérifier la syntaxe dans `config/schedule.rb` (voir section "Configuration")

#### ❌ "Supercronic ne tourne pas"

**Cause** : Supercronic n'est pas démarré ou le fichier `config/crontab` est absent/invalide

**Solution** :
```bash
# Vérifier que le conteneur tourne
docker ps | grep grenoble-roller

# Vérifier que le crontab existe
docker exec grenoble-roller-staging test -f /rails/config/crontab && echo "OK" || echo "Manquant"

# Relancer le déploiement
./ops/staging/deploy.sh
```

#### ❌ "Les emails automatiques ne sont pas envoyés"

**Cause** : Jobs cron ne s'exécutent pas ou erreurs dans les jobs

**Solution** :
1. Vérifier les logs : `docker exec grenoble-roller-staging tail -f log/cron.log`
2. Vérifier que Supercronic tourne (voir ci-dessus)
3. Tester manuellement le job (voir ci-dessus)

---

## 🔄 Migration vers Solid Queue (Plan Futur)

### Pourquoi Migrer ?

- ✅ Éliminer Supercronic (dépendance externe)
- ✅ Ajouter contrôle de concurrence sur HelloAsso (fix race condition)
- ✅ Améliorer observabilité (Mission Control dashboard)
- ✅ Intégration native Rails 8
- ✅ Retry automatique et gestion d'erreurs améliorée

### Plan de Migration

**Phase 1 : Setup** (1h)
- `bundle add solid_queue mission_control-jobs`
- `rails db:prepare` (crée tables Solid Queue)
- Créer `config/recurring.yml`
- Créer `config/initializers/solid_queue.rb`

**Phase 2 : Jobs Implementation** (2h)
- Créer `SyncHelloAssoPaymentsJob` avec `limits_concurrency`
- Créer `UpdateExpiredMembershipsJob`
- Créer `SendRenewalRemindersJob`
- `EventReminderJob` et `InitiationParticipantsReportJob` : Existent déjà

**Phase 3 : Config Updates** (1h)
- Mettre à jour `config/routes.rb` → ajouter Mission Control
- Mettre à jour `docker-compose.yml` → `SOLID_QUEUE_IN_PUMA: 'true'`
- Mettre à jour `bin/docker-entrypoint` → supprimer Supercronic

**Phase 4 : Testing** (1h)
- Tester chaque job manuellement
- Vérifier Mission Control dashboard
- Vérifier `recurring.yml` charges
- Vérifier `limits_concurrency` fonctionne

**Phase 5 : Deployment** (2h)
- Déployer à staging (1 semaine de monitoring)
- Déployer à production
- Supprimer `config/schedule.rb`
- Supprimer Whenever gem
- Supprimer Supercronic du Dockerfile

### Configuration Solid Queue (Preview)

**`config/recurring.yml`** :
```yaml
production:
  sync_helloasso_payments:
    class: SyncHelloAssoPaymentsJob
    queue: default
    schedule: every 5 minutes
    limits_concurrency:
      by: 1
      of: SyncHelloAssoPaymentsJob
  
  event_reminder:
    class: EventReminderJob
    queue: default
    schedule: every day at 7:00pm
  
  initiation_participants_report:
    class: InitiationParticipantsReportJob
    queue: default
    schedule: every day at 7:00am
  
  update_expired_memberships:
    class: UpdateExpiredMembershipsJob
    queue: default
    schedule: every day at 12:00am
  
  send_renewal_reminders:
    class: SendRenewalRemindersJob
    queue: default
    schedule: every day at 9:00am
```

**`config/initializers/solid_queue.rb`** :
```ruby
Rails.application.config.solid_queue.connects_to = {
  default: { writing: :primary }
}
```

**Mission Control** : `/admin_panel/jobs` (dashboard web pour monitoring)

---

## 📚 Références

### Fichiers de Configuration

- [`config/schedule.rb`](../../config/schedule.rb) - Configuration Whenever (source)
- [`config/crontab`](../../config/crontab) - Crontab généré (lu par Supercronic)
- [`config/recurring.yml`](../../config/recurring.yml) - Configuration Solid Queue (futur)
- [`ops/lib/deployment/cron.sh`](../../ops/lib/deployment/cron.sh) - Script d'installation

### Scripts et Jobs

- [`ops/scripts/update-crontab.sh`](../../ops/scripts/update-crontab.sh) - Installation manuelle crontab
- [`app/jobs/event_reminder_job.rb`](../../app/jobs/event_reminder_job.rb) - EventReminderJob
- [`app/jobs/initiation_participants_report_job.rb`](../../app/jobs/initiation_participants_report_job.rb) - InitiationParticipantsReportJob
- [`lib/tasks/helloasso.rake`](../../lib/tasks/helloasso.rake) - Tâche sync HelloAsso
- [`lib/tasks/memberships.rake`](../../lib/tasks/memberships.rake) - Tâches adhésions

### Documentation

- [`docs/development/Mailing/mailing-system-complete.md`](../Mailing/mailing-system-complete.md) - Documentation complète système de mailing
- [`docs/09-product/deployment-cron.md`](../../09-product/deployment-cron.md) - Documentation déploiement cron (ancienne)

### Liens Externes

- [Whenever Gem](https://github.com/javan/whenever) - Documentation Whenever
- [Supercronic](https://github.com/aptible/supercronic) - Documentation Supercronic
- [Solid Queue](https://github.com/rails/solid_queue) - Documentation Solid Queue
- [Mission Control Jobs](https://github.com/rails/mission_control-jobs) - Documentation Mission Control

---

## ✅ Checklist Déploiement

- [ ] Le crontab est installé automatiquement lors du déploiement
- [ ] Les logs sont dans `log/cron.log`
- [ ] Supercronic tourne dans le conteneur
- [ ] Les tâches sont visibles avec `cat /rails/config/crontab`
- [ ] Les rappels événements fonctionnent (tester avec un événement du lendemain)
- [ ] Le sync HelloAsso fonctionne (vérifier les logs toutes les 5 min)
- [ ] Les rappels renouvellement fonctionnent (vérifier les logs à 9h)

---

**Retour** : [INDEX développement](../README.md) | [INDEX principal](../../README.md)