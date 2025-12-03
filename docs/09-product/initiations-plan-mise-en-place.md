# Plan de Mise en Place - Module Initiations

**Date** : 2025-12-02  
**Méthodologie** : Shape Up (6 semaines cycle)  
**Date cible MVP** : Janvier 2026  
**Durée estimée** : 3 semaines (Building) + 1 semaine (Cooldown)

---

## 📋 PRINCIPE SHAPE UP

**Appetite fixe (3 semaines), scope flexible** - Si pas fini → réduire scope, pas étendre deadline.

### 4 Phases Shape Up
1. **SHAPING** (2-3 jours) : Définir les limites ✅ **TERMINÉ**
2. **BETTING TABLE** (1 jour) : Priorisation brutale ✅ **TERMINÉ**
3. **BUILDING** (Semaines 1-3) : Livrer feature shippable 🔄 **EN COURS**
4. **COOLDOWN** (Semaine 4) : Repos obligatoire 📅 **À VENIR**

---

## 🎯 SÉQUENCE CRITIQUE RAILS 8 (Ordre à Respecter)

```
JOUR 1: Migrations + Modèles STI
  ↓
JOUR 2-3: Validations + Scopes + Tests unitaires (>70%)
  ↓
JOUR 4: Contrôleurs + Routes publiques
  ↓
JOUR 5-6: Vues + Formulaire inscription
  ↓
JOUR 7: Permissions Pundit + Validations métier
  ↓
JOUR 8-9: ActiveAdmin + Dashboard bénévoles
  ↓
JOUR 10: Notifications email (adapter EventMailer)
  ↓
JOUR 11-12: Tests intégration + Validation
  ↓
JOUR 13-15: Optimisations + Finalisation
```

---

## 📅 SPRINT 1 : FONDATIONS (Semaine 1)

### Jour 1 : Migrations + Modèles STI ✅ **TERMINÉ**

#### 1.1 Migration Base de Données ✅ **TERMINÉ**

**⚠️ RECOMMANDATION CRITIQUE : Vérification STI**

**AVANT d'ajouter la colonne `:type`** :
- Vérifier que la table `events` n'a **PAS déjà** de colonne `type`
- Si colonne existe → STI déjà configuré, ne pas la recréer
- Si colonne n'existe pas → Ajouter avec valeur par défaut `'Event::Rando'` pour les événements existants

**Migration 1 : Extension `events` pour STI**

```ruby
# db/migrate/YYYYMMDDHHMMSS_add_initiation_fields_to_events.rb
class AddInitiationFieldsToEvents < ActiveRecord::Migration[8.0]
  def change
    # Safety check : Vérifier si colonne type existe déjà
    unless column_exists?(:events, :type)
      add_column :events, :type, :string, default: 'Event::Rando'
      add_index :events, :type
    end
    
    add_column :events, :is_recurring, :boolean, default: false
    add_column :events, :recurring_day, :string
    add_column :events, :recurring_time, :string
    add_column :events, :season, :string
    add_column :events, :recurring_start_date, :date
    add_column :events, :recurring_end_date, :date
    
    add_index :events, [:type, :season]
    add_index :events, [:status, :start_at] # Déjà existe, vérifier
  end
end
```

**Migration 2 : Extension `attendances`**

```ruby
# db/migrate/YYYYMMDDHHMMSS_add_initiation_fields_to_attendances.rb
class AddInitiationFieldsToAttendances < ActiveRecord::Migration[8.0]
  def change
    add_column :attendances, :free_trial_used, :boolean, default: false
    add_column :attendances, :is_volunteer, :boolean, default: false
    add_column :attendances, :equipment_note, :text
    
    add_index :attendances, [:event_id, :is_volunteer]
    add_index :attendances, [:user_id, :free_trial_used]
  end
end
```

**Checklist** :
- [x] **Vérifier Event n'a pas déjà colonne `:type`** (safety check) ✅
- [x] Créer les migrations ✅
  - [x] `20251203172509_add_initiation_fields_to_events.rb` ✅
  - [x] `20251203172510_add_initiation_fields_to_attendances.rb` ✅
- [x] Appliquer migrations (`rails db:migrate`) ✅
- [x] Vérifier indexes créés ✅
- [x] **Corriger données existantes** (type = 'Event' au lieu de 'Event::Rando') ✅
- [ ] **Tester rollback migration** (`rails db:rollback` puis `rails db:migrate`) 🔄 **À FAIRE**

#### 1.2 Modèles STI

**Créer `app/models/event/initiation.rb`**

```ruby
class Event::Initiation < Event
  # Scopes spécifiques
  scope :by_season, ->(season) { where(season: season) }
  scope :upcoming_initiations, -> { where("start_at > ?", Time.current).order(:start_at) }
  
  # Validations spécifiques
  validates :season, presence: true
  validates :max_participants, presence: true, numericality: { greater_than: 0 }
  validate :is_saturday, :is_correct_time, :is_correct_location
  
  # Méthodes métier
  def full?
    available_places <= 0
  end
  
  def available_places
    max_participants - participants_count
  end
  
  def participants_count
    attendances.where(is_volunteer: false, status: ['registered', 'present']).count
  end
  
  def volunteers_count
    attendances.where(is_volunteer: true).count
  end
  
  private
  
  def is_saturday
    errors.add(:start_at, "must be a Saturday") unless start_at&.saturday?
  end
  
  def is_correct_time
    return unless start_at
    errors.add(:start_at, "must start at 10:15") unless start_at.hour == 10 && start_at.min == 15
  end
  
  def is_correct_location
    return unless location_text
    errors.add(:location_text, "must be Gymnase Ampère") unless location_text.include?("Gymnase Ampère")
  end
end
```

**Adapter `app/models/attendance.rb`**

