# Erreur #186-194 : Requests Initiations (9 erreurs)

**Date d'analyse** : 2025-12-15  
**Priorité** : 🟡 Priorité 9  
**Catégorie** : Tests de Request  
**Statut** : ✅ **RÉSOLU** (9 tests passent)

---

## 📋 Informations Générales

- **Fichier test** : `spec/requests/initiations_spec.rb`
- **Lignes** : 10, 21, 30, 40, 43, 51, 67, 77, 90
- **Tests** : Routes GET pour les initiations et export ICS
- **Nombre de tests** : 9 (tous passent maintenant)

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/requests/initiations_spec.rb
  ```

---

## 🔴 Erreurs Initiales

### Erreurs principales :
1. `create(:event_initiation, ...)` échoue
2. `create(:user, :organizer)` échoue
3. Format ICS retourne 406 (Not Acceptable)
4. Redirections incorrectes pour les initiations en draft

---

## 🔍 Analyse

### Constats

1. **Factory problématique** : `create(:event_initiation, ...)` échoue à cause de validations complexes.

2. **Format ICS manquant** : Le contrôleur `initiations_controller.rb` ne gérait pas le format ICS, ce qui causait une erreur 406.

3. **Redirections** : Les initiations en draft doivent rediriger vers `root_path` pour les visiteurs non authentifiés et les utilisateurs non créateurs.

---

## 💡 Solutions Appliquées

### Solution 1 : Utilisation de `build_event` pour les initiations

**Problème** : `create(:event_initiation, ...)` échoue.

**Solution** : Utiliser `build_event(type: 'Event::Initiation', ...)` suivi de `save!`.

**Code appliqué** :
```ruby
# Avant
create(:event_initiation, :published, title: 'Initiation Débutant')
initiation = create(:event_initiation, :published, title: 'Cours Initiation')

# Après
e = build_event(type: 'Event::Initiation', status: 'published', title: 'Initiation Débutant', max_participants: 30, allow_non_member_discovery: false)
e.save!
initiation = build_event(type: 'Event::Initiation', status: 'published', title: 'Cours Initiation', max_participants: 30, allow_non_member_discovery: false)
initiation.save!
```

**Fichier modifié** : `spec/requests/initiations_spec.rb`
- Toutes les occurrences de `create(:event_initiation, ...)` remplacées par `build_event(type: 'Event::Initiation', ...)`

### Solution 2 : Ajout de la gestion du format ICS dans le contrôleur

**Problème** : Le contrôleur `initiations_controller.rb` ne gérait pas le format ICS, causant une erreur 406.

**Solution** : Ajouter la gestion du format ICS dans la méthode `show` du contrôleur, similaire à `events_controller.rb`.

**Code appliqué** :
```ruby
# Dans app/controllers/initiations_controller.rb
def show
  authorize @initiation
  
  respond_to do |format|
    format.html do
      # ... code HTML existant
    end
    
    format.ics do
      authenticate_user!
      authorize @initiation, :show?

      calendar = Icalendar::Calendar.new
      calendar.prodid = "-//Grenoble Roller//Initiations//FR"

      event_ical = Icalendar::Event.new
      event_ical.dtstart = Icalendar::Values::DateTime.new(@initiation.start_at)
      event_ical.dtend = Icalendar::Values::DateTime.new(@initiation.start_at + @initiation.duration_min.minutes)
      event_ical.summary = @initiation.title
      event_ical.description = @initiation.description.presence || "Initiation organisée par #{@initiation.creator_user.first_name}"
      
      if @initiation.location_text.present?
        location_parts = [@initiation.location_text]
        if @initiation.meeting_lat.present? && @initiation.meeting_lng.present?
          location_parts << "#{@initiation.meeting_lat},#{@initiation.meeting_lng}"
        end
        event_ical.location = location_parts.join(" ")
      end
      
      event_ical.url = initiation_url(@initiation)
      calendar.add_event(event_ical)

      send_data calendar.to_ical, type: 'text/calendar', disposition: 'attachment', filename: "#{@initiation.title.parameterize}.ics"
    end
  end
