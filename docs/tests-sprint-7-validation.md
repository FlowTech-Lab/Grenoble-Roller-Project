# Tests Sprint 7 - Validation Complète

> 📚 **Index Documentation :** Voir [`INDEX-FORMULAIRES-ADHESION.md`](./INDEX-FORMULAIRES-ADHESION.md) pour la vue d'ensemble  
> 🗓️ **Plan de Sprints :** Voir [`plan-sprints-formulaires-adhesion.md`](./plan-sprints-formulaires-adhesion.md) pour le contexte

---

## 📋 Objectif

Valider tous les flux critiques implémentés dans les Sprints 1 à 6 :
- Adhésions et renouvellements (adulte/enfant)
- Essais gratuits enfants
- Validations JavaScript

---

## ✅ Checklist de Tests

### 7.1 Tests Adhésions & Renouvellements

#### Test 7.1.1 : Adhésion Adulte Initiale
- [ ] **Prérequis** : Utilisateur connecté sans adhésion active
- [ ] **Actions** :
  1. Aller sur `/memberships`
  2. Cliquer sur "Adhérer maintenant"
  3. Remplir le formulaire adulte (catégorie Standard)
  4. Valider avec paiement HelloAsso
- [ ] **Résultat attendu** :
  - Adhésion créée avec statut `pending`
  - Redirection vers HelloAsso pour paiement
  - Après paiement, statut passe à `active`

#### Test 7.1.2 : Renouvellement Adulte depuis Historique
- [ ] **Prérequis** : Utilisateur avec adhésion expirée
- [ ] **Actions** :
  1. Aller sur `/memberships`
  2. Cliquer sur "Renouveler" sur l'adhésion expirée
  3. Vérifier le pré-remplissage (catégorie, adresse, etc.)
  4. Modifier si nécessaire et valider
- [ ] **Résultat attendu** :
  - Formulaire pré-rempli avec données de l'ancienne adhésion
  - Titre affiche "RENOUVELLEMENT D'ADHÉSION"
  - Message info visible dans l'étape 2
  - Création nouvelle adhésion avec données pré-remplies

#### Test 7.1.3 : Adhésion Enfant Initiale
- [ ] **Prérequis** : Utilisateur connecté
- [ ] **Actions** :
  1. Aller sur `/memberships`
  2. Cliquer sur "Ajouter" dans la section enfants
  3. Remplir le formulaire enfant (nom, prénom, date de naissance, catégorie)
  4. Répondre au questionnaire de santé
  5. Valider avec paiement HelloAsso
- [ ] **Résultat attendu** :
  - Adhésion enfant créée avec statut `pending`
  - Redirection vers HelloAsso pour paiement
  - Enfant visible dans la liste des adhésions

#### Test 7.1.4 : Renouvellement Enfant
- [ ] **Prérequis** : Utilisateur avec adhésion enfant expirée
- [ ] **Actions** :
  1. Aller sur `/memberships`
  2. Cliquer sur "Réadhérer" sur l'adhésion enfant expirée
  3. Vérifier le pré-remplissage
  4. Valider
- [ ] **Résultat attendu** :
  - Formulaire pré-rempli avec données de l'enfant
  - Création nouvelle adhésion enfant

#### Test 7.1.5 : Cas Limites d'Âge (14, 15, 16, 17, 18 ans)
- [ ] **Test 14 ans** :
  - Créer enfant avec date de naissance = 14 ans
  - Vérifier : autorisation parentale requise
- [ ] **Test 15 ans** :
  - Créer enfant avec date de naissance = 15 ans
  - Vérifier : autorisation parentale requise
- [ ] **Test 16 ans** :
  - Créer enfant avec date de naissance = 16 ans
  - Vérifier : autorisation parentale requise
- [ ] **Test 17 ans** :
  - Créer enfant avec date de naissance = 17 ans
  - Vérifier : autorisation parentale non requise
- [ ] **Test 18 ans** :
  - Essayer créer enfant avec date de naissance = 18 ans
  - Vérifier : redirection vers formulaire adulte

#### Test 7.1.6 : Catégories Standard/FFRS avec/sans Certificat
- [ ] **Standard - Toutes réponses NON** :
  - Créer adhésion Standard
  - Répondre NON à toutes les questions santé
  - Vérifier : pas de certificat requis, adhésion créée
- [ ] **Standard - Au moins une réponse OUI** :
  - Créer adhésion Standard
  - Répondre OUI à au moins une question
  - Vérifier : certificat recommandé mais pas obligatoire
