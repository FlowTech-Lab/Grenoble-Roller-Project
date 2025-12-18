# 8. Tests d'Intégration Recommandés

[← Retour à l'index](index.md)

**Ordre logique d'exécution des tests** :
1. **Modèle (Membership)** : Tests de création enfant (Section 8.1)
2. **Modèle (Attendance)** : Tests de validations essai gratuit (Sections 8.2-8.5)
3. **Requête HTTP** : Tests du contrôleur complet (Section 8.6)
4. **Intégration** : Tests end-to-end parent + enfant + initiation (Section 8.7)

### 8.1. Test : Enfant Créé → Statut pending + Essai Gratuit Attribué

**Fichier** : `spec/models/membership_spec.rb`

```ruby
# spec/models/membership_spec.rb
describe "Child membership creation" do
  it "creates child in pending with free trial available" do
    parent = create(:user)
    
    # Simuler la création d'un enfant via le formulaire
    membership = Membership.create!(
      user: parent,
      status: :pending,
      is_child_membership: true,
      child_first_name: "Alice",
      child_last_name: "Dupont",
      child_date_of_birth: 10.years.ago,
      # ... autres champs requis
    )
    
    expect(membership.status).to eq(:pending)
    expect(membership.is_child_membership).to eq(true)
    
    # Vérifier que l'essai gratuit est disponible (pas de champ DB, c'est implicite)
    # L'essai gratuit est disponible si aucune attendance active avec free_trial_used = true
    expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: membership.id).exists?).to eq(false)
  end
end
```

### 8.2. Test : Essai Gratuit Utilisé lors de l'Inscription

**Fichier** : `spec/models/attendance_spec.rb`
describe "Free trial usage on initiation registration" do
  it "marks free trial as used on first initiation" do
    parent = create(:user)
    child = create(:membership, 
      user: parent, 
      status: :pending, 
      is_child_membership: true
    )
    initiation = create(:initiation)
    
    # Créer l'attendance avec essai gratuit
    attendance = Attendance.create!(
      user: parent,
      event: initiation,
      child_membership_id: child.id,
      free_trial_used: true,
      status: :registered
    )
    
    expect(attendance.free_trial_used).to eq(true)
    expect(attendance.status).to eq(:registered)
    
    # Vérifier que l'essai gratuit est maintenant "utilisé"
    expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: child.id).exists?).to eq(true)
  end
end
```

### 8.3. Test : Essai Gratuit Non Réutilisable

**Fichier** : `spec/models/attendance_spec.rb`
describe "Free trial non-reusability" do
  it "prevents second initiation with same child free trial" do
    parent = create(:user)
    child = create(:membership, 
      user: parent, 
      status: :pending, 
      is_child_membership: true
    )
    initiation1 = create(:initiation)
    initiation2 = create(:initiation)
    
    # Première inscription
    attendance1 = create(:attendance,
      user: parent,
      event: initiation1,
      child_membership_id: child.id,
      free_trial_used: true,
      status: :registered
    )
    
    # Deuxième inscription (devrait être bloquée)
    attendance2 = build(:attendance,
      user: parent,
      event: initiation2,
      child_membership_id: child.id,
      free_trial_used: true
    )
    
    expect(attendance2).not_to be_valid
    expect(attendance2.errors[:free_trial_used]).to be_present
  end
end
```

### 8.4. Test : Essai Gratuit Réutilisable après Annulation

**Fichier** : `spec/models/attendance_spec.rb`
describe "Free trial reuse after cancellation" do
  it "allows free trial reuse after cancellation" do
    parent = create(:user)
    child = create(:membership, 
      user: parent, 
      status: :pending, 
      is_child_membership: true
    )
    initiation1 = create(:initiation)
    initiation2 = create(:initiation)
    
    # Première inscription
    attendance1 = create(:attendance,
      user: parent,
      event: initiation1,
      child_membership_id: child.id,
      free_trial_used: true,
      status: :registered
    )
    
    # Annulation
    attendance1.update!(status: :canceled)
    
    # Deuxième inscription (devrait être possible)
    attendance2 = build(:attendance,
      user: parent,
      event: initiation2,
      child_membership_id: child.id,
      free_trial_used: true
    )
    
    # Le scope .active exclut canceled, donc l'essai est disponible
    expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: child.id).exists?).to eq(false)
    expect(attendance2).to be_valid
  end
end
```

### 8.5. Test : Race Condition Protection

```ruby
# spec/models/attendance_spec.rb
describe "Race condition protection" do
  it "prevents double free trial usage in parallel requests" do
    parent = create(:user)
    child = create(:membership, 
      user: parent, 
      status: :pending, 
      is_child_membership: true
    )
    initiation = create(:initiation)
    
    # Simuler deux requêtes parallèles
    threads = []
    2.times do
      threads << Thread.new do
        Attendance.create!(
          user: parent,
          event: initiation,
          child_membership_id: child.id,
          free_trial_used: true,
          status: :registered
        )
      end
    end
    
    threads.each(&:join)
    
    # Seule une attendance devrait être créée (grâce à la contrainte unique)
    expect(parent.attendances.active.where(free_trial_used: true, child_membership_id: child.id).count).to eq(1)
  end
end
```

### 8.6. Test : JavaScript Désactivé

**Fichier** : `spec/requests/initiations/attendances_spec.rb`
describe "Without JavaScript" do
  it "validates free trial requirement server-side" do
    parent = create(:user)
    child = create(:membership, 
      user: parent, 
      status: :trial,  # Statut trial = essai gratuit obligatoire
      is_child_membership: true
    )
    initiation = create(:initiation)
    
    # Soumission sans paramètre use_free_trial (simule JS désactivé)
    post initiation_attendances_path(initiation), params: {
      child_membership_id: child.id
      # Pas de use_free_trial
    }
    
    expect(response).to have_http_status(:redirect)
    expect(Attendance.count).to eq(0)
    expect(flash[:alert]).to include("L'essai gratuit est obligatoire")
  end
end
```

---

---

**Navigation** :
- [← Section précédente](07-cycle-vie-statuts.md)
- [← Retour à l'index](index.md)
- [→ Section suivante](09-parent-enfant.md)