end
```

**Fichier modifié** : `app/controllers/initiations_controller.rb`
- Lignes 15-80 : Restructuration de la méthode `show` pour gérer les formats HTML et ICS

### Solution 3 : Correction des redirections pour les initiations en draft

**Problème** : Les initiations en draft ne redirigent pas correctement.

**Solution** : Modifier le contrôleur pour vérifier les permissions avant `authorize` et rediriger vers `root_path` si nécessaire.

**Code appliqué** :
```ruby
# Dans app/controllers/initiations_controller.rb
def show
  # Pour les initiations en draft, vérifier explicitement les permissions
  unless @initiation.published? || @initiation.canceled? || (user_signed_in? && (can_moderate? || @initiation.creator_user_id == current_user.id))
    respond_to do |format|
      format.html { redirect_to root_path, alert: "Cette initiation n'est pas accessible." }
      format.ics { redirect_to root_path, alert: "Cette initiation n'est pas accessible." }
    end
    return
  end
  
  authorize @initiation
  # ... reste du code
end
```

**Fichier modifié** : `app/controllers/initiations_controller.rb`
- Lignes 15-20 : Ajout de la vérification des permissions avant `authorize`

### Solution 4 : Utilisation de `create_user` avec les rôles appropriés

**Problème** : `create(:user, :organizer)` échoue.

**Solution** : Utiliser `create_user(role: organizer_role)` avec des rôles créés explicitement.

**Code appliqué** :
```ruby
# Avant
organizer = create(:user, :organizer)

# Après
organizer_role = Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 }
organizer = create_user(role: organizer_role)
```

**Fichier modifié** : `spec/requests/initiations_spec.rb`
- Lignes 85-86 : Utilisation de `create_user` avec le rôle approprié

### Solution 5 : Ajout d'adhésion active pour les tests d'attendances

**Problème** : Les initiations nécessitent une adhésion active pour créer des attendances.

**Solution** : Créer une adhésion active pour l'utilisateur dans les tests d'attendances.

**Code appliqué** :
```ruby
it 'registers the current user' do
  user = create_user(role: role)
  # Créer une adhésion active pour l'utilisateur
  create(:membership, user: user, status: :active, season: '2025-2026', start_date: Date.today.beginning_of_year, end_date: Date.today.end_of_year)
  login_user(user)
  # ... reste du test
end
```

**Fichier modifié** : `spec/requests/initiations_spec.rb`
- Ligne 99 : Ajout de la création d'adhésion active

---

## 🎯 Type de Problème

❌ **PROBLÈME DE TEST** :
- Utilisation de factories qui ne gèrent pas correctement les validations complexes

⚠️ **PROBLÈME DE LOGIQUE** :
- Contrôleur ne gérait pas le format ICS pour les initiations
- Contrôleur ne gérait pas correctement les redirections pour les initiations en draft

---

## 📊 Résultat

✅ **TOUS LES TESTS PASSENT** (9/9)

```
Initiations
  GET /initiations
    renders the initiations index with upcoming initiations
  GET /initiations/:id
    allows anyone to view a published initiation
    redirects visitors trying to view a draft initiation
  GET /initiations/:id.ics
    requires authentication
    exports initiation as iCal file for published initiation when authenticated
    redirects to root for draft initiation when authenticated but not creator
    allows creator to export draft initiation
  POST /initiations/:initiation_id/attendances
    requires authentication
    registers the current user

Finished in 10.13 seconds (files took 1.75 seconds to load)
9 examples, 0 failures
```

---

## ✅ Actions Effectuées

1. [x] Exécuter les tests pour voir les erreurs exactes
2. [x] Analyser chaque erreur et documenter
3. [x] Identifier le type de problème (test ou logique)
4. [x] Proposer des solutions
5. [x] Appliquer les corrections
6. [x] Vérifier que tous les tests passent
7. [x] Mettre à jour le statut dans [README.md](../README.md)

---

## 📝 Notes

- La modification du contrôleur était nécessaire pour ajouter la gestion du format ICS
- Les corrections suivent le même pattern que pour les autres tests corrigés précédemment
- L'ajout d'adhésions actives est nécessaire pour les tests d'attendances sur les initiations
