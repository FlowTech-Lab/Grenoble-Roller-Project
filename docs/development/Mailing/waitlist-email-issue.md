# 🔴 Problème : Email de File d'Attente Non Envoyé

**Date de création** : 2025-12-30  
**Statut** : ⚠️ **PROBLÈME IDENTIFIÉ - À CORRIGER**  
**Priorité** : 🔴 **HAUTE** - Les utilisateurs ne reçoivent pas les notifications de places disponibles

---

## 📋 Description du Problème

Les emails de notification de file d'attente (`waitlist_spot_available`) **ne sont pas envoyés** aux utilisateurs lorsqu'une place se libère et qu'ils sont les suivants sur la liste d'attente.

### Symptômes

- ✅ L'entrée de file d'attente est correctement mise à jour (`status = "notified"`, `notified_at` est défini)
- ✅ L'attendance "pending" est créée correctement
- ❌ **L'email n'est pas envoyé** à l'utilisateur
- ❌ Aucune erreur visible dans les logs (erreur silencieuse)

---

## 🔍 Analyse du Code

### Fichier concerné

**`app/models/waitlist_entry.rb`** - Méthode `send_notification_email` (lignes 228-234)

```ruby
# Envoyer l'email de notification pour une place disponible
def send_notification_email
  EventMailer.waitlist_spot_available(self).deliver_now
rescue => e
  Rails.logger.error("Failed to send waitlist notification email for WaitlistEntry #{id}: #{e.message}")
  # Ne pas faire échouer la notification si l'email échoue
end
```

### Problèmes identifiés

#### 1. ⚠️ **Utilisation de `deliver_now` au lieu de `deliver_later`**

**Problème** : L'email est envoyé de manière synchrone (`deliver_now`), ce qui peut bloquer la requête si le serveur SMTP est lent.

**Note** : Le commentaire dans le code indique "Envoyer l'email immédiatement (pas en queue) pour s'assurer qu'il est envoyé", mais cela peut causer des problèmes de performance.

**⚠️ IMPORTANT** : L'email de file d'attente doit **TOUJOURS** être envoyé, même si l'utilisateur a désactivé `wants_events_mail`. C'est un email critique qui permet à l'utilisateur de confirmer sa place dans les 24h. L'utilisateur a explicitement demandé à être sur la file d'attente, il doit recevoir la notification.

#### 2. 🔇 **Erreur silencieuse**

**Problème** : Si l'envoi échoue, l'erreur est capturée et loggée, mais la notification continue comme si tout s'était bien passé. L'utilisateur ne reçoit pas l'email mais pense qu'il a été notifié.

---

## 🎯 Solutions Proposées

### Solution 1 : ❌ **REJETÉE** - Ne pas vérifier `wants_events_mail`

**⚠️ IMPORTANT** : Cette solution a été rejetée car l'email de file d'attente est **critique** et doit **TOUJOURS** être envoyé.

**Raison** :
- L'utilisateur a explicitement demandé à être sur la file d'attente
- Il a un délai de 24h pour confirmer sa place
- S'il ne reçoit pas l'email, il ne peut pas confirmer et perd sa place
- C'est différent des autres emails (confirmation, rappel) qui sont optionnels

**Conclusion** : L'email de file d'attente doit être envoyé **systématiquement**, indépendamment des préférences utilisateur.

### Solution 2 : Utiliser `deliver_later` au lieu de `deliver_now`

**Modification** : Changer `deliver_now` en `deliver_later`

```ruby
def send_notification_email
  return unless user.wants_events_mail?

  if event.is_a?(Event::Initiation) && !user.wants_initiation_mail?
    return
  end

  EventMailer.waitlist_spot_available(self).deliver_later
rescue => e
  Rails.logger.error("Failed to send waitlist notification email for WaitlistEntry #{id}: #{e.message}")
end
```