```ruby
# Ajouter dans Attendance
validates :free_trial_used, inclusion: { in: [true, false] }
validate :can_use_free_trial, on: :create

scope :volunteers, -> { where(is_volunteer: true) }
scope :participants, -> { where(is_volunteer: false) }

private

def can_use_free_trial
  return unless free_trial_used
  return unless user
  
  if user.attendances.where(free_trial_used: true).exists?
    errors.add(:free_trial_used, "Vous avez déjà utilisé votre essai gratuit")
  end
end
```

**Checklist** :
- [x] Créer modèle `Event::Initiation` ✅
  - [x] Fichier `app/models/event/initiation.rb` créé ✅
- [x] Ajouter validations spécifiques ✅
  - [x] Validation samedi ✅
  - [x] Validation horaire 10h15 ✅
  - [x] Validation lieu Gymnase Ampère ✅
- [x] Ajouter scopes ✅
  - [x] `by_season` ✅
  - [x] `upcoming_initiations` ✅
- [x] Ajouter méthodes métier ✅
  - [x] `full?` ✅
  - [x] `available_places` ✅
  - [x] `participants_count` ✅
  - [x] `volunteers_count` ✅
  - [x] Override `unlimited?` → toujours false ✅
- [x] Adapter `Attendance` avec nouvelles validations ✅
  - [x] Validation `free_trial_used` ✅
  - [x] Validation `can_use_free_trial` ✅
  - [x] Validation `can_register_to_initiation` ✅
  - [x] Scopes `volunteers` et `participants` ✅
  - [x] Adaptation `event_has_available_spots` (bénévoles bypass) ✅
- [ ] Tests unitaires modèles (voir Jour 2-3) 🔄 **PROCHAINE ÉTAPE**

---

### Jour 2-3 : Validations + Scopes + Tests Unitaires

#### 2.1 Tests Modèles (RSpec)

**Créer `spec/models/event/initiation_spec.rb`**

```ruby
RSpec.describe Event::Initiation, type: :model do
  describe "validations" do
    it "requires season" do
      initiation = build(:event_initiation, season: nil)
      expect(initiation).not_to be_valid
    end
    
    it "requires max_participants > 0" do
      initiation = build(:event_initiation, max_participants: 0)
      expect(initiation).not_to be_valid
    end
    
    it "must be on Saturday" do
      initiation = build(:event_initiation, start_at: Time.zone.parse("2025-12-01 10:15")) # Dimanche
      expect(initiation).not_to be_valid
    end
    
    it "must start at 10:15" do
      initiation = build(:event_initiation, start_at: Time.zone.parse("2025-12-06 11:00")) # Samedi mais 11h
      expect(initiation).not_to be_valid
    end
  end
  
  describe "#full?" do
    it "returns true when no places available" do
      initiation = create(:event_initiation, max_participants: 2)
      create_list(:attendance, 2, event: initiation, is_volunteer: false)
      expect(initiation.full?).to be true
    end
    
    it "returns false when places available" do
      initiation = create(:event_initiation, max_participants: 30)
      create_list(:attendance, 10, event: initiation, is_volunteer: false)
      expect(initiation.full?).to be false
    end
    
    it "does not count volunteers" do
      initiation = create(:event_initiation, max_participants: 1)
      create(:attendance, event: initiation, is_volunteer: true)
      create(:attendance, event: initiation, is_volunteer: false)
      expect(initiation.full?).to be true
    end
  end
  
  describe "#available_places" do
    it "calculates correctly" do
      initiation = create(:event_initiation, max_participants: 30)
      create_list(:attendance, 5, event: initiation, is_volunteer: false)
      expect(initiation.available_places).to eq(25)
    end
  end
end
```

**Créer `spec/models/attendance_spec.rb` (extension)**

```ruby
RSpec.describe Attendance, type: :model do
  describe "free_trial_used" do
    it "prevents using free trial twice" do
      user = create(:user)
      create(:attendance, user: user, free_trial_used: true)
      
      new_attendance = build(:attendance, user: user, free_trial_used: true)
      expect(new_attendance).not_to be_valid
    end
    
    it "allows free trial if never used" do
      user = create(:user)
      attendance = build(:attendance, user: user, free_trial_used: true)
      expect(attendance).to be_valid
    end
  end
  
  describe "scopes" do
    it "filters volunteers" do
      volunteer = create(:attendance, is_volunteer: true)
      participant = create(:attendance, is_volunteer: false)
      
      expect(Attendance.volunteers).to include(volunteer)
      expect(Attendance.volunteers).not_to include(participant)
    end
  end
end
```

**Créer factories**

```ruby
# spec/factories/event/initiations.rb
FactoryBot.define do
  factory :event_initiation, class: 'Event::Initiation' do
    association :creator_user, factory: :user
    type { 'Event::Initiation' }
    title { "Initiation Roller - Samedi #{start_at.strftime('%d %B %Y')}" }
    description { "Cours d'initiation au roller pour débutants" }
    start_at { next_saturday_at_10_15 }
    duration_min { 105 } # 1h45
    location_text { "Gymnase Ampère, 74 Rue Anatole France, 38100 Grenoble" }
    meeting_lat { 45.1891 }
    meeting_lng { 5.7317 }
    max_participants { 30 }
    status { 'published' }
    season { Membership.current_season_name }
    is_recurring { true }
    recurring_day { 'saturday' }
    recurring_time { '10:15' }
    level { 'beginner' }
    distance_km { 0 }
    price_cents { 0 }
    currency { 'EUR' }
  end
  
  trait :full do
    after(:create) do |initiation|
      create_list(:attendance, initiation.max_participants, event: initiation, is_volunteer: false)
    end
  end
end

def next_saturday_at_10_15
  today = Date.today
  days_until_saturday = (6 - today.wday) % 7
  days_until_saturday = 7 if days_until_saturday == 0 && Time.current.hour >= 10
  (today + days_until_saturday.days).beginning_of_day + 10.hours + 15.minutes
end
```

**⚠️ RECOMMANDATION CRITIQUE : Tests Validations Métier**

**Ajouter tests spécifiques initiations** :