- [ ] **FFRS - Toutes réponses NON (nouvelle licence)** :
  - Créer adhésion FFRS
  - Répondre NON à toutes les questions
  - Vérifier : certificat obligatoire (nouvelle licence)
- [ ] **FFRS - Toutes réponses NON (renouvellement)** :
  - Créer adhésion FFRS pour enfant ayant déjà eu FFRS
  - Répondre NON à toutes les questions
  - Vérifier : pas de certificat requis (attestation auto)
- [ ] **FFRS - Au moins une réponse OUI** :
  - Créer adhésion FFRS
  - Répondre OUI à au moins une question
  - Vérifier : certificat obligatoire

---

### 7.2 Tests Essai Gratuit

#### Test 7.2.1 : Création Enfant sans Adhésion (Status Trial)
- [ ] **Actions** :
  1. Aller sur formulaire enfant (`/memberships/new?type=child`)
  2. Remplir les informations de l'enfant
  3. Cocher "Créer sans adhésion (pour essai gratuit)"
  4. Valider
- [ ] **Résultat attendu** :
  - Adhésion créée avec statut `trial`
  - Pas de dates ni montant requis
  - Badge "Essai gratuit" visible dans `/memberships`
  - Message : "L'enfant a été ajouté avec succès. Vous pouvez maintenant utiliser l'essai gratuit pour une initiation."

#### Test 7.2.2 : Inscription Initiation avec Essai Gratuit Enfant
- [ ] **Prérequis** : Enfant avec statut `trial` créé
- [ ] **Actions** :
  1. Aller sur une page d'initiation
  2. Sélectionner l'enfant avec statut `trial` dans le dropdown
  3. Vérifier que la checkbox "Utiliser l'essai gratuit de [Nom Enfant]" apparaît
  4. Cocher la checkbox (déjà cochée par défaut)
  5. Valider l'inscription
- [ ] **Résultat attendu** :
  - Inscription créée avec `free_trial_used: true`
  - `child_membership_id` correctement renseigné
  - Message de confirmation affiché
  - Enfant inscrit à l'initiation

#### Test 7.2.3 : Limite 1 Essai Gratuit par Enfant
- [ ] **Prérequis** : Enfant avec statut `trial` ayant déjà utilisé son essai gratuit
- [ ] **Actions** :
  1. Aller sur une autre initiation
  2. Sélectionner le même enfant
  3. Essayer s'inscrire avec essai gratuit
- [ ] **Résultat attendu** :
  - Option essai gratuit masquée ou désactivée
  - Message d'erreur si tentative : "Cet enfant a déjà utilisé son essai gratuit"
  - Inscription impossible sans adhésion payante

#### Test 7.2.4 : Plusieurs Enfants avec Essais Gratuits
- [ ] **Actions** :
  1. Créer 2 enfants avec statut `trial`
  2. Inscrire le premier enfant à une initiation avec essai gratuit
  3. Inscrire le deuxième enfant à une autre initiation avec essai gratuit
- [ ] **Résultat attendu** :
  - Chaque enfant peut utiliser son propre essai gratuit
  - Les essais sont indépendants (pas de conflit)
  - Chaque enfant peut s'inscrire avec son essai gratuit

#### Test 7.2.5 : Conversion Essai → Adhésion
- [ ] **Prérequis** : Enfant avec statut `trial`
- [ ] **Actions** :
  1. Aller sur `/memberships`
  2. Cliquer sur "Adhérer maintenant" sur l'enfant avec statut `trial`
  3. Confirmer la conversion
- [ ] **Résultat attendu** :
  - Statut passe de `trial` à `pending`
  - Dates de saison ajoutées
  - Montant calculé selon la catégorie
  - Redirection vers formulaire de paiement
  - Message : "L'essai gratuit a été converti en adhésion. Vous pouvez maintenant procéder au paiement."

---

### 7.3 Tests JavaScript

#### Test 7.3.1 : Validation Format Téléphone
- [ ] **Format avec espaces** :
  - Entrer "06 12 34 56 78"
  - Vérifier : validation OK
- [ ] **Format sans espaces** :
  - Entrer "0612345678"
  - Vérifier : masque ajoute automatiquement les espaces
- [ ] **Format invalide** :
  - Entrer "123" ou "abc"
  - Vérifier : message d'erreur affiché
- [ ] **Format international** :
  - Entrer "+33 6 12 34 56 78"
  - Vérifier : validation selon pattern défini

