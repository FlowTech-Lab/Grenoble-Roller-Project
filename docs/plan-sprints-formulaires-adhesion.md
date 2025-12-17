# Plan de Sprints – Refacto Formulaires Adhésion + Essai Gratuit

**Périmètre :** Harmonisation formulaires enfant/adulte + renouvellement adulte + essai gratuit enfants  
**Période cible :** ~8–11 jours (en sprints courts)

> 📚 **Index Documentation :** Voir [`INDEX-FORMULAIRES-ADHESION.md`](./INDEX-FORMULAIRES-ADHESION.md) pour la vue d'ensemble  
> 📊 **Analyse Technique :** Voir [`comparatif-complet-formulaires-integration.md`](./comparatif-complet-formulaires-integration.md) pour les détails techniques complets  
> 🔄 **Renouvellement Adulte :** Voir [`comparatif-formulaires-enfant-adulte.md`](./comparatif-formulaires-enfant-adulte.md) section "RENOUVELLEMENT D'ADHÉSION"  
> 🎁 **Essai Gratuit :** Voir [`ESSAI_GRATUIT_ENFANTS.md`](./ESSAI_GRATUIT_ENFANTS.md) pour la spécification complète

---

## Sprint 1 – Backend Formulaires & Bouton Espèces/Chèques (Critique) ✅

### Objectifs
- Unifier la logique backend (`is_child_membership` / `type`).
- Corriger le flux "Espèces / Chèques" adulte pour qu’il ne déclenche plus HelloAsso.

### Modifications supplémentaires
- Suppression des blocs de progression (stepper) dans les deux formulaires pour réduire l'encombrement visuel.
- Centrage des badges "Saison" et "Dates" dans le Hero.

### Tâches

#### 1.1 Unification champs cachés
- [x] **S1-T1** (todo `phase1-1-1`) – Analyser `is_child_membership` vs `type` dans `memberships_controller.rb`  
  - Fichier : `app/controllers/memberships_controller.rb`  
  - Lignes : ~183, 201, 203, 206  
  - Délivrable : décision claire sur le schéma cible (doc rapide ou commentaire dans le code).
- [x] **S1-T2** (todo `phase1-1-2`) – Unifier champs cachés dans `adult_form.html.erb`  
  - Fichier : `app/views/memberships/adult_form.html.erb` (ligne ~47)  
  - Action : remplacer `f.hidden_field :type, value: "adult"` par une approche cohérente avec `is_child_membership`.
- [x] **S1-T3** (todo `phase1-1-3`) – Vérifier cohérence dans `create`  
  - Fichier : `app/controllers/memberships_controller.rb` (lignes ~183–210)  
  - Action : s’assurer que la détection du type fonctionne encore et couvrir les cas enfant/ado/adulte.

#### 1.2 Bouton "Espèces / Chèques" adulte
- [x] **S1-T4** (todo `phase1-2-1`) – Finaliser la gestion du bouton "Espèces / Chèques" adulte  
  - Fichier : `app/views/memberships/adult_form.html.erb` (boutons + JS autour de 495–505 et 1218–1245)  
  - Objectif : clic sur ce bouton → `params[:payment_method] == "cash_check"` → `create_without_payment`.
- [x] **S1-T5** (todo `phase1-2-2`) – Harmoniser avec le bouton enfant  
  - Fichier : `app/views/memberships/child_form.html.erb` (lignes ~519–526)  
  - Objectif : même pattern (id, nom, gestion JS) entre enfant et adulte.
- [ ] **S1-T6** (todo `phase1-2-3`) – Tester le flux complet "Espèces / Chèques" adulte  
  - Vérifier dans la console Rails que :
    - `params[:payment_method]` vaut bien `"cash_check"`.
    - `create_without_payment` est appelé.
    - Aucune URL HelloAsso n’est générée.

---

## Sprint 2 – Renouvellement Adulte (Flux complet) ✅

### Objectifs
- Finir le renouvellement adulte côté vues.
- Garantir un flux homogène avec les enfants.

### Tâches

#### 2.1 Liens de renouvellement
- [x] **S2-T1** (todo `phase1-3-1`) – Lien renouvellement adulte dans `index.html.erb`  
  - Fichier : `app/views/memberships/index.html.erb` (lignes ~338–341)  
  - Action : utiliser `new_membership_path(type: 'adult', renew_from: membership.id)`.
- [x] **S2-T2** (todo `phase1-3-2`) – Lien renouvellement adulte dans `_membership_card.html.erb`  
  - Fichier : `app/views/memberships/_membership_card.html.erb` (lignes ~104–106)  
  - Action : même logique avec `renew_from: membership.id`.