- [ ] **Tester cas "séance complète"** : Empêcher inscription non-bénévole si `full?`
- [ ] **Tester cas "bénévole bypass"** : Permettre inscription bénévole même si séance complète
- [ ] **Tester "essai gratuit déjà utilisé"** : Empêcher réutilisation essai gratuit
- [ ] **Tester cas "enfant"** : Vérifier adhésion enfant acceptée
- [ ] **Tester parcours utilisateur complet** : Inscription → Email → Réutilisation essai = erreur

**Checklist** :
- [ ] Créer tests modèles `Event::Initiation`
- [ ] Créer tests extension `Attendance`
- [ ] **Créer tests validations métier (essai, adhésion, places)**
- [ ] **Créer tests cas enfants**
- [ ] **Créer tests parcours utilisateur complet**
- [ ] Créer factories
- [ ] Coverage >70% (`bundle exec rspec spec/models`)
- [ ] Tous les tests passent

---

### Jour 4 : Contrôleurs + Routes Publiques

#### 4.1 Routes

**Ajouter dans `config/routes.rb`**

```ruby
resources :initiations, only: [:index, :show] do
  member do
    post :register
    delete :cancel_registration
  end
end
```

#### 4.2 Contrôleur `InitiationsController`

**⚠️ RECOMMANDATION CRITIQUE : Gestion Cas Enfants**

**Adapter la méthode `register` pour gérer les enfants** :
- Vérifier adhésion parent **OU** adhésion enfant active
- Permettre `child_membership_id` dans les params si parent inscrit un enfant
- Vérifier que l'enfant a bien une adhésion active si `child_membership_id` présent

**Créer `app/controllers/initiations_controller.rb`**

```ruby
class InitiationsController < ApplicationController
  before_action :set_initiation, only: [:show, :register, :cancel_registration]
  before_action :authenticate_user!, only: [:register, :cancel_registration]
  
  def index
    @initiations = Event::Initiation
      .published
      .upcoming_initiations
      .limit(12) # 3 mois
      .includes(:creator_user)
    
    @current_season = Membership.current_season_name
  end
  
  def show
    authorize @initiation
    @user_attendance = current_user&.attendances&.find_by(event: @initiation)
    @can_register = can_register?
  end
  
  def register
    authorize @initiation, :register?
    
    attendance = @initiation.attendances.find_or_initialize_by(user: current_user)
    
    if attendance.persisted?
      redirect_to @initiation, notice: "Vous êtes déjà inscrit(e)."
      return
    end
    
    attendance.assign_attributes(attendance_params)
    attendance.status = 'registered'
    
    # Gestion essai gratuit
    if params[:use_free_trial] == '1'
      if current_user.attendances.where(free_trial_used: true).exists?
        redirect_to @initiation, alert: "Vous avez déjà utilisé votre essai gratuit."
        return
      end
      attendance.free_trial_used = true
    else
      # ⚠️ AJOUTER : Vérifier adhésion (parent OU enfant)
      has_active_membership = current_user.memberships.active_now.exists?
      has_child_membership = current_user.memberships.active_now.where(is_child_membership: true).exists?
      
      unless has_active_membership || has_child_membership
        redirect_to @initiation, alert: "Adhésion requise. Utilisez votre essai gratuit ou adhérez à l'association."
        return
      end
    end
    
    if attendance.save
      EventMailer.attendance_confirmed(attendance).deliver_later
      redirect_to @initiation, notice: "Inscription confirmée pour le #{l(@initiation.start_at, format: :long)}."
    else
      redirect_to @initiation, alert: attendance.errors.full_messages.to_sentence
    end
  end
  
  def cancel_registration
    authorize @initiation, :cancel_registration?
    
    attendance = @initiation.attendances.find_by(user: current_user)
    if attendance&.destroy
      EventMailer.attendance_cancelled(current_user, @initiation).deliver_later
      redirect_to @initiation, notice: "Inscription annulée."
    else
      redirect_to @initiation, alert: "Impossible d'annuler votre participation."
    end
  end
  
  private
  
  def set_initiation
    @initiation = Event::Initiation.find(params[:id])
  end
  
  def attendance_params
    # ⚠️ AJOUTER : child_membership_id si c'est un enfant qui s'inscrit
    params.require(:attendance).permit(:wants_reminder, :equipment_note, :child_membership_id)
  end
  
  def can_register?
    return false unless user_signed_in?
    return false if @initiation.full?
    return false if @user_attendance&.persisted?
    
    # Vérifier adhésion ou essai gratuit disponible
    current_user.memberships.active_now.exists? || 
      !current_user.attendances.where(free_trial_used: true).exists?
  end
  helper_method :can_register?
end
```

#### 4.3 Policy Pundit

**Créer `app/policies/initiation_policy.rb`**

```ruby
class InitiationPolicy < ApplicationPolicy
  def index?
    true # Tous peuvent voir la liste
  end
  
  def show?
    true # Tous peuvent voir une initiation
  end
  
  def register?
    return false unless user
    return false if record.full?
    return false if user.attendances.exists?(event: record)
    
    # Vérifier adhésion ou essai gratuit disponible
    user.memberships.active_now.exists? || 
      !user.attendances.where(free_trial_used: true).exists?
  end
  
  def cancel_registration?
    return false unless user
    user.attendances.exists?(event: record)
  end
  
  def manage?
    user&.role&.level.to_i >= 30 # INSTRUCTOR+
  end
  
  class Scope < Scope
    def resolve
      scope.published
    end
  end
end
```

**Checklist** :
- [ ] Créer routes
- [ ] Créer contrôleur `InitiationsController`
- [ ] Créer policy `InitiationPolicy`
- [ ] Tests contrôleur (RSpec requests)
- [ ] Tests policy (RSpec)

---

### Jour 5-6 : Vues + Formulaire Inscription

#### 5.1 Vue Index

**Créer `app/views/initiations/index.html.erb`**

