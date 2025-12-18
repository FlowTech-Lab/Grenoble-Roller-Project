# 10. Logique JavaScript vs Serveur (Sans JS)

[← Retour à l'index](index.md)

### 10.1. Comment le JavaScript Détecte que l'Essai a été Attribué ?

**Où est stockée l'info "essai gratuit attribué" ?**

L'essai gratuit n'est **pas stocké explicitement** dans la base de données. C'est **implicite** :
- Tous les enfants créés ont automatiquement un essai gratuit disponible
- L'essai gratuit est "utilisé" lorsqu'une `Attendance` est créée avec `free_trial_used = true`

**Comment le frontend le sait ?**

Le frontend calcule la disponibilité en vérifiant les attendances actives :

```javascript
// app/views/shared/_registration_form_fields.html.erb
// Données préparées côté serveur (Ruby)
const trialChildrenData = <%= raw trial_children_data %>;

// trial_children_data contient :
{
  id: child.id,
  name: "Alice Dupont",
  has_used_trial: false,  // Calculé : !attendances.active.where(free_trial_used: true).exists?
  can_use_trial: true      // Calculé : !has_used_trial
}
```

**Code Ruby réel qui prépare les données** :
```ruby
# app/views/shared/_registration_form_fields.html.erb
trial_children_data = trial_children.map do |child|
  {
    id: child.id,
    name: "#{child.child_first_name} #{child.child_last_name}",
    has_used_trial: current_user.attendances.active
      .where(free_trial_used: true, child_membership_id: child.id)
      .exists?,
    can_use_trial: !current_user.attendances.active
      .where(free_trial_used: true, child_membership_id: child.id)
      .exists?
  }
end.to_json
```

**Pas d'endpoint API nécessaire** : Les données sont calculées côté serveur et injectées dans le HTML via JSON.

### 10.2. Comportement avec JavaScript

**Avec JavaScript activé** :
- ✅ Checkbox cochée automatiquement pour enfants `trial` (obligatoire)
- ✅ Checkbox affichée mais optionnelle pour enfants `pending`
- ✅ Validation avant soumission (empêche soumission si non cochée pour `trial`)
- ✅ Mise à jour du champ caché automatique
- ✅ Meilleure UX (feedback immédiat)

### 10.3. Comportement sans JavaScript

**Sans JavaScript (ou JS désactivé)** :
- ⚠️ Checkbox peut ne pas être cochée automatiquement
- ✅ **Validation serveur prend le relais** :
  - Contrôleur vérifie que `use_free_trial` est présent pour enfants `trial`
  - Modèle vérifie que `free_trial_used = true` pour enfants `trial`
- ✅ L'inscription est bloquée avec message d'erreur approprié

### 10.4. Garantie de Fonctionnement

**Principe** : Le système fonctionne **même sans JavaScript**.

**Protection** :
- ✅ Validation contrôleur : Vérifie les paramètres ET l'état
- ✅ Validation modèle : Vérifie l'état (source de vérité)
- ✅ Messages d'erreur clairs pour guider l'utilisateur

**Exemple de flux sans JS** :
```
1. Utilisateur sélectionne enfant trial
2. Checkbox non cochée automatiquement (JS désactivé)
3. Utilisateur soumet
4. Contrôleur détecte : use_free_trial manquant
5. Redirection avec message "L'essai gratuit est obligatoire pour les enfants non adhérents. Veuillez cocher la case correspondante."
6. Utilisateur coche manuellement et resoumet
7. Validation réussie
```

---

---

**Navigation** :
- [← Section précédente](09-parent-enfant.md)
- [← Retour à l'index](index.md)
- [→ Section suivante](11-metriques-kpis.md)