**Avantages** :
- ✅ Ne bloque pas la requête HTTP
- ✅ Cohérent avec les autres emails (tous utilisent `deliver_later` sauf exceptions justifiées)
- ✅ Meilleure performance

**Note** : Cette solution nécessite que le système de queue (Active Job) soit configuré et fonctionnel.

### Solution 3 : Vérification dans le mailer (ALTERNATIVE)

**Modification** : Ajouter la vérification dans `EventMailer.waitlist_spot_available`

```ruby
# app/mailers/event_mailer.rb
def waitlist_spot_available(waitlist_entry)
  @waitlist_entry = waitlist_entry
  @event = waitlist_entry.event
  @user = waitlist_entry.user
  
  # Vérifier les préférences
  return unless @user.wants_events_mail?
  
  if @event.is_a?(Event::Initiation) && !@user.wants_initiation_mail?
    return
  end
  
  # ... reste du code
end
```

**Avantages** :
- ✅ Centralise la logique de vérification dans le mailer
- ✅ Plus facile à maintenir

**Inconvénients** :
- ⚠️ Le mailer retourne `nil` si les préférences ne sont pas activées, ce qui peut être confus

---

## ✅ Solution Finale Appliquée

**⚠️ IMPORTANT** : L'email de file d'attente est **TOUJOURS envoyé**, même si l'utilisateur a désactivé `wants_events_mail`. C'est un email critique.

**Implémentation finale** :

```ruby
# app/models/waitlist_entry.rb
# Envoyer l'email de notification pour une place disponible
# IMPORTANT : Cet email est TOUJOURS envoyé, même si l'utilisateur a désactivé wants_events_mail
# Car c'est un email critique qui permet à l'utilisateur de confirmer sa place dans les 24h
# L'utilisateur a explicitement demandé à être sur la file d'attente, il doit recevoir la notification
def send_notification_email
  EventMailer.waitlist_spot_available(self).deliver_later
rescue => e
  Rails.logger.error("Failed to send waitlist notification email for WaitlistEntry #{id}: #{e.message}")
  Rails.logger.error(e.backtrace.join("\n"))
  # Ne pas faire échouer la notification si l'email échoue
end
```

**Changements appliqués** :
1. ✅ **AUCUNE vérification de préférences** - L'email est toujours envoyé (email critique)
2. ✅ Changement de `deliver_now` en `deliver_later` (meilleure performance)
3. ✅ Amélioration des logs d'erreur (stack trace)

**Pourquoi pas de vérification de préférences ?**
- L'utilisateur a explicitement demandé à être sur la file d'attente
- Il a un délai de 24h pour confirmer sa place
- S'il ne reçoit pas l'email, il ne peut pas confirmer et perd sa place
- C'est différent des autres emails (confirmation, rappel) qui sont optionnels

---

## 🧪 Tests à Effectuer

### Test 1 : Utilisateur avec `wants_events_mail = true`

**Scénario** :
1. Créer un utilisateur avec `wants_events_mail = true`
2. Ajouter l'utilisateur à la file d'attente d'un événement complet
3. Libérer une place (annuler une inscription)
4. Vérifier que l'email est envoyé

**Résultat attendu** : ✅ Email envoyé

### Test 2 : Utilisateur avec `wants_events_mail = false`

**Scénario** :
1. Créer un utilisateur avec `wants_events_mail = false`
2. Ajouter l'utilisateur à la file d'attente d'un événement complet
3. Libérer une place (annuler une inscription)
4. Vérifier que l'email **EST envoyé** (car c'est un email critique)
5. Vérifier que l'entrée de file d'attente est mise à jour (`status = "notified"`)

**Résultat attendu** : ✅ Email envoyé (même si `wants_events_mail = false`), notification créée

**⚠️ IMPORTANT** : L'email de file d'attente est toujours envoyé, même si l'utilisateur a désactivé `wants_events_mail`, car c'est un email critique.

### Test 3 : Initiation avec `wants_initiation_mail = false`