```erb
<div class="container py-4">
  <div class="hero-memberships mb-4">
    <h1 class="h2 mb-2">
      <i class="bi bi-book-fill me-2 fs-2"></i>
      Initiations Roller
    </h1>
    <p class="mb-2 opacity-75">
      Cours d'initiation tous les samedis matin de 10h15 à 12h00
    </p>
  </div>
  
  <!-- Infos statiques -->
  <div class="card card-liquid shadow-sm mb-4">
    <div class="card-body">
      <h2 class="h5 mb-3">Informations pratiques</h2>
      <ul class="list-unstyled">
        <li><i class="bi bi-clock me-2"></i><strong>Horaires :</strong> Samedi 10h15-12h00</li>
        <li><i class="bi bi-geo-alt me-2"></i><strong>Lieu :</strong> Gymnase Ampère, 74 Rue Anatole France, 38100 Grenoble</li>
        <li><i class="bi bi-people me-2"></i><strong>Public :</strong> Adhérents, enfants dès 6 ans (adulte obligatoire)</li>
        <li><i class="bi bi-tag me-2"></i><strong>Tarif :</strong> Gratuit après adhésion 10€</li>
        <li><i class="bi bi-gift me-2"></i><strong>Essai gratuit :</strong> 1 essai sans adhésion</li>
      </ul>
    </div>
  </div>
  
  <!-- Liste séances -->
  <div class="row g-3">
    <% @initiations.each do |initiation| %>
      <div class="col-12 col-md-6 col-lg-4">
        <%= render 'initiation_card', initiation: initiation %>
      </div>
    <% end %>
  </div>
</div>
```

#### 5.2 Vue Show

**Créer `app/views/initiations/show.html.erb`**

```erb
<div class="container py-4">
  <div class="card card-liquid shadow-sm">
    <div class="card-body">
      <h1 class="h3 mb-3"><%= @initiation.title %></h1>
      
      <div class="mb-4">
        <p><i class="bi bi-calendar me-2"></i><%= l(@initiation.start_at, format: :long) %></p>
        <p><i class="bi bi-geo-alt me-2"></i><%= @initiation.location_text %></p>
        <p><i class="bi bi-people me-2"></i><%= @initiation.available_places %> / <%= @initiation.max_participants %> places disponibles</p>
      </div>
      
      <% if @can_register %>
        <%= render 'registration_form', initiation: @initiation %>
      <% elsif @user_attendance %>
        <div class="alert alert-success">
          <p>Vous êtes inscrit(e) à cette séance.</p>
          <%= button_to "Annuler mon inscription", initiation_cancel_registration_path(@initiation), 
              method: :delete, class: "btn btn-danger" %>
        </div>
      <% else %>
        <div class="alert alert-warning">
          <% if @initiation.full? %>
            <p>Cette séance est complète.</p>
          <% else %>
            <p>Vous devez être connecté(e) et avoir une adhésion active pour vous inscrire.</p>
            <%= link_to "Se connecter", new_user_session_path, class: "btn btn-primary" %>
          <% end %>
        </div>
      <% end %>
    </div>
  </div>
</div>
```

#### 5.3 Formulaire Inscription

**⚠️ RECOMMANDATION CRITIQUE : Sélection Enfant**

**Ajouter sélection enfant dans le formulaire** :
- Si parent a des adhésions enfants actives → Afficher dropdown
- Permettre de choisir "S'inscrire pour moi-même" ou "S'inscrire pour [Nom Enfant]"
- Si enfant sélectionné → Vérifier adhésion enfant active

**Créer `app/views/initiations/_registration_form.html.erb`**

```erb
<%= form_with url: initiation_register_path(initiation), method: :post, local: true do |f| %>
  
  <!-- ⚠️ AJOUTER : Sélection enfant si applicable -->
  <% child_memberships = current_user.memberships.active_now.where(is_child_membership: true) %>
  <% if child_memberships.any? %>
    <div class="mb-3">
      <%= f.label :child_membership_id, "S'inscrire pour un enfant (optionnel)", class: "form-label" %>
      <%= f.collection_select :child_membership_id, child_memberships, :id, 
          ->(m) { "#{m.child_first_name} #{m.child_last_name}" }, 
          { prompt: "S'inscrire pour moi-même", include_blank: true }, 
          { class: "form-select" } %>
      <small class="text-muted">Laissez vide pour vous inscrire vous-même</small>
    </div>
  <% end %>
  
  <div class="mb-3">
    <%= f.label :equipment_note, "Demande de matériel (optionnel)", class: "form-label" %>
    <%= f.text_area :equipment_note, class: "form-control", 
        placeholder: "Ex: Demande rollers taille 40" %>
    <small class="text-muted">Votre demande sera transmise au staff via WhatsApp</small>
  </div>
  
  <% if current_user.memberships.active_now.empty? && 
        !current_user.attendances.where(free_trial_used: true).exists? %>
    <div class="mb-3 form-check">
      <%= f.check_box :use_free_trial, { class: "form-check-input" }, "1", "0" %>
      <%= f.label :use_free_trial, "Utiliser mon essai gratuit", class: "form-check-label" %>
    </div>
  <% end %>
  
  <div class="mb-3 form-check">
    <%= f.check_box :wants_reminder, { checked: true, class: "form-check-input" }, "1", "0" %>
    <%= f.label :wants_reminder, "Recevoir un rappel la veille à 19h", class: "form-check-label" %>
  </div>
  
  <%= f.submit "S'inscrire", class: "btn btn-primary btn-lg" %>
<% end %>
```

**Checklist** :
- [ ] Créer vue index
- [ ] Créer vue show
- [ ] Créer formulaire inscription
- [ ] **Ajouter sélection enfant dans formulaire**
- [ ] Créer partial `_initiation_card`
- [ ] Tests vues (RSpec requests)
- [ ] **Responsive mobile** (tester sur mobile réel)

---

### Jour 7 : Permissions Pundit + Validations Métier

#### 7.1 Finaliser Permissions