#### 2.2 Vue `adult_form`
- [x] **S2-T3** (todo `phase1-3-3`) – Titre dynamique Hero adulte  
  - Fichier : `app/views/memberships/adult_form.html.erb` (lignes 14–15)  
  - Action : répliquer la logique de `child_form` (`@old_membership` présent → titre renouvellement).
- [x] **S2-T4** (todo `phase1-3-4`) – Message d’info en étape 2  
  - Fichier : `adult_form.html.erb` (après le titre de la section infos, ~ligne 94)  
  - Action : `alert alert-info` conditionnelle si `@old_membership`.
- [x] **S2-T5** (todo `phase1-3-5`) – Pré-remplissage propre via `@membership`  
  - Fichier : `adult_form.html.erb` (tous les champs infos/coordonnées)  
  - Action : utiliser `@membership&.xxx || @user.xxx.presence` (ou `"FR"` pour le pays) comme dans le comparatif.

---

## Sprint 3 – Téléphone & Questionnaire Santé ✅

### Objectifs
- Avoir une validation téléphone propre et homogène.
- Harmoniser les textes et comportements du questionnaire de santé.

### Tâches

#### 3.1 Téléphone (adultes)
- [x] **S3-T1** (todo `phase2-1-1`) – Décider format téléphone de référence (avec ou sans espaces).  
- [x] **S3-T2** (todo `phase2-1-2`) – Mettre à jour le placeholder  
  - Fichier : `adult_form.html.erb` (lignes ~129–137).
- [x] **S3-T3** (todo `phase2-1-3`) – Mettre à jour le pattern HTML du champ.
- [x] **S3-T4** (todo `phase2-1-4`) – Mettre à jour le message d’erreur dans `validateField()` adulte.
- [x] **S3-T5** (todo `phase2-1-5`) – Vérifier que le contrôleur Stimulus `phone-mask` reste cohérent.

#### 3.2 Questionnaire de santé
- [x] **S3-T6** (todo `phase2-2-1`) – Comparer les textes santé enfant/adulte (lignes ~340–351 dans les deux vues) et noter les écarts.
- [x] **S3-T7** (todo `phase2-2-2`) – Harmoniser les textes (ton, mentions FFRS) dans `child_form` et `adult_form`.
- [x] **S3-T8** (todo `phase2-2-3`) – Vérifier que `checkHealthQuestions()` a la même logique (ffrs/standard) dans les deux fichiers.

---

## Sprint 4 – Boutons & Validation JS

### Objectifs
- Uniformiser l’UX des boutons.
- Réduire les divergences inutiles de validation JS.

### Tâches

#### 4.1 Boutons de soumission
- [ ] **S4-T1** (todo `phase2-3-1`) – Fixer les libellés finaux des boutons principaux (enfant/adulte).
- [ ] **S4-T2** (todo `phase2-3-2`) – Harmoniser les classes CSS (`btn-liquid-primary` par ex.) dans `child_form` et `adult_form` pour le bouton principal.
- [ ] **S4-T3** (todo `phase2-3-3`) – Aligner la gestion du bouton "Espèces / Chèques" entre enfant et adulte (même pattern technique).

#### 4.2 Validation globale `validateForm`
- [ ] **S4-T4** (todo `phase2-4-1`) – Diff comparer les deux `validateForm()` et extraire ce qui est vraiment commun.
- [ ] **S4-T5** (todo `phase2-4-2`) – Unifier la façon de gérer les `required` sur champs cachés.
- [ ] **S4-T6** (todo `phase2-4-3`) – Aligner les messages d’erreurs (ton, structure, affichage).
- [ ] **S4-T7** (todo `phase2-4-4`) – Harmoniser la gestion des boutons désactivés/activés en fonction de la validité.

---

## Sprint 5 – Finitions UX (Catégories, Noms de fonctions, Callbacks)

### Objectifs
- Avoir une logique de catégorie cohérente.
- Rendre le JS plus lisible et homogène.

### Tâches

#### 5.1 Sélection & Inférence Catégorie
- [ ] **S5-T1** (todo `phase3-1-1`) – Décider la règle de sélection par défaut (`standard` + `@membership.nil?` ?).
- [ ] **S5-T2** (todo `phase3-1-2`) – Implémenter la règle dans `child_form`.
- [ ] **S5-T3** (todo `phase3-1-3`) – Implémenter la même règle dans `adult_form`.
- [ ] **S5-T4** (todo `phase3-2-1`) – Décider si on garde l’inférence catégorie côté enfant, si on l’ajoute côté adulte ou si on la supprime.
- [ ] **S5-T5** (todo `phase3-2-2`) – Implémenter la décision (enfant, adulte ou les deux).

