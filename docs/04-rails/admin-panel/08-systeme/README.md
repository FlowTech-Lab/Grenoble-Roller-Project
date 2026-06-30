# ⚙️ SYSTÈME - Plan d'Implémentation

**Priorité** : 🟡 MOYENNE | **Phase** : 8 | **Semaine** : 8+

---

## 📋 Vue d'ensemble

Gestion système : paiements, **notifications Discord (webhooks admin)** — voir [DR-002](../../10-decisions-and-changelog/DR-002-discord-webhook-notifications.md).

**Status actuel** : ✅ Payments dans AdminPanel · ✅ Notification channels **implémenté** (DR-002, 2026-06-09)

**Note** : 
- **Maintenance** → Géré dans [`00-dashboard/`](../00-dashboard/README.md)
- **AuditLogs** → Non prioritaire (peu utilisé)

---

## 📄 Documentation

### **📁 Fichiers détaillés par type (CODE EXACT)**
- [`01-migrations.md`](./01-migrations.md) - Migrations (code exact)
- [`02-modeles.md`](./02-modeles.md) - Modèles (code exact)
- [`03-services.md`](./03-services.md) - Services (code exact)
- [`04-controllers.md`](./04-controllers.md) - Controllers (code exact)
- [`05-routes.md`](./05-routes.md) - Routes (code exact)
- [`06-policies.md`](./06-policies.md) - Policies (code exact)
- [`07-vues.md`](./07-vues.md) - Vues ERB (code exact)
- [`08-javascript.md`](./08-javascript.md) - JavaScript (code exact)

### **📁 Fichiers par fonctionnalité**
- [`paiements.md`](./paiements.md) - Gestion paiements

---

## 🎯 Fonctionnalités Incluses

### ✅ Payments (Paiements)
- Liste avec filtres (provider, status, date)
- Détails avec panels (Orders, Memberships, Attendances associés)
- CRUD complet

### ✅ Notification channels (Discord webhooks) — DR-002

- CRUD webhooks Discord (SUPERADMIN ≥ 70) — `/admin-panel/notification-channels`
- Toggles par type d'événement (~65 clés), bouton test, échantillons QA, multi-canaux
- Dispatch après confirmation paiement HelloAsso (pas callbacks modèle)
- Gate staging : `ALLOW_DISCORD_NOTIFICATIONS=true`
- Spec : [DR-002-discord-webhook-notifications.md](../../10-decisions-and-changelog/DR-002-discord-webhook-notifications.md)

---

## ✅ Checklist Globale

### **Phase 8 (Semaine 8+)**
- [x] Controller Payments ✅ **IMPLÉMENTÉ** (index, show, destroy)
- [x] Policy Payments ✅ **IMPLÉMENTÉE** (index/show: level >= 60, destroy: level >= 70 ⚠️)
- [x] Routes Payments ✅ **IMPLÉMENTÉES** (RESTful)
- [x] Vues Payments ✅ **IMPLÉMENTÉES** (index avec filtres Ransack, show avec panels, boutons groupés)
- [x] Menu sidebar ✅ **AJOUTÉ** (sous-menu Commandes)
- [x] Tests RSpec ✅ **22 exemples, 0 échecs**
- [x] Factory Payment ✅ **CRÉÉE**
- [x] Sécurité ✅ **RENFORCÉE** (suppression SUPERADMIN uniquement + disclaimer explicite)

### **Notification channels (DR-002 — 2026-06-09)**
- [x] Migration `notification_channels`, `notification_subscriptions`, `notification_deliveries`
- [x] Models + `NotificationDispatchService`, `DiscordWebhookClient`, delivery job
- [x] Admin CRUD + test + sample events (`NotificationChannelsController`)
- [x] Hooks HelloAsso, contact public, registrations, ~18 admin controllers (`AdminPanel::NotifiesDiscord`)
- [x] Menu sidebar **Notifications**
- [x] Tests RSpec (~65+ examples for registry, dispatch, job, admin requests)

---

## 🔗 Dépendances

- **Orders** : Pour afficher commandes liées aux paiements
- **Memberships** : Pour afficher adhésions liées aux paiements
- **Attendances** : Pour afficher participations liées aux paiements

---

## 📊 Estimation

- **Temps** : 1 semaine
- **Complexité** : ⭐⭐⭐
- **Dépendances** : Commandes, Utilisateurs, Événements

---

**Retour** : [INDEX principal](../INDEX.md)