**Adapter `app/policies/initiation_policy.rb`** (voir Jour 4)

**Créer `app/policies/attendance_policy.rb`** (extension)

```ruby
class AttendancePolicy < ApplicationPolicy
  def mark_presence?
    return false unless user
    return false unless record.event.is_a?(Event::Initiation)
    user.role&.level.to_i >= 30 # INSTRUCTOR+
  end
  
  def toggle_volunteer?
    mark_presence? # Même permission
  end
end
```

#### 7.2 Validations Métier

**Adapter `app/models/attendance.rb`**

```ruby
validate :can_register_to_initiation, on: :create

private

def can_register_to_initiation
  return unless event.is_a?(Event::Initiation)
  return if is_volunteer # Bénévoles bypassent les validations
  
  # Vérifier places disponibles
  if event.full?
    errors.add(:event, "Cette séance est complète")
    return
  end
  
  # Vérifier adhésion ou essai gratuit
  if free_trial_used
    # Essai utilisé → vérifier qu'il n'a pas déjà été utilisé
    if user.attendances.where(free_trial_used: true).where.not(id: id).exists?
      errors.add(:free_trial_used, "Vous avez déjà utilisé votre essai gratuit")
    end
  else
    # Pas d'essai → vérifier adhésion active
    unless user.memberships.active_now.exists?
      errors.add(:base, "Adhésion requise. Utilisez votre essai gratuit ou adhérez à l'association.")
    end
  end
end
```

**Checklist** :
- [ ] Finaliser permissions Pundit
- [ ] Ajouter validations métier
- [ ] Tests permissions (RSpec)
- [ ] Tests validations (RSpec)

---

### Jour 8-9 : ActiveAdmin + Dashboard Bénévoles

#### 8.1 ActiveAdmin Resource

**⚠️ RECOMMANDATION CRITIQUE : Export Demandes Matériel**

**Ajouter export pour WhatsApp** :
- Action item "Exporter demandes matériel" dans la vue show
- Format texte simple : "Nom (Téléphone): Demande matériel"
- Permet au staff de copier-coller dans WhatsApp rapidement

**Créer `app/admin/event/initiations.rb`**

```ruby
ActiveAdmin.register Event::Initiation, as: "Initiation" do
  menu label: "Initiations", priority: 3
  
  permit_params :title, :description, :start_at, :duration_min, :max_participants, 
                 :status, :season, :location_text, :meeting_lat, :meeting_lng
  
  scope :toutes
  scope :published
  scope :upcoming, default: true
  scope :full
  scope :canceled
  
  filter :season
  filter :start_at
  filter :status
  filter :creator_user
  
  index do
    selectable_column
    column :title
    column :start_at
    column :available_places do |initiation|
      "#{initiation.available_places} / #{initiation.max_participants}"
    end
    column :status
    column :season
    actions
  end
  
  show do
    attributes_table do
      row :title
      row :start_at
      row :location_text
      row :available_places do
        "#{initiation.available_places} / #{initiation.max_participants}"
      end
      row :volunteers_count
      row :status
      row :season
    end
    
    # ⚠️ AJOUTER : Action item export matériel
    action_item :export_material_demands, only: :show do
      link_to "Exporter demandes matériel", 
              admin_initiation_material_export_path(initiation),
              class: "btn btn-info"
    end
    
    panel "Inscriptions" do
      table_for initiation.attendances.includes(:user) do
        column :user do |attendance|
          attendance.user.full_name
        end
        column :email do |attendance|
          attendance.user.email
        end
        column :free_trial_used
        column :is_volunteer
        column :equipment_note
        column :status do |attendance|
          status_tag attendance.status
        end
        column :actions do |attendance|
          link_to "Pointer présence", "#", class: "btn btn-sm"
        end
      end
    end
  end
  
  form do |f|
    f.inputs do
      f.input :title
      f.input :start_at, as: :datetime_picker
      f.input :max_participants
      f.input :status, as: :select, collection: Event.statuses.keys
      f.input :season
    end
    f.actions
  end
  
  # ⚠️ AJOUTER : Route et action export matériel
  member_action :material_export do
    @initiation = resource
    @demands = @initiation.attendances
      .where("equipment_note IS NOT NULL AND equipment_note != ''")
      .includes(:user)
    
    respond_to do |format|
      format.txt do
        render plain: generate_material_text(@demands)
      end
    end
  end
  
  private
  
  def generate_material_text(demands)
    demands.map do |att|
      phone = att.user.phone.present? ? att.user.phone : "Pas de téléphone"
      "#{att.user.full_name} (#{phone}): #{att.equipment_note}"
    end.join("\n")
  end
end
```

**Ajouter route dans `config/routes.rb`** :

```ruby
namespace :admin do
  resources :initiations, only: [] do
    member do
      get :material_export
    end
  end
end
```

#### 8.2 Dashboard Bénévoles

**Créer `app/controllers/admin/initiations_controller.rb`**

```ruby
module Admin
  class InitiationsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_instructor!
    before_action :set_initiation, only: [:show, :update_presences]
    
    def show
      @attendances = @initiation.attendances.includes(:user).order(:created_at)
    end
    
    def update_presences
      params[:presences].each do |attendance_id, status|
        attendance = @initiation.attendances.find(attendance_id)
        attendance.update(status: status)
      end
      
      redirect_to admin_initiation_path(@initiation), notice: "Présences mises à jour."
    end
    
    private
    
    def set_initiation
      @initiation = Event::Initiation.find(params[:id])
    end
    
    def ensure_instructor!
      unless current_user.role&.level.to_i >= 30
        redirect_to root_path, alert: "Accès réservé aux encadrants."
      end
    end
  end
end
```

**Créer `app/views/admin/initiations/show.html.erb`**