#### Test 7.3.2 : Validation Date de Naissance
- [ ] **Date invalide (jour)** :
  - Sélectionner jour 31 pour février
  - Vérifier : message d'erreur ou correction automatique
- [ ] **Date invalide (mois/année)** :
  - Sélectionner date future
  - Vérifier : message d'erreur "Date de naissance invalide"
- [ ] **Âge < 6 ans** :
  - Entrer date de naissance pour enfant < 6 ans
  - Vérifier : message "L'adhésion n'est pas possible pour les enfants de moins de 6 ans"
- [ ] **Date valide** :
  - Entrer date valide
  - Vérifier : pas d'erreur, âge calculé correctement

#### Test 7.3.3 : Validation Questionnaire Santé
- [ ] **Catégorie Standard - Toutes NON** :
  - Sélectionner Standard
  - Répondre NON à toutes les questions
  - Vérifier : pas de demande de certificat
- [ ] **Catégorie Standard - Au moins une OUI** :
  - Sélectionner Standard
  - Répondre OUI à une question
  - Vérifier : message recommandation certificat (pas obligatoire)
- [ ] **Catégorie FFRS - Toutes NON** :
  - Sélectionner FFRS
  - Répondre NON à toutes les questions
  - Vérifier : demande certificat (nouvelle licence) ou pas (renouvellement)
- [ ] **Catégorie FFRS - Au moins une OUI** :
  - Sélectionner FFRS
  - Répondre OUI à une question
  - Vérifier : certificat obligatoire, champ requis
- [ ] **Changement de catégorie** :
  - Répondre aux questions avec Standard
  - Changer pour FFRS
  - Vérifier : revalidation automatique, mise à jour affichage certificat

#### Test 7.3.4 : Boutons Submit Désactivés/Activés
- [ ] **Formulaire incomplet** :
  - Laisser des champs obligatoires vides
  - Vérifier : bouton submit désactivé ou message d'erreur au clic
- [ ] **Questionnaire santé incomplet** :
  - Ne pas répondre à toutes les questions santé
  - Vérifier : bouton submit désactivé ou message d'erreur
- [ ] **Certificat manquant (FFRS obligatoire)** :
  - Sélectionner FFRS, répondre OUI, ne pas uploader certificat
  - Vérifier : bouton submit désactivé ou message d'erreur
- [ ] **Formulaire complet** :
  - Remplir tous les champs obligatoires
  - Vérifier : bouton submit activé
- [ ] **Essai gratuit (parent)** :
  - Parent sans adhésion, checkbox essai gratuit non cochée
  - Vérifier : bouton submit désactivé (si essai requis)
- [ ] **Essai gratuit (enfant trial)** :
  - Sélectionner enfant trial, checkbox essai gratuit non cochée
  - Vérifier : bouton submit désactivé

---

## 📝 Notes de Test

### Environnement de Test
- **URL de base** : `http://localhost:3000` (ou URL de staging/production)
- **Comptes de test** : Créer des comptes utilisateurs avec différents scénarios

### Données de Test Recommandées
- **Enfant 6-15 ans** : Pour tester autorisation parentale
- **Enfant 16-17 ans** : Pour tester sans autorisation parentale
- **Enfant 18 ans** : Pour tester redirection adulte
- **Adhésions expirées** : Pour tester renouvellements

### Points d'Attention
- Vérifier les messages d'erreur sont clairs et compréhensibles
- Vérifier les redirections après actions (création, paiement, etc.)
- Vérifier la cohérence des statuts d'adhésion
- Vérifier l'indépendance des essais gratuits par enfant
- Vérifier la conversion trial → pending fonctionne correctement

---

## 🔗 Liens Vers Autres Documents

- 📚 **[Index Documentation](./INDEX-FORMULAIRES-ADHESION.md)** - Vue d'ensemble de tous les documents
- 📊 **[Analyse Technique Complète](./comparatif-complet-formulaires-integration.md)** - Détails techniques avec liens vers fichiers
- 🗓️ **[Plan de Sprints](./plan-sprints-formulaires-adhesion.md)** - Vue d'ensemble des sprints
- 🔄 **[Comparatif Initial](./comparatif-formulaires-enfant-adulte.md)** - Analyse comparative initiale
- 🎁 **[Essai Gratuit Enfants](./ESSAI_GRATUIT_ENFANTS.md)** - Spécification complète de la fonctionnalité

---

## ✅ Résultat Final

Une fois tous les tests validés, cocher les tâches correspondantes dans le plan de sprints et documenter les éventuels bugs ou améliorations à apporter.
