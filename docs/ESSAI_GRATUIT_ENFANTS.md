# Essai Gratuit pour les Enfants - Analyse et Proposition

## 📋 État Actuel

### Fonctionnement actuel

**Pour les PARENTS :**
- ✅ Un parent peut utiliser un essai gratuit pour lui-même (sans adhésion)
- ✅ L'essai gratuit est comptabilisé au niveau du compte parent (1 essai par parent)

**Pour les ENFANTS :**
- ❌ Un enfant DOIT avoir une adhésion active pour s'inscrire
- ❌ Aucun essai gratuit possible pour les enfants
- ❌ Un enfant ne peut pas être créé sans adhésion

### Stockage dans la base de données

L'information est stockée dans la table `attendances` :

```sql
attendances:
  - user_id: ID du parent
  - child_membership_id: NULL si parent, ID adhésion si enfant
  - free_trial_used: boolean (true si essai utilisé)
```

**Index optimisé :** `index_attendances_on_user_id_and_free_trial_used`

**Logique actuelle :**
```ruby
# Vérification actuelle (contrôleur)
current_user.attendances.where(free_trial_used: true).exists?
# => Vérifie TOUTES les attendances du parent (peu importe parent/enfant)
# => 1 essai gratuit maximum par compte parent
```

---

## 🎯 Proposition : Permettre l'essai gratuit pour les enfants

### Concept

**Permettre à chaque enfant d'avoir son propre essai gratuit**, comme si chaque enfant était un utilisateur indépendant pour cet usage.

### Workflow Utilisateur Proposé

#### Étape 1 : Création d'un enfant (sans adhésion)

**Nouveau flux :** Le parent peut créer un enfant avec juste :
- Prénom de l'enfant
- Nom de l'enfant  
- Date de naissance
- (Optionnel) Autorisation parentale si < 16 ans

**Pas besoin d'adhésion à ce stade !**

#### Étape 2 : Inscription à une initiation

**Si l'enfant n'a pas d'adhésion :**
- ✅ Le parent peut utiliser l'essai gratuit pour cet enfant
- ✅ Chaque enfant a son propre essai gratuit
- ✅ Un parent peut utiliser l'essai gratuit pour lui + essai gratuit pour enfant 1 + essai gratuit pour enfant 2, etc.