```erb
<div class="container py-4">
  <h1 class="h3 mb-4"><%= @initiation.title %></h1>
  
  <%= form_with url: admin_initiation_update_presences_path(@initiation), method: :patch do |f| %>
    <table class="table">
      <thead>
        <tr>
          <th>Nom</th>
          <th>Email</th>
          <th>Matériel</th>
          <th>Présent</th>
          <th>Absent</th>
        </tr>
      </thead>
      <tbody>
        <% @attendances.each do |attendance| %>
          <tr>
            <td><%= attendance.user.full_name %></td>
            <td><%= attendance.user.email %></td>
            <td><%= attendance.equipment_note %></td>
            <td>
              <%= radio_button_tag "presences[#{attendance.id}]", "present", 
                  attendance.status == 'present' %>
            </td>
            <td>
              <%= radio_button_tag "presences[#{attendance.id}]", "absent", 
                  attendance.status == 'absent' %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
    
    <%= f.submit "Sauvegarder présences", class: "btn btn-primary" %>
  <% end %>
</div>
```

**Checklist** :
- [ ] Créer resource ActiveAdmin
- [ ] **Ajouter export demandes matériel (pour WhatsApp)**
- [ ] Créer dashboard bénévoles
- [ ] Tests admin (RSpec)
- [ ] **Tester interface mobile** (vérifier responsive sur mobile réel)

---

### Jour 10 : Notifications Email

#### 10.1 Adapter EventMailer

**Adapter `app/mailers/event_mailer.rb`**

```ruby
def attendance_confirmed(attendance)
  @attendance = attendance
  @event = attendance.event
  @user = attendance.user
  
  mail(
    to: @user.email,
    subject: "Inscription confirmée - #{@event.title}"
  )
end
```

**Adapter template `app/views/event_mailer/attendance_confirmed.html.erb`**

```erb
<h2>Inscription confirmée</h2>
<p>Bonjour <%= @user.first_name %>,</p>
<p>Votre inscription à l'initiation du <%= l(@event.start_at, format: :long) %> est confirmée.</p>

<% if @event.is_a?(Event::Initiation) %>
  <h3>Informations pratiques</h3>
  <ul>
    <li><strong>Lieu :</strong> <%= @event.location_text %></li>
    <li><strong>Horaire :</strong> <%= l(@event.start_at, format: :time) %> - <%= l(@event.end_at, format: :time) %></li>
    <% if @attendance.free_trial_used %>
      <li><strong>Essai gratuit utilisé</strong> - Adhésion requise pour les prochaines séances</li>
    <% end %>
    <% if @attendance.equipment_note.present? %>
      <li><strong>Matériel demandé :</strong> <%= @attendance.equipment_note %></li>
    <% end %>
  </ul>
<% end %>

<% if @attendance.wants_reminder? %>
  <p>Un rappel vous sera envoyé la veille à 19h.</p>
<% end %>
```

**Checklist** :
- [ ] Adapter EventMailer
- [ ] Adapter templates email
- [ ] Tests mailers (RSpec)
- [ ] Vérifier envoi réel (dev)

---

### Jour 11-12 : Tests Intégration + Validation

#### 11.1 Tests Intégration

**⚠️ RECOMMANDATION CRITIQUE : Tests Parcours Utilisateur Complet**

**Créer `spec/requests/initiations_spec.rb`**

```ruby
RSpec.describe "Initiations", type: :request do
  let(:user) { create(:user) }
  let(:initiation) { create(:event_initiation) }
  
  describe "GET /initiations" do
    it "returns success" do
      get initiations_path
      expect(response).to have_http_status(:success)
    end
  end
  
  describe "POST /initiations/:id/register" do
    before { sign_in user }
    
    context "with valid membership" do
      before { create(:membership, user: user, status: :active) }
      
      it "creates attendance" do
        expect {
          post initiation_register_path(initiation), params: {
            attendance: { wants_reminder: true }
          }
        }.to change(Attendance, :count).by(1)
      end
    end
    
    context "with free trial" do
      it "uses free trial" do
        post initiation_register_path(initiation), params: {
          attendance: { wants_reminder: true },
          use_free_trial: "1"
        }
        
        attendance = Attendance.last
        expect(attendance.free_trial_used).to be true
      end
    end
  end
end
```

**⚠️ AJOUTER : Tests Parcours Utilisateur Complet**

**Créer `spec/requests/initiations_user_journey_spec.rb`**

```ruby
RSpec.describe "Initiation user journeys", type: :request do
  let(:user_no_membership) { create(:user) }
  let(:initiation) { create(:event_initiation) }
  
  describe "Free trial journey" do
    it "allows non-member to register with free trial" do
      sign_in user_no_membership
      
      # 1. Voir liste initiations
      get initiations_path
      expect(response).to have_http_status(:success)
      
      # 2. S'inscrire avec essai gratuit
      post initiation_register_path(initiation), params: {
        attendance: { wants_reminder: true },
        use_free_trial: "1"
      }
      expect(response).to redirect_to(initiation_path(initiation))
      
      # 3. Vérifier inscription
      attendance = Attendance.last
      expect(attendance.free_trial_used).to be true
      expect(attendance.user).to eq(user_no_membership)
      
      # 4. Recevoir email confirmation
      expect(ActionMailer::Base.deliveries.last.to).to include(user_no_membership.email)
      
      # 5. Essayer de réutiliser essai = erreur
      new_initiation = create(:event_initiation, start_at: 1.week.from_now)
      post initiation_register_path(new_initiation), params: {
        attendance: { wants_reminder: true },
        use_free_trial: "1"
      }
      expect(response).to redirect_to(new_initiation_path(new_initiation))
      expect(flash[:alert]).to include("essai gratuit")
    end
  end
end
```

**Checklist** :
- [ ] Tests requests initiations
- [ ] **Tests parcours utilisateur complet** (essai gratuit → email → réutilisation = erreur)
- [ ] **Tests cas enfants** (inscription enfant avec adhésion enfant)
- [ ] Coverage >70% maintenu
- [ ] Tous les tests passent

---

### Jour 13-15 : Optimisations + Finalisation

#### 13.1 Optimisations