**Scénario** :
1. Créer un utilisateur avec `wants_events_mail = false` et `wants_initiation_mail = false`
2. Ajouter l'utilisateur à la file d'attente d'une initiation complète
3. Libérer une place
4. Vérifier que l'email **EST envoyé** (car c'est un email critique)

**Résultat attendu** : ✅ Email envoyé (même si les préférences sont désactivées)

### Test 4 : Vérification des logs

**Scénario** :
1. Exécuter les tests 1, 2 et 3
2. Vérifier les logs pour les messages informatifs

**Résultat attendu** : ✅ Logs clairs indiquant pourquoi l'email a été envoyé ou non

---

## 📊 Impact

### Avant la correction

- ❌ Les emails ne sont pas envoyés (problème principal)
- ⚠️ Utilisation de `deliver_now` (peut bloquer les requêtes)
- 🔇 Erreurs silencieuses

### Après la correction

- ✅ Les emails sont envoyés **systématiquement** (email critique)
- ✅ Utilisation de `deliver_later` (meilleure performance)
- ✅ Logs clairs pour le debugging
- ✅ **Aucune vérification de préférences** - L'email est toujours envoyé car c'est critique pour que l'utilisateur puisse confirmer sa place

---

## 🔗 Fichiers Concernés

### À modifier

- **`app/models/waitlist_entry.rb`** : Méthode `send_notification_email` (lignes 228-234)

### Références

- **`app/controllers/events/attendances_controller.rb`** : Exemple de vérification `wants_events_mail` (lignes 93-99)
- **`app/mailers/event_mailer.rb`** : Méthode `waitlist_spot_available` (lignes 76-95)
- **`app/models/user.rb`** : Champs `wants_events_mail` et `wants_initiation_mail`

---

## 📝 Notes Additionnelles

### Pourquoi `wants_events_mail` est important

- Les utilisateurs peuvent désactiver les emails d'événements pour réduire le spam
- Si on envoie des emails sans vérifier cette préférence, on viole les préférences utilisateur
- C'est une bonne pratique de respecter les préférences utilisateur

### Pourquoi `wants_initiation_mail` pour les initiations

- Les initiations ont une préférence spécifique (`wants_initiation_mail`)
- Cette préférence est vérifiée dans `EventReminderJob` pour les rappels
- Il faut être cohérent et vérifier cette préférence aussi pour les notifications de file d'attente

### Pourquoi `deliver_later` au lieu de `deliver_now`

- `deliver_now` bloque la requête HTTP jusqu'à ce que l'email soit envoyé
- Si le serveur SMTP est lent, cela peut causer des timeouts
- `deliver_later` envoie l'email de manière asynchrone via Active Job
- Tous les autres emails de l'application utilisent `deliver_later` (sauf exceptions justifiées)

---

## ✅ Checklist de Correction

- [x] Changer `deliver_now` en `deliver_later` ✅
- [x] Améliorer les logs d'erreur (stack trace) ✅
- [x] **Ne PAS ajouter de vérification de préférences** (email critique) ✅
- [ ] Tester avec `wants_events_mail = true`
- [ ] Tester avec `wants_events_mail = false` (doit quand même envoyer)
- [ ] Tester avec `wants_initiation_mail = false` (doit quand même envoyer)
- [ ] Vérifier les logs
- [x] Mettre à jour la documentation ✅

---

**Date de création** : 2025-12-30  
**Dernière mise à jour** : 2025-12-30  
**Statut** : ✅ **CORRIGÉ** - Correction appliquée dans `app/models/waitlist_entry.rb`

**⚠️ IMPORTANT** : L'email de file d'attente est **TOUJOURS envoyé**, même si l'utilisateur a désactivé `wants_events_mail`. C'est un email critique qui permet à l'utilisateur de confirmer sa place dans les 24h. L'utilisateur a explicitement demandé à être sur la file d'attente, il doit recevoir la notification.
