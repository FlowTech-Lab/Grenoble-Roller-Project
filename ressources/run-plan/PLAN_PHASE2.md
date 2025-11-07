# 🎯 PLAN PHASE 2 - Événements & Admin

**Document unique** : Planning, checklist et pièges à éviter pour Phase 2  
**Date** : Jan 2025  
**État** : Modèles créés ✅ → Tests RSpec ✅ → ActiveAdmin ensuite

---

## 📊 ÉTAT ACTUEL

### ✅ TERMINÉ
- [x] Migrations Phase 2 créées et appliquées (7 migrations)
- [x] Modèles Phase 2 créés (Route, Event, Attendance, OrganizerApplication, Partner, ContactMessage, AuditLog)
- [x] Validations, associations, enums, scopes
- [x] Seeds créés et testés (Phase 2)
- [x] RSpec configuré

### 🔜 EN COURS
- [ ] FactoryBot factories pour tous les modèles Phase 2 (optionnel si helpers suffisants)

### 📅 À VENIR
- [ ] ActiveAdmin (Jour 11, après tests >70%)
- [ ] Customisation ActiveAdmin (Jour 12-13)
- [ ] Tests admin + permissions (Jour 14-15)

---

## ⚠️ PIÈGE CRITIQUE À ÉVITER

### ❌ NE PAS créer contrôleurs/routes manuels avant ActiveAdmin

**Pourquoi ?** ActiveAdmin génère automatiquement :
- Contrôleurs admin (`app/admin/events.rb`, etc.)
- Routes admin (`/admin/events`, `/admin/routes`, etc.)
- Vues admin (index, show, form, filters, bulk actions)

**Si vous créez maintenant** :
```ruby
# app/controllers/events_controller.rb (full CRUD)
# app/controllers/routes_controller.rb (full CRUD)
# + routes.rb resources :events, :routes
# + vues ERB admin
```

**Puis Jour 11** :
```bash
rails generate activeadmin:resource Event Route
# ← Crée les MÊMES contrôleurs (version ActiveAdmin)
# ← Résultat : Duplication complète, travail perdu ❌
```

**✅ Solution** : ActiveAdmin génère TOUT automatiquement. Zéro travail manuel de CRUD admin.

---

## 📅 PLAN DÉTAILLÉ (Jour par jour)

### Jour 5-10 : Tests RSpec COMPLETS (AVANT ActiveAdmin)

#### ✅ Pré-requis vérifiés
- [x] Modèles stables (validations, associations, scopes) ✅
- [x] Migrations appliquées ✅
- [x] Seeds créés et testés ✅

#### ✅ Réalisé
- [x] **Tests RSpec models complets** :
  - `spec/models/route_spec.rb` (validations name, distance_km, elevation_m, difficulty)
  - `spec/models/event_spec.rb` (validations title, description, start_at, duration_min, status, scopes)
  - `spec/models/attendance_spec.rb` (associations user, event, payment, validations)
  - `spec/models/organizer_application_spec.rb` (workflow status, associations)
  - `spec/models/partner_spec.rb` (validations, associations)
  - `spec/models/contact_message_spec.rb` (validations)
  - `spec/models/audit_log_spec.rb` (validations, associations, scopes)

- [x] **Tests edge cases** (validations négatives, associations invalides)
- [x] **Coverage >70%** ← **OBLIGATOIRE AVANT ActiveAdmin** *(modèle specs : 75 exemples, 0 échec)*

**Vérification** :
```bash
rspec spec/models
# ✅ 75 examples, 0 failures
# ✅ Coverage >70%
```

---

### Jour 11 : Installation ActiveAdmin

#### ⚠️ Pré-requis OBLIGATOIRES
- [x] Modèles 100% stables ✅
- [x] Migrations appliquées ✅
- [x] Seeds testés ✅
- [ ] **Tests RSpec >70% coverage** ← **OBLIGATOIRE**

#### Installation
- [ ] `bundle add activeadmin devise`
- [ ] `rails generate activeadmin:install --skip-users`
- [ ] Config `app/admin/application.rb` (authentication_method, PunditAdapter)
- [ ] Generate resources :
  ```bash
  rails g activeadmin:resource Event Route User Attendance Product Order OrganizerApplication Partner ContactMessage AuditLog
  ```

#### ✅ ActiveAdmin génère automatiquement
- Contrôleurs admin (`app/admin/events.rb`, `app/admin/routes.rb`, etc.)
- Routes admin (`/admin/events`, `/admin/routes`, `/admin/attendances`, etc.)
- Vues admin (index, show, form, filters, bulk actions)
- **ZÉRO travail manuel de CRUD admin** ✅

---

### Jour 12-13 : Customisation ActiveAdmin

- [ ] Configurer colonnes visibles (index, show, form)
- [ ] Filtres simples (email, role, created_at, status, date) - utilisables par bénévoles
- [ ] Bulk actions (sélectionner 10 événements = modifier status en 1 clic)
- [ ] Export CSV/PDF intégré (out-of-the-box)
- [ ] Dashboard validation organisateurs
- [ ] Actions personnalisées (validate_organizer!, publish_event, cancel_event)

---

### Jour 14-15 : Tests Admin & Finalisation

- [ ] Tests admin controllers (RSpec)
- [ ] Integration tests (admin actions via Capybara)
- [ ] Permissions Pundit testées
- [ ] Coverage >70% maintenu
- [ ] Audit sécurité (Brakeman)
- [ ] Optimisation requêtes (N+1 queries)

---

## 📋 CHECKLIST RAPIDE

### Modèles Phase 2
- [x] Route ✅
- [x] Event ✅
- [x] Attendance ✅
- [x] OrganizerApplication ✅
- [x] Partner ✅
- [x] ContactMessage ✅
- [x] AuditLog ✅

### Tests RSpec
- [x] Route (validations, associations)
- [x] Event (validations, associations, scopes)
- [x] Attendance (validations, associations)
- [x] OrganizerApplication (validations, workflow)
- [x] Partner (validations)
- [x] ContactMessage (validations)
- [x] AuditLog (validations, associations, scopes)
- [x] Coverage >70%

### ActiveAdmin (Jour 11+)
- [ ] Installation
- [ ] Resources générés
- [ ] Customisation (filtres, bulk actions, exports)
- [ ] Tests admin
- [ ] Permissions Pundit

---

## 🎯 PROCHAINES ÉTAPES

1. **MAINTENANT** : Préparer l'installation d'ActiveAdmin (vérifier prérequis, planifier génération)
2. **Jour 11** : Installer ActiveAdmin (génère automatiquement tout)
3. **Jour 12-13** : Customiser ActiveAdmin
4. **Jour 14-15** : Tests admin + finalisation

---

## 📚 RESSOURCES

- **Schema DB** : `ressources/db/dbdiagram.md`
- **Documentation modèles** : `docs/03-architecture/domain/models.md`
- **Migrations Phase 2** : `docs/04-rails/phase2-migrations-models.md`
- **Guide technique** : `GUIDE_IMPLEMENTATION.md`

---

**Document créé le** : 2025-01-20  
**Version** : 1.0 (Document unique simplifié)

