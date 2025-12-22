# 📧 MAILING - Emails automatiques

**Status** : ✅ Implémenté | **Configuration** : Via tâches cron / Solid Queue

> 📖 **Documentation complète** : Voir [`docs/development/Mailing/mailing-system-complete.md`](../../Mailing/mailing-system-complete.md) pour la documentation détaillée du système de mailing complet.

---

## 📋 Vue d'ensemble

Gestion des emails automatiques envoyés par l'application. Ces emails sont déclenchés par des tâches cron (actuellement Supercronic, migration vers Solid Queue prévue).

**Mailers disponibles** :
- `EventMailer` : Emails liés aux événements et initiations
- `MembershipMailer` : Emails liés aux adhésions
- `UserMailer` : Emails utilisateurs (bienvenue, confirmation, etc.)
- `OrderMailer` : Emails liés aux commandes (optionnel)

---

## 📧 Emails automatiques (déclenchés par cron)

### Emails événements

#### 1. Rappels événements (EventReminderJob)
- **Fréquence** : Tous les jours à 19h
- **Job** : `EventReminderJob` (`app/jobs/event_reminder_job.rb`)
- **Mailer** : `EventMailer.event_reminder(attendance)`
- **Destinataires** : Participants avec `wants_reminder: true`
- **Contenu** : Rappel 24h avant l'événement
- **Note** : Pour les initiations, respecte aussi `wants_initiation_mail`

#### 2. Rapport participants initiation (InitiationParticipantsReportJob)
- **Fréquence** : Tous les jours à 7h (production uniquement)
- **Job** : `InitiationParticipantsReportJob` (`app/jobs/initiation_participants_report_job.rb`)
- **Mailer** : `EventMailer.initiation_participants_report(initiation)`
- **Destinataires** : `contact@grenoble-roller.org` (organisateurs)
- **Contenu** : Liste des participants et matériel demandé pour les initiations du jour
- **Note** : Timing à 7h le jour même car les personnes peuvent s'inscrire jusqu'à la dernière minute

### Emails adhésions

#### 3. Rappels renouvellement (memberships:send_renewal_reminders)
- **Fréquence** : Tous les jours à 9h
- **Tâche** : `memberships:send_renewal_reminders` (Rake task)
- **Mailer** : `MembershipMailer.renewal_reminder(membership)`
- **Destinataires** : Membres dont l'adhésion expire dans 30 jours
- **Contenu** : Rappel pour renouveler l'adhésion

#### 4. Adhésions expirées (memberships:update_expired)
- **Fréquence** : Tous les jours à minuit (00:00)
- **Tâche** : `memberships:update_expired` (Rake task)
- **Mailer** : `MembershipMailer.expired(membership)`
- **Destinataires** : Membres dont l'adhésion vient d'expirer
- **Contenu** : Notification d'expiration d'adhésion

---

## 📨 Mailers disponibles

### EventMailer (`app/mailers/event_mailer.rb`)