- [ ] Indexes database optimisés
- [ ] Requêtes N+1 corrigées (`includes`, `joins`)
- [ ] Cache fragments si nécessaire
- [ ] Performance tests

#### 13.2 Finalisation

**⚠️ RECOMMANDATION CRITIQUE : Seeds Data Initiations**

**Créer seeds pour générer automatiquement les séances récurrentes** :
- Générer 52 séances pour la saison courante (1er sept → 31 août)
- Chaque samedi à 10h15
- Statut initial : "published"
- Lieu fixe : Gymnase Ampère
- Max participants : 30

**Note** : Cette génération peut être faite via :
- Seeds (`db/seeds.rb`) pour données de test/dev
- Rake task pour production (optionnel)
- Interface admin (future amélioration)

**Checklist** :
- [ ] Documentation mise à jour
- [ ] **Créer seeds data initiations (52 séances pour saison courante)**
- [ ] Migration données existantes (si nécessaire)
- [ ] **Tester migration production (replay sur staging)**
- [ ] **Documenter rollback strategy** (procédure complète)
- [ ] Audit sécurité (Brakeman)
- [ ] Revue code finale

---

## 📊 MÉTRIQUES DE SUCCÈS

### Techniques
- ✅ Coverage >70% maintenu
- ✅ 0 erreur de linting
- ✅ Temps de réponse < 200ms
- ✅ Tous les tests passent

### Fonctionnelles
- ✅ Inscription initiation < 2 minutes
- ✅ Pointage présence < 30 secondes
- ✅ Génération séances automatique < 5 secondes

---

## 🚨 POINTS CRITIQUES & ERREURS À ÉVITER

### ❌ Erreurs Fréquentes
1. **Modèles instables avant ActiveAdmin** → Tests >70% AVANT ActiveAdmin
2. **Oublier validations métier** → Essai gratuit, adhésion, places
3. **N+1 queries** → Toujours `includes(:user)` sur attendances
4. **Permissions oubliées** → Pundit sur toutes les actions
5. **Tests à la fin** → TDD dès le début
6. **Oublier cas enfants** → Vérifier adhésion enfant dans contrôleur
7. **Interface non-responsive** → Tester sur mobile réel avant production

### ✅ Bonnes Pratiques Rails 8
1. **STI pour Event::Initiation** → Réutilise Event existant
2. **Tests TDD** → Unitaires + intégration dès le début
3. **ActiveAdmin après tests** → Jour 8-9 uniquement
4. **Validations métier** → Dans modèles, pas contrôleurs
5. **Permissions Pundit** → Policies pour toutes les actions
6. **Vérifier colonne type** → Safety check avant migration STI
7. **Tests parcours complet** → Détecte bugs cachés

### 🔴 RISQUES À SURVEILLER (Semaine Critique)

#### Jour 1 : Migrations
- **Risque** : Conflit avec migration events existante
- **Protection** : Vérifier `schema.rb` avant migration, tester rollback

#### Jour 2-3 : Tests
- **Risque** : Tests qui passent mais logique métier buggée
- **Protection** : Tests du parcours utilisateur complet (voir Jour 11-12)

#### Jour 4 : Contrôleurs
- **Risque** : Oublier validation adhésion enfant
- **Protection** : Utiliser checklist enfant (voir Jour 4)

#### Jour 8-9 : ActiveAdmin
- **Risque** : Interface non-responsive mobile
- **Protection** : Tester sur mobile avant Jour 9

#### Jour 11-12 : Production
- **Risque** : Migration échoue → rollback complexe
- **Protection** : Tester rollback Jour 12, documenter procédure

---

## 📋 CHECKLIST FINALE AVANT PRODUCTION

### Code
- [ ] Tous les tests passent (>70% coverage)
- [ ] **Tests parcours utilisateur complet** (essai gratuit → email → réutilisation)
- [ ] **Tests cas enfants** (inscription avec adhésion enfant)
- [ ] Linting OK (Rubocop)
- [ ] Audit sécurité (Brakeman)
- [ ] Performance OK (< 200ms)

### Fonctionnel
- [ ] Inscription fonctionne (adulte + enfant)
- [ ] Essai gratuit fonctionne (1x max)
- [ ] Pointage présence fonctionne
- [ ] Notifications email envoyées
- [ ] Admin interface fonctionnelle
- [ ] **Export matériel fonctionne** (format WhatsApp)
- [ ] **Interface mobile testée** (responsive OK)

### Documentation
- [ ] README mis à jour
- [ ] Documentation utilisateur
- [ ] Runbook admin
- [ ] **Rollback strategy documentée** (procédure complète)

### Déploiement
- [ ] **Migration production testée** (replay sur staging)
- [ ] Seeds production prêts (52 séances saison courante)
- [ ] **Rollback strategy testée** (rollback puis re-migration)
- [ ] Monitoring configuré

---

## 📝 RÉCAPITULATIF DES RECOMMANDATIONS CRITIQUES

### ✅ Validations Positives

- **Architecture générale** : STI Event::Initiation → Réutilise Event, pas de duplication
- **Extension Attendance** : Minimale, non-invasive
- **Migrations progressives** : Jour 1, testé Jour 1-2
- **TDD dès le début** : Tests avant ActiveAdmin (bon ordre)
- **Permissions Pundit** : Jour 7, avant ActiveAdmin
- **Séquence Rails 8** : Ordre correct (Migrations → Modèles → Tests → Contrôleurs → Vues → Admin)
- **Réalisme Shape Up** : 3 semaines bâtiment, scope flexible, cooldown semaine 4

### ⚠️ Recommandations Critiques à Appliquer

#### 1. Jour 1 : Migrations
- ✅ **Vérifier Event n'a pas déjà colonne `:type`** (safety check avant STI)
- ✅ **Tester rollback migration** Jour 1 soir
- ✅ **Valeur par défaut `'Event::Rando'`** pour événements existants