#### 5.2 Nommage & callbacks JS
- [ ] **S5-T6** (todo `phase3-3-1`) – Choisir une convention de nommage (`updateXAge` ou `checkXAge`).
- [ ] **S5-T7** (todo `phase3-3-2` + `phase3-3-3`) – Renommer les fonctions et mettre à jour tous les appels.
- [ ] **S5-T8** (todo `phase3-4-1`) – Vérifier tous les endroits où `checkHealthQuestions()` est appelé (catégorie, réponses, âge).
- [ ] **S5-T9** (todo `phase3-4-2`) – Ajouter/retirer les appels pour obtenir exactement le même comportement enfant/adulte.

---

## Sprint 6 – Essai Gratuit Enfants

### Objectifs
- Implémenter l’essai gratuit par enfant (fonctionnalité plus grosse, isolée en sprint dédié).

### Tâches (synthèse – voir todo détaillée phase 4)

#### 6.1 Modèle & contrôleurs
- [x] **S6-T1** (todo `phase4-1-1` + `phase4-1-2`) – Ajouter status `trial` dans `Membership` et adapter validations.
- [x] **S6-T2** (todo `phase4-2-1` + `phase4-2-2`) – Adapter `attendances_controller` pour différencier parent/enfant.
- [x] **S6-T3** (todo `phase4-3-1` + `phase4-3-2`) – Adapter `Event::InitiationPolicy`.
- [x] **S6-T4** (todo `phase4-4-1` + `phase4-4-2`) – Adapter validation `can_use_free_trial` dans `Attendance`.

#### 6.2 Frontend & flux
- [ ] **S6-T5** (todo `phase4-5-1` + `phase4-5-2`) – Ajouter création enfant sans adhésion (status `trial`) dans `child_form` + contrôleur.
- [ ] **S6-T6** (todo `phase4-6-1` à `phase4-6-3`) – Intégrer l’option "essai gratuit" dans le formulaire d’inscription à l’initiation.
- [ ] **S6-T7** (todo `phase4-7-1` à `phase4-7-3`) – Implémenter le flux de conversion `trial` → adhésion payante.

---

## Sprint 7 – Tests Finaux & Validation

### Objectifs
- Valider tous les flux critiques (adhésions + essais gratuits).

### Document de Test
📋 **[Guide de Tests Complet](./tests-sprint-7-validation.md)** - Checklist détaillée pour tous les scénarios de test

### Tâches

#### 7.1 Tests adhésions & renouvellements
- [ ] **S7-T1** (todos `phase5-1-1` à `phase5-1-6`) – Exécuter tous les scénarios :
  - Adhésion adulte initiale.
  - Renouvellement adulte.
  - Adhésion enfant initiale.
  - Renouvellement enfant.
  - Cas limites d’âge (14–18).
  - Standard/FFRS avec/sans certificat.

#### 7.2 Tests essai gratuit
- [ ] **S7-T2** (todos `phase5-2-1` à `phase5-2-5`) – Tester :
  - Création enfant `trial`.
  - Inscription initiation avec essai gratuit.
  - Limite 1 essai par enfant.
  - Multi-enfants.
  - Conversion essai → adhésion.

#### 7.3 Tests JS
- [ ] **S7-T3** (todos `phase5-3-1` à `phase5-3-4`) – Tester :
  - Formats téléphone.
  - Dates de naissance.
  - Questionnaire santé.
  - Activation/désactivation des boutons.

---

---

## 🔗 Liens Vers Autres Documents

- 📚 **[Index Documentation](./INDEX-FORMULAIRES-ADHESION.md)** - Vue d'ensemble de tous les documents
- 📊 **[Analyse Technique Complète](./comparatif-complet-formulaires-integration.md)** - Détails techniques avec liens vers fichiers
- 🔄 **[Comparatif Initial](./comparatif-formulaires-enfant-adulte.md)** - Analyse comparative initiale + détails renouvellement adulte
- 🎁 **[Essai Gratuit Enfants](./ESSAI_GRATUIT_ENFANTS.md)** - Spécification complète de la fonctionnalité

---

## Utilisation

- Ce fichier sert de **vue d’ensemble par sprint**.  
- La todolist détaillée reste dans le système de todos (ids `phaseX-Y-Z`).  
- À chaque sprint, tu peux :
  - Cocher ici les tâches de sprint.
  - Marquer les todos correspondants comme `completed`.

Si tu veux, on peut maintenant **choisir ensemble le Sprint 1** et commencer à l’attaquer proprement (en suivant ce plan).