1. **`attendance_confirmed(attendance)`**
   - Envoyé lors de l'inscription à un événement
   - Déclenchement : Action utilisateur (création d'attendance)
   - Sujet : "✅ Inscription confirmée - [Nom événement]"

2. **`attendance_cancelled(user, event)`**
   - Envoyé lors de la désinscription d'un événement
   - Déclenchement : Action utilisateur (suppression d'attendance)
   - Sujet : "❌ Désinscription confirmée - [Nom événement]"

3. **`event_reminder(attendance)`** ⏰ **AUTOMATIQUE**
   - Rappel 24h avant l'événement
   - Déclenchement : `EventReminderJob` (19h veille)
   - Sujet : "📅 Rappel : [Nom événement] demain !"

4. **`event_rejected(event)`**
   - Notification au créateur quand un événement est refusé
   - Déclenchement : Action admin (rejet événement)
   - Sujet : "❌ Votre événement \"[Nom]\" a été refusé"

5. **`waitlist_spot_available(waitlist_entry)`**
   - Notification quand une place se libère en liste d'attente
   - Déclenchement : Action utilisateur (désinscription libère une place)
   - Sujet : "🎉 Place disponible - [Nom événement]"

6. **`initiation_participants_report(initiation)`** 📋 **AUTOMATIQUE**
   - Rapport des participants et matériel pour une initiation
   - Déclenchement : `InitiationParticipantsReportJob` (7h jour même)
   - Destinataire : `contact@grenoble-roller.org`
   - Sujet : "📋 Rapport participants - Initiation [Date]"

### MembershipMailer (`app/mailers/membership_mailer.rb`)

1. **`activated(membership)`**
   - Envoyé quand une adhésion est activée (paiement confirmé)
   - Déclenchement : Paiement confirmé (HelloAsso sync)
   - Sujet : "✅ Adhésion Saison [X] - Bienvenue !"

2. **`expired(membership)`** ⏰ **AUTOMATIQUE**
   - Envoyé quand une adhésion expire
   - Déclenchement : `memberships:update_expired` (minuit)
   - Sujet : "⏰ Adhésion Saison [X] - Expirée"

3. **`renewal_reminder(membership)`** ⏰ **AUTOMATIQUE**
   - Rappel 30 jours avant expiration
   - Déclenchement : `memberships:send_renewal_reminders` (9h)
   - Sujet : "🔄 Renouvellement d'adhésion - Dans 30 jours"

4. **`payment_failed(membership)`**
   - Envoyé quand un paiement échoue
   - Déclenchement : Échec de paiement (HelloAsso)
   - Sujet : "❌ Paiement adhésion Saison [X] - Échec"

---

## 🔄 Migration vers Solid Queue

Lors de la migration vers Solid Queue, les tâches Rake seront remplacées par des ActiveJob :

- `helloasso:sync_payments` → `SyncHelloAssoPaymentsJob`
- `memberships:update_expired` → `UpdateExpiredMembershipsJob`
- `memberships:send_renewal_reminders` → `SendRenewalRemindersJob`
- `EventReminderJob` : Existe déjà (pas de changement)
- `InitiationParticipantsReportJob` : Existe déjà (pas de changement)

**Référence** : 
- Plan de migration cron → Solid Queue : Voir [`docs/development/cron/CRON.md`](../../../development/cron/CRON.md) (section "Migration vers Solid Queue")
- Documentation mailing complète : Voir `docs/development/Mailing/mailing-system-complete.md`

---

## 📊 Monitoring

### Logs des emails

Les emails sont envoyés via Active Job (asynchrone), donc :
- Les logs d'envoi sont dans les logs Rails standard
- Les erreurs sont loggées avec Sentry (si configuré)
- Les jobs échoués apparaîtront dans Mission Control après migration

### Vérifier les emails envoyés

```bash
# Logs Rails (emails enqueued)
docker logs grenoble-roller-staging | grep -i "mailer"

# Logs des jobs cron (déclencheurs)
docker exec grenoble-roller-staging tail -f log/cron.log
```

### Tester un email manuellement

```bash
# Test EventMailer
docker exec grenoble-roller-staging rails runner "attendance = Attendance.find(X); EventMailer.event_reminder(attendance).deliver_now"

# Test MembershipMailer
docker exec grenoble-roller-staging rails runner "membership = Membership.find(X); MembershipMailer.renewal_reminder(membership).deliver_now"
```

---

## 📝 Notes importantes

- **Configuration SMTP** : Voir `config/environments/production.rb` et `config/environments/development.rb`
- **From** : Tous les emails partent de `Grenoble Roller <no-reply@grenoble-roller.org>` (configuré dans `ApplicationMailer`)
- **Host** : Les liens dans les emails utilisent `MAILER_HOST` et `MAILER_PROTOCOL` (environnement)
- **Asynchrone** : Tous les emails sont envoyés via `deliver_later` (Active Job) pour ne pas bloquer les requêtes
- **Timezone** : Tous les horaires sont en `Europe/Paris` (configuré dans `config/application.rb`)

---

**Retour** : [INDEX principal](../../INDEX.md)
