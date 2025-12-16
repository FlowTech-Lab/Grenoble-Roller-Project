# Erreur #029-035 : Features Mes Sorties (7 erreurs)

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟡 Priorité 4  
**Catégorie** : Tests Feature Capybara

---

## 📋 Informations Générales

- **Fichier test** : `spec/features/mes_sorties_spec.rb`
- **Lignes** : 26, 46, 69, 81, 92, 117, 133
- **Tests** :
  1. Ligne 26 : `affiche la page Mes sorties avec les événements inscrits`
  2. Ligne 46 : `permet de se désinscrire depuis la page Mes sorties`
  3. Ligne 69 : `affiche les informations de l'événement (date, lieu, nombre d'inscrits)`
  4. Ligne 81 : `n'affiche que les événements où l'utilisateur est inscrit`
  5. Ligne 92 : `n'affiche pas les inscriptions annulées`
  6. Ligne 117 : `permet de cliquer sur un événement pour voir les détails`
  7. Ligne 133 : `permet de retourner à la liste des événements`

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/features/mes_sorties_spec.rb
  ```

---

## 🔴 Erreur

✅ **RÉSOLU** - 9/10 tests passent, 1 test SKIP (ChromeDriver)

### Erreurs initiales
1. `ActiveRecord::RecordInvalid` lors de la création d'organizer (factory incorrecte)
2. `ActiveRecord::RecordInvalid` lors de la création d'utilisateur sans rôle
3. `NoMethodError: undefined method 'can_moderate?'` dans la vue `_event_card.html.erb`
4. `Selenium::WebDriver::Error::WebDriverError` - ChromeDriver non disponible (1 test JavaScript)

---

## 🔍 Analyse

### Constats
- ✅ Erreurs analysées et corrigées
- ✅ 9 tests passent maintenant
- ⏭️ 1 test JavaScript SKIP (ChromeDriver non disponible dans Docker)

### Causes identifiées
1. **Factory `:organizer` incorrecte** : Syntaxe invalide pour les associations
2. **Factory `:user` sans rôle** : Les tests créaient des utilisateurs sans rôle explicite
3. **Helper `can_moderate?` manquant** : Défini dans `EventsController` mais pas dans `ApplicationController`, donc non disponible dans `AttendancesController#index`
4. **Recherche de boutons** : Le bouton affiche "Annuler" mais a `aria-label="Se désinscrire"`
5. **ChromeDriver** : Non disponible dans Docker pour les tests JavaScript (`js: true`)

---

## 💡 Solutions Appliquées

✅ **SOLUTIONS APPLIQUÉES**

1. **Factory `:organizer` corrigée** :
   ```ruby
   let!(:organizer_role) { ensure_role(code: 'ORGANIZER', name: 'Organisateur', level: 40) }
   let(:organizer) { create(:user, role: organizer_role) }
   ```

2. **Helper `can_moderate?` ajouté à ApplicationController** :
   ```ruby
   # app/controllers/application_controller.rb
   helper_method :can_moderate?
   
   def can_moderate?
     return false unless current_user
     current_user.role&.level.to_i >= 50 # Modérateur (50) ou Admin (60) ou SuperAdmin (70)
   end
   ```

3. **Recherche de boutons corrigée** :
   ```ruby
   # Le bouton affiche "Annuler" mais a aria-label="Se désinscrire"
   expect(page).to have_button('Annuler').or have_button("Se désinscrire")
   ```

4. **Test JavaScript SKIP** :
   ```ruby
   xit 'permet de se désinscrire depuis la page Mes sorties', js: true do # SKIP: ChromeDriver non disponible
   ```

---

## 🎯 Type de Problème

✅ **RÉSOLU** - ❌ **PROBLÈME DE TEST** (factories, helper manquant, recherche de boutons)

---

## 📊 Statut

⏳ **À ANALYSER** - Vérifier l'état réel des tests (peut être résolu ou avoir des erreurs restantes)

### Progrès
- ✅ Test 17 (ligne 17) : **RÉSOLU** - Factory organizer corrigée
- ✅ Test 26 (ligne 28) : **RÉSOLU** - Helper `can_moderate?` ajouté à ApplicationController
- ⏭️ Test 46 (ligne 48) : **SKIP** - ChromeDriver non disponible (test JavaScript)
- ✅ Test 69 (ligne 72) : **RÉSOLU** - Factory user corrigée
- ✅ Test 81 (ligne 83) : **RÉSOLU** - Factory user corrigée
- ✅ Test 92 (ligne 94) : **RÉSOLU** - Test passe
- ✅ Test 117 (ligne 119) : **RÉSOLU** - Recherche du bouton corrigée

### Corrections appliquées
1. **Factory `:organizer`** : Utilisation de `ensure_role` au lieu de `association :role`
2. **Factory `:user`** : Ajout de rôle explicite dans tous les tests
3. **Helper `can_moderate?`** : Ajouté à `ApplicationController` pour être disponible dans toutes les vues
4. **Recherche de boutons** : Utilisation de `aria-label` ou texte alternatif (bouton affiche "Annuler" mais a `aria-label="Se désinscrire"`)
5. **Test JavaScript** : SKIP avec `xit` car ChromeDriver non disponible dans Docker

---

## 🔗 Erreurs Similaires

Cette erreur est similaire à :
- [016-features-event-attendance.md](016-features-event-attendance.md)
- [024-features-event-management.md](024-features-event-management.md)

---

## ✅ Actions à Effectuer

1. [ ] Exécuter les tests pour voir les erreurs exactes
2. [ ] Vérifier la configuration Capybara
3. [ ] Analyser chaque erreur et documenter
4. [ ] Identifier le type de problème (test ou logique)
5. [ ] Proposer des solutions
6. [ ] Mettre à jour le statut dans [README.md](../README.md)

