---
title: "Checklist Tests - Inscription & Profil"
status: "active"
version: "1.0"
created: "2025-11-24"
tags: ["testing", "checklist", "devise", "registration", "profile"]
---

# Checklist Tests - Inscription & Profil

**Date** : 2025-11-24  
**Branche** : `feature/devise-quick-wins`  
**Objectif** : Tests manuels prioritaires à effectuer

---

## 🔴 PRIORITÉ HAUTE - Tests Critiques

### 1. Inscription - Cas Nominal ✅
- [ ] **Accéder à** `/users/sign_up`
- [ ] **Remplir** : Email valide, Prénom, Mot de passe 12+ caractères, Niveau, CGU coché
- [ ] **Vérifier** : Redirection vers `/events`
- [ ] **Vérifier** : Message "Bienvenue [Prénom] ! 🎉"
- [ ] **Vérifier** : Utilisateur connecté automatiquement
- [ ] **Vérifier** : Emails envoyés (bienvenue + confirmation) - **Vérifier logs Rails**

### 2. Inscription - Erreurs de Validation ⚠️
- [ ] **Email invalide** : `email-invalide` → Message "Email n'est pas valide"
- [ ] **Prénom vide** → Message "Prénom doit être rempli(e)"
- [ ] **Mot de passe 11 caractères** → Message "est trop court (minimum 12 caractères)" ✅ **CORRIGÉ**
- [ ] **Niveau non sélectionné** → Message "Niveau doit être sélectionné"
- [ ] **CGU non coché** → Message "Vous devez accepter les CGU..."
- [ ] **Email déjà utilisé** → Message "Email a déjà été utilisé"
- [ ] **Vérifier** : Reste sur `/users/sign_up` (ne redirige pas vers `/users`) ✅ **CORRIGÉ**

### 3. Toggle Password 👁️
- [ ] **Saisir mot de passe** → Cliquer sur icône œil
- [ ] **Vérifier** : Mot de passe visible
- [ ] **Vérifier** : Icône change (œil → œil barré)
- [ ] **Vérifier** : `aria-label` mis à jour
- [ ] **Vérifier** : Contour rouge englobe input + bouton toggle ✅ **CORRIGÉ**

### 4. Accès Immédiat (Période de Grâce) 🎁
- [ ] **S'inscrire** sans confirmer email
- [ ] **Vérifier** : Accès immédiat au site (navigation libre)
- [ ] **Vérifier** : Consultation événements possible
- [ ] **Vérifier** : Consultation panier possible
- [ ] **Tester** : S'inscrire à un événement → **BLOQUÉ** avec message "Vous devez confirmer votre adresse email"
- [ ] **Tester** : Passer une commande → **BLOQUÉ** avec message "Vous devez confirmer votre adresse email"

### 5. Profil - Consultation & Modification ✅
- [ ] **Accéder à** `/users/edit` (connecté)
- [ ] **Vérifier** : Tous les champs affichés (Prénom, Nom, Email, Téléphone, Niveau, Bio)
- [ ] **Vérifier** : Skill level cards pré-sélectionnées avec niveau actuel
- [ ] **Modifier** : Nom, Téléphone, Niveau, Bio
- [ ] **Saisir** : Mot de passe actuel
- [ ] **Vérifier** : Message "Votre compte a été mis à jour avec succès"
- [ ] **Vérifier** : Modifications sauvegardées

### 6. Profil - Erreurs de Validation ⚠️
- [ ] **Prénom vide** → Message "Prénom doit être rempli(e)"
- [ ] **Email invalide** → Message "Email n'est pas valide"
- [ ] **Mot de passe actuel incorrect** → Message "Mot de passe actuel est incorrect"
- [ ] **Mot de passe actuel vide** → Message "Mot de passe actuel doit être rempli(e)"

---

## 🟡 PRIORITÉ MOYENNE - Tests UX

### 7. Skill Level Cards 🎯
- [ ] **Vérifier** : 3 cards affichées (Débutant, Intermédiaire, Avancé)
- [ ] **Vérifier** : Card actuelle pré-sélectionnée (bordure active)
- [ ] **Cliquer** sur autre card → Changement fonctionnel
- [ ] **Vérifier** : Icônes visibles (person, person-check, trophy)
- [ ] **Vérifier** : Responsive (3 colonnes sur mobile)

### 8. Accessibilité WCAG 2.2 ♿
- [ ] **Navigation clavier** : Tab dans formulaire → Focus visible (outline 3px)
- [ ] **Ordre logique** : Email → Prénom → Password → Niveau → CGU → Submit
- [ ] **Erreurs** : `aria-describedby` pointe vers messages d'erreur
- [ ] **Erreurs** : `aria-invalid="true"` sur champs en erreur
- [ ] **Cibles tactiles** : Boutons ≥ 44×44px, Checkboxes ≥ 24×24px