**Si l'enfant a une adhésion active :**
- ✅ Comportement normal (pas besoin d'essai gratuit)

---

## 🔧 Modifications Techniques Nécessaires

### 1. Base de données ✅

**Aucune migration nécessaire !** La structure actuelle supporte déjà cette fonctionnalité :

```ruby
# Schema actuel (suffisant)
attendances:
  user_id: ID du parent
  child_membership_id: ID de l'adhésion enfant (ou NULL)
  free_trial_used: boolean
```

**Cependant**, il faudra distinguer :
- Les enfants créés **avec** une adhésion (membership active)
- Les enfants créés **sans** adhésion (juste nom/prénom, pour essai gratuit)

### 2. Modèle `Membership`

**Option A :** Créer des "adhésions virtuelles" avec `status: 'trial'`
- Permet de stocker les infos de l'enfant même sans adhésion payée
- Facilite la gestion (même structure)

**Option B :** Créer une nouvelle table `children` séparée
- Plus de clarté conceptuelle
- Nécessite une migration
- Plus de refactoring du code

**Recommandation : Option A** (moins de changements)

### 3. Contrôleur `initiations/attendances_controller.rb`

**Modifications nécessaires :**

```ruby
# Ligne 91 - Actuellement
if child_membership_id.nil? && !is_member
  # Gestion essai gratuit UNIQUEMENT pour parents
  
# À modifier en
if !is_member  # Pour parents OU enfants sans adhésion
  # Gérer l'essai gratuit pour parent ou enfant
  if child_membership_id.present?
    # Vérifier si CET ENFANT a déjà utilisé son essai gratuit
    if current_user.attendances
         .where(free_trial_used: true, child_membership_id: child_membership_id)
         .exists?
      # Bloquer
    end
  else
    # Vérifier si le PARENT a déjà utilisé son essai gratuit
    if current_user.attendances
         .where(free_trial_used: true, child_membership_id: nil)
         .exists?
      # Bloquer
    end
  end
```

### 4. Vue : Formulaire de création d'enfant

**Nouveau formulaire :** Permettre de créer un enfant sans adhésion

```erb
<!-- Formulaire simplifié -->
- Prénom enfant (requis)
- Nom enfant (requis)
- Date de naissance (requis)
- Autorisation parentale si < 16 ans (requis si applicable)

<!-- Options -->
[ ] Créer l'adhésion maintenant (paiement)
[ ] Créer sans adhésion (pour essai gratuit)
```

### 5. Vue : Formulaire d'inscription à l'initiation

**Modifications :**

```erb
<!-- Si enfant sans adhésion -->
<% if child_membership.status == 'trial' %>
  <label>
    <input type="checkbox" name="use_free_trial" value="1">
    Utiliser l'essai gratuit pour <%= child_membership.child_first_name %>
  </label>
<% end %>
```

### 6. Policy `Event::InitiationPolicy`

**Modifications nécessaires :**

```ruby
# Ligne 92 - Actuellement
is_member || !user.attendances.where(free_trial_used: true).exists?

# À modifier pour distinguer parent/enfant
if child_membership_id.present?
  # Enfant : vérifier si CET ENFANT a déjà utilisé son essai
  child_has_trial = user.attendances
    .where(free_trial_used: true, child_membership_id: child_membership_id)
    .exists?
  child_membership&.active? || !child_has_trial
else
  # Parent : vérifier si le PARENT a déjà utilisé son essai
  is_member || !user.attendances.where(free_trial_used: true, child_membership_id: nil).exists?
end
```

### 7. Modèle `Attendance`

**Validation `can_use_free_trial` :**

```ruby
# Ligne 130 - À modifier
def can_use_free_trial
  return unless free_trial_used
  return unless user
  
  if child_membership_id.present?
    # Vérifier si CET ENFANT a déjà utilisé son essai
    if user.attendances
         .where(free_trial_used: true, child_membership_id: child_membership_id)
         .where.not(id: id)
         .exists?
      errors.add(:free_trial_used, "Cet enfant a déjà utilisé son essai gratuit")
    end
  else
    # Vérifier si le PARENT a déjà utilisé son essai
    if user.attendances
         .where(free_trial_used: true, child_membership_id: nil)
         .where.not(id: id)
         .exists?
      errors.add(:free_trial_used, "Vous avez déjà utilisé votre essai gratuit")
    end
  end
end
```

---

## 📊 Comparaison : Avant / Après

### Avant (Système Actuel)

| Cas | Comportement |
|-----|--------------|
| Parent sans adhésion | ✅ 1 essai gratuit possible |
| Enfant sans adhésion | ❌ **Impossible de s'inscrire** |
| Parent + 2 enfants sans adhésion | ❌ Impossible (enfants bloqués) |

**Résultat :** Les familles sans adhésions sont très limitées

### Après (Proposition)

| Cas | Comportement |
|-----|--------------|
| Parent sans adhésion | ✅ 1 essai gratuit |
| Enfant 1 sans adhésion | ✅ 1 essai gratuit (indépendant) |
| Enfant 2 sans adhésion | ✅ 1 essai gratuit (indépendant) |
| Parent + 2 enfants sans adhésion | ✅ **3 essais gratuits possibles !** |

**Résultat :** Les familles peuvent tester l'activité avant d'adhérer

---

## ✅ Avantages de cette approche

1. **Meilleure découverte** : Les familles peuvent tester avec plusieurs enfants
2. **Fidélisation** : Plus de familles tentent l'expérience
3. **Logique métier claire** : Chaque enfant = 1 essai gratuit
4. **Pas de migration DB** : Structure actuelle suffit (avec quelques ajustements)

## ⚠️ Points d'attention

1. **Gestion des enfants "essai"** : 
   - Comment distinguer un enfant créé pour essai vs un enfant avec adhésion ?
   - → Solution : Status `'trial'` dans membership ou table séparée

2. **Conversion essai → adhésion** :
   - Après l'essai gratuit, comment passer à l'adhésion ?
   - → Flux de "upgrade" nécessaire

3. **Limite d'enfants** :
   - Faut-il limiter le nombre d'enfants créés sans adhésion ?
   - → À discuter avec les bénévoles

---

## 🎯 Scénarios Utilisateurs

### Scénario 1 : Famille découvre l'initiation

1. **Parent se connecte** (ou crée un compte)
2. **Crée enfant 1** (juste nom/prénom, pas d'adhésion)
3. **S'inscrit avec essai gratuit** pour enfant 1
4. **Après la session** : "Super ! Je veux adhérer"
5. **Crée l'adhésion** pour enfant 1
6. **Peut maintenant** inscrire enfant 1 sans limite

### Scénario 2 : Famille avec 2 enfants

1. **Parent se connecte**
2. **Crée enfant 1** (sans adhésion)
3. **Crée enfant 2** (sans adhésion)
4. **S'inscrit avec essai gratuit** pour enfant 1
5. **S'inscrit avec essai gratuit** pour enfant 2
6. **Les deux enfants** peuvent tester gratuitement !

### Scénario 3 : Parent teste aussi

1. **Parent se connecte**
2. **Parent utilise son essai gratuit** pour lui-même
3. **Crée enfant 1** (sans adhésion)
4. **Enfant 1 utilise son essai gratuit**
5. **Résultat** : Parent + enfant ont testé gratuitement !

---

## 📝 Checklist des modifications

### Backend
- [ ] Modifier `Membership` pour supporter status `'trial'` (ou nouvelle table)
- [ ] Modifier contrôleur `attendances_controller.rb` (ligne 91+)
- [ ] Modifier policy `initiation_policy.rb` (ligne 92)
- [ ] Modifier validation `attendance.rb` méthode `can_use_free_trial`
- [ ] Modifier méthode `can_register_to_initiation` si nécessaire

### Frontend
- [ ] Formulaire création enfant sans adhésion
- [ ] Modifier formulaire d'inscription (affichage essai gratuit pour enfants)
- [ ] Flux de conversion essai → adhésion
- [ ] Messages d'aide/explications pour les parents

### Tests
- [ ] Test : Enfant sans adhésion peut utiliser essai gratuit
- [ ] Test : Plusieurs enfants peuvent utiliser leur essai gratuit
- [ ] Test : Conversion essai → adhésion
- [ ] Test : Limite 1 essai gratuit par enfant

---

## 🚀 Conclusion

**La base de données est prête**, il faut surtout modifier la **logique métier** et les **vues** pour permettre :
1. Création d'enfant sans adhésion (juste infos)
2. Essai gratuit par enfant (indépendant)
3. Conversion facile essai → adhésion

**Estimation :** 2-3 jours de développement + tests

---

**Date de création :** 2025-01-XX  
**Auteur :** Analyse technique  
**Destinataires :** Bénévoles association Grenoble Roller