#### 2. Jour 2-3 : Tests
- ✅ **Tester validations métier** (essai, adhésion, places)
- ✅ **Tester cas enfants** (adhésion enfant acceptée)
- ✅ **Tester parcours utilisateur complet** (essai gratuit → email → réutilisation = erreur)
- ✅ **Tester cas "séance complète"** : Empêcher inscription non-bénévole si `full?`
- ✅ **Tester cas "bénévole bypass"** : Permettre inscription bénévole même si séance complète

#### 3. Jour 4 : Contrôleurs
- ✅ **Gestion cas enfants** : Vérifier adhésion parent **OU** adhésion enfant active
- ✅ **Permettre `child_membership_id`** dans les params si parent inscrit un enfant
- ✅ **Vérifier adhésion enfant active** si `child_membership_id` présent

#### 4. Jour 5-6 : Vues
- ✅ **Ajouter sélection enfant dans formulaire** (dropdown si parent a adhésions enfants)
- ✅ **Tester interface mobile** (responsive sur mobile réel)

#### 5. Jour 8-9 : ActiveAdmin
- ✅ **Ajouter export demandes matériel** (format texte pour WhatsApp)
- ✅ **Tester interface mobile** (dashboard bénévoles responsive)

#### 6. Jour 11-12 : Tests Intégration
- ✅ **Tests parcours utilisateur complet** (essai gratuit → email → réutilisation = erreur)
- ✅ **Tests cas enfants** (inscription enfant avec adhésion enfant)

#### 7. Jour 13-15 : Finalisation
- ✅ **Créer seeds data initiations** (52 séances pour saison courante)
- ✅ **Tester migration production** (replay sur staging)
- ✅ **Documenter rollback strategy** (procédure complète)

### 🔴 Risques Identifiés et Protections

| Jour | Risque | Protection |
|------|--------|-----------|
| Jour 1 | Conflit migration events existante | Vérifier `schema.rb` avant migration, tester rollback |
| Jour 2-3 | Tests passent mais logique buggée | Tests parcours utilisateur complet |
| Jour 4 | Oublier validation adhésion enfant | Checklist enfant (voir Jour 4) |
| Jour 8-9 | Interface non-responsive mobile | Tester sur mobile avant Jour 9 |
| Jour 11-12 | Migration échoue → rollback complexe | Tester rollback Jour 12, documenter procédure |

### 📊 Résumé Final

| Aspect | Statut | Commentaire |
|--------|--------|-------------|
| Architecture | ✅ Validée | STI + Extension = optimal |
| Séquence | ✅ Validée | Ordre Rails 8 correct |
| Tests | ⚠️ À renforcer | Ajouter parcours utilisateur |
| Enfants | ⚠️ À implémenter | Cas présent mais incomplet |
| Timeline | ✅ Réaliste | 3 semaines faisable |
| Risques | ⚠️ Identifiés | Migrations + rollback |

### 🚀 Décision : LANCÉ

**Verdict** : ✅ **APPROUVÉ**

Ce plan est solide, détaillé et réaliste. Les ajustements proposés sont mineurs (enfants, export matériel, tests parcours).

**Points forts** :
- ✅ Ordre correct (migrations → tests → contrôleurs → admin)
- ✅ TDD dès le début (>70% coverage obligatoire)
- ✅ Respect Shape Up (3 semaines, scope flexible)
- ✅ Réutilise code existant (80% code réutilisé = rapide)
- ✅ Sécurité/permissions dès Jour 7

**Avant de démarrer** :
- [ ] Appliquer les 7 recommandations critiques ci-dessus
- [ ] Créer branche `feature/initiations-mvp`
- [ ] Briefing équipe sur Shape Up (discipline scope)
- [ ] Confirmer dates (Jour 1 = quand ?)

**Document PRÊT POUR DÉVELOPPEMENT** 🚀

---

---

## 📊 SUIVI D'AVANCEMENT

### ✅ Jour 1 : Migrations + Modèles STI (2025-12-03)

**Statut** : ✅ **TERMINÉ**

#### Réalisations

**Migrations créées** :
- ✅ `20251203172509_add_initiation_fields_to_events.rb`
  - Colonne `type` avec safety check
  - Champs récurrence : `is_recurring`, `recurring_day`, `recurring_time`, `season`, `recurring_start_date`, `recurring_end_date`
  - Index `[:type, :season]`
  - Mise à jour événements existants avec `type = 'Event::Rando'`
- ✅ `20251203172510_add_initiation_fields_to_attendances.rb`
  - `free_trial_used` (boolean, default: false)
  - `is_volunteer` (boolean, default: false)
  - `equipment_note` (text)
  - Index `[:event_id, :is_volunteer]` et `[:user_id, :free_trial_used]`

**Modèles créés/adaptés** :
- ✅ `app/models/event/initiation.rb` créé
  - STI héritant de `Event`
  - Validations : samedi, 10h15, Gymnase Ampère
  - Méthodes métier : `full?`, `available_places`, `participants_count`, `volunteers_count`
- ✅ `app/models/attendance.rb` adapté
  - Validations essai gratuit et adhésion
  - Scopes `volunteers` et `participants`
  - Gestion bénévoles (ne comptent pas dans limite)

**Fichiers modifiés** :
- `db/migrate/20251203172509_add_initiation_fields_to_events.rb` (nouveau)
- `db/migrate/20251203172510_add_initiation_fields_to_attendances.rb` (nouveau)
- `app/models/event/initiation.rb` (nouveau)
- `app/models/attendance.rb` (modifié)

**Migrations appliquées** :
- ✅ Migrations exécutées avec succès
- ✅ Données existantes corrigées (type = 'Event' pour événements existants)
- ✅ Application fonctionne (200 OK sur pages/index)
- ✅ 7 événements existants avec type = 'Event'
- ✅ 0 initiations pour l'instant (normal, pas encore créées)

**Prochaine étape** : Passer au Jour 2-3 (Tests unitaires)

---

**Document de référence pour le développement du module Initiations**