### 9. Responsive Design 📱
- [ ] **Mobile (375px)** : Formulaire centré, cards 3 colonnes, pas de débordement
- [ ] **Tablette (768px)** : Layout adapté
- [ ] **Desktop (1920px)** : Layout optimal

---

## 🟢 PRIORITÉ BASSE - Tests Complémentaires

### 10. Emails 📧
- [ ] **Email de bienvenue** : Vérifier contenu HTML, lien vers événements
- [ ] **Email de confirmation** : Vérifier lien de confirmation
- [ ] **Config SMTP** : Vérifier que les emails sont bien envoyés (logs Rails)

### 11. Rack::Attack (Rate Limiting) 🔒
- [ ] **5 tentatives connexion** → Bloqué avec message 429
- [ ] **3 inscriptions/heure** → Bloqué après 3ème
- [ ] **3 reset password/heure** → Bloqué après 3ème
- [ ] **Vérifier** : Pas d'erreur `NoMethodError` ✅ **CORRIGÉ**

---

## ✅ Tests Automatisés RSpec - Statut

### RSpec - Models (✅ Complété)
**Fichier** : `spec/models/user_spec.rb`
- ✅ `first_name` obligatoire (déjà testé)
- ✅ **Ajouté** : Validation `skill_level` obligatoire
- ✅ **Ajouté** : Validation `skill_level` inclusion (beginner, intermediate, advanced)
- ✅ **Ajouté** : Méthode `active_for_authentication?` (accès non confirmé)
- ✅ **Ajouté** : Callback `send_welcome_email_and_confirmation` (envoi email)

**Factory** : `spec/factories/users.rb`
- ✅ **Ajouté** : `skill_level` par défaut (intermediate)
- ✅ **Ajouté** : `confirmed_at` par défaut (utilisateur confirmé)
- ✅ **Ajouté** : Traits `:unconfirmed`, `:beginner`, `:advanced`

**Helper** : `spec/support/test_data_helper.rb`
- ✅ **Ajouté** : `skill_level` dans `build_user` et `create_user`

### RSpec - Controllers (✅ Créé)
**Fichier créé** : `spec/requests/registrations_spec.rb`
- ✅ Création avec consentement RGPD
- ✅ Redirection en cas d'erreur (reste sur sign_up)
- ✅ Message de bienvenue personnalisé
- ✅ Envoi emails (bienvenue + confirmation)
- ✅ Validation des erreurs (email, prénom, password, skill_level, CGU)
- ✅ Email déjà utilisé
- ✅ Accès immédiat (période de grâce)

**Fichier complété** : `spec/requests/events_spec.rb`
- ✅ **Ajouté** : Blocage si email non confirmé pour `attend`

**Fichier créé** : `spec/requests/orders_spec.rb`
- ✅ Blocage si email non confirmé pour `create`
- ✅ Accès checkout pour utilisateurs confirmés

**Helper** : `spec/support/request_authentication_helper.rb`
- ✅ **Ajouté** : Méthode `logout_user`

### RSpec - Mailers (✅ Créé)
**Fichier créé** : `spec/mailers/user_mailer_spec.rb`
- ✅ Email de bienvenue (destinataire, sujet)
- ✅ Contenu HTML et texte
- ✅ Inclusion prénom utilisateur
- ✅ Lien vers événements

### RSpec - System/Features (⏳ À créer - Optionnel)
**Fichiers à créer** (tests end-to-end avec Capybara) :
- [ ] `spec/features/registration_spec.rb` : Parcours complet d'inscription
  - Formulaire 4 champs
  - Validation des erreurs
  - Toggle password
  - Skill level cards
  - Consentement RGPD
- [ ] `spec/features/profile_spec.rb` : Modification du profil
  - Affichage des champs
  - Modification skill level
  - Validation des erreurs

---

## 📝 Notes de Test

### Environnement de Test
- **URL** : `https://dev-grenoble-roller.flowtech-lab.org`
- **Base de données** : Vérifier que les emails de test ne sont pas déjà utilisés
- **SMTP** : Vérifier configuration pour envoi d'emails

### Bugs Connus / Résolus
- ✅ **Corrigé** : Message "14 caractères" → "12 caractères"
- ✅ **Corrigé** : Redirection vers `/users` → Reste sur `/users/sign_up`
- ✅ **Corrigé** : Contour rouge n'englobait pas le bouton toggle
- ✅ **Corrigé** : Rack::Attack `NoMethodError` sur `match_data`

### Points d'Attention
- **Emails** : Vérifier que la configuration SMTP fonctionne en staging
- **Période de grâce** : Tester que l'accès fonctionne pendant 2 jours sans confirmation
- **Confirmation email** : Tester que le blocage fonctionne pour événements et commandes

---

**Dernière mise à jour** : 2025-11-24

