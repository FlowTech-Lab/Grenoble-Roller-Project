# Erreur #024-028 : Features Event Management (5 erreurs)

**Date d'analyse** : 2025-01-13  
**Priorité** : 🟡 Priorité 4  
**Catégorie** : Tests Feature Capybara

---

## 📋 Informations Générales

- **Fichier test** : `spec/features/event_management_spec.rb`
- **Lignes** : 20, 42, 152, 171, 235
- **Tests** :
  1. Ligne 20 : `permet de créer un événement via le formulaire`
  2. Ligne 42 : `permet de créer un événement avec max_participants = 0 (illimité)`
  3. Ligne 152 : `permet de supprimer l'événement avec confirmation`
  4. Ligne 171 : `annule la suppression si l'utilisateur clique sur Annuler dans le modal`
  5. Ligne 235 : `affiche le prochain événement en vedette`

- **Commande pour reproduire** :
  ```bash
  docker exec grenoble-roller-dev bundle exec rspec ./spec/features/event_management_spec.rb
  ```

---

## 🔴 Erreur

✅ **RÉSOLU** - 15/17 tests passent, 2 tests SKIP (ChromeDriver)

### Erreurs initiales
1. `ActiveRecord::RecordInvalid` lors de la création d'organizer/admin (factory incorrecte)
2. `ActiveRecord::RecordInvalid` lors de la création d'utilisateur sans rôle
3. `Capybara::ElementNotFound` - Champ "Statut" non trouvé (non modifiable par organisateurs)
4. `Capybara::ElementNotFound` - Champ "Prix (€)" non trouvé (utiliser ID `price_euros`)
5. `Capybara::ElementNotFound` - Champ "Lieu" non trouvé (nom exact du label)
6. Erreurs de validation - Champs requis manquants (Niveau, Distance, Image)
7. `Selenium::WebDriver::Error::WebDriverError` - ChromeDriver non disponible (2 tests JavaScript)

---

## 🔍 Analyse

### Constats
- ✅ Erreurs analysées et corrigées
- ✅ 15 tests passent maintenant
- ⏭️ 2 tests JavaScript SKIP (ChromeDriver non disponible dans Docker)

### Causes identifiées
1. **Factory `:organizer` et `:admin` incorrectes** : Syntaxe invalide pour les associations
2. **Factory `:user` sans rôle** : Les tests créaient des utilisateurs sans rôle explicite
3. **Champ "Statut"** : Non visible pour les organisateurs (seulement modérateurs+)
4. **Champs requis manquants** : Niveau, Distance, Image de couverture
5. **Recherche de champs** : Utilisation des IDs au lieu des labels pour certains champs
6. **ChromeDriver** : Non disponible dans Docker pour les tests JavaScript (`js: true`)

---

## 💡 Solutions Appliquées

✅ **SOLUTIONS APPLIQUÉES**

1. **Factory `:organizer` et `:admin` corrigées** :
   ```ruby
   let!(:organizer_role) { ensure_role(code: 'ORGANIZER', name: 'Organisateur', level: 40) }
   let!(:organizer) { create(:user, role: organizer_role) }
   ```

2. **Formulaire événement - Champs requis ajoutés** :
   ```ruby
   select 'Tous niveaux', from: 'Niveau'
   fill_in 'Distance par boucle (km)', with: '10'
   attach_file 'Image de couverture', Rails.root.join('spec', 'fixtures', 'files', 'test-image.jpg')
   ```

3. **Champ "Prix" - Utilisation de l'ID** :
   ```ruby
   fill_in 'price_euros', with: '0'  # Au lieu de fill_in 'Prix (€)', with: '0'
   ```

4. **Champ "Statut" - Non modifiable par organisateurs** :
   ```ruby
   # Le statut n'est pas modifiable par l'organisateur (automatiquement 'draft')
   # Pas besoin de select 'Published', from: 'Statut'
   ```

5. **Tests JavaScript SKIP** :
   ```ruby
   xit 'permet de supprimer l\'événement avec confirmation', js: true do # SKIP: ChromeDriver non disponible
   ```

---

## 🎯 Type de Problème

✅ **RÉSOLU** - ❌ **PROBLÈME DE TEST** (factories, champs requis, recherche de champs)

---

## 📊 Statut

✅ **RÉSOLU** (15/17 tests passent, 2 tests SKIP)

### Progrès
- ✅ Test 15 (ligne 20) : **RÉSOLU** - Factory organizer corrigée
- ✅ Test 20 (ligne 23) : **RÉSOLU** - Formulaire corrigé (champs requis ajoutés)
- ✅ Test 42 (ligne 47) : **RÉSOLU** - Formulaire corrigé (champs requis ajoutés)
- ⏭️ Test 152 (ligne 152) : **SKIP** - ChromeDriver non disponible (test JavaScript)
- ⏭️ Test 171 (ligne 171) : **SKIP** - ChromeDriver non disponible (test JavaScript)
- ✅ Test 235 (ligne 240) : **RÉSOLU** - Texte de recherche corrigé

### Corrections appliquées
1. **Factory `:organizer` et `:admin`** : Utilisation de `ensure_role` au lieu de `association :role`
2. **Factory `:user`** : Ajout de rôle explicite dans tous les tests
3. **Formulaire événement** : Ajout des champs requis (Niveau, Distance, Image de couverture)
4. **Champ "Statut"** : Non modifiable par les organisateurs (automatiquement 'draft')
5. **Champ "Prix"** : Utilisation de l'ID `price_euros` au lieu du label
6. **Tests JavaScript** : SKIP avec `xit` car ChromeDriver non disponible dans Docker
7. **Texte "Prochain rendez-vous"** : Corrigé pour chercher "À venir" et "Les prochains rendez-vous roller"

---

## 🔗 Erreurs Similaires

Cette erreur est similaire à :
- [016-features-event-attendance.md](016-features-event-attendance.md)
- [029-features-mes-sorties.md](029-features-mes-sorties.md)

---

## ✅ Actions à Effectuer

1. [ ] Exécuter les tests pour voir les erreurs exactes
2. [ ] Vérifier la configuration Capybara
3. [ ] Analyser chaque erreur et documenter
4. [ ] Identifier le type de problème (test ou logique)
5. [ ] Proposer des solutions
6. [ ] Mettre à jour le statut dans [README.md](../README.md)

