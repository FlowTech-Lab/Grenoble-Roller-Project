# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Waitlist Entries', type: :request do
  include RequestAuthenticationHelper
  include WaitlistTestHelper

  let(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let(:user) { create(:user, role: role, confirmed_at: Time.current) }
  let(:event) { create(:event, :published, :upcoming, max_participants: 2) }
  let(:initiation) { create(:event_initiation, :published, :upcoming, max_participants: 2) }
  
  # Stubber l'envoi d'emails pour éviter les erreurs SMTP
  before do
    allow_any_instance_of(User).to receive(:send_confirmation_instructions).and_return(true)
    allow_any_instance_of(User).to receive(:send_welcome_email_and_confirmation).and_return(true)
  end

  describe 'POST /events/:event_id/waitlist_entries' do
    context 'when event is full' do
      before do
        # Remplir l'événement avec des attendances registered (bypass validations)
        2.times do
          attendance = build(:attendance, event: event, status: 'registered', is_volunteer: false)
          attendance.save(validate: false)
        end
        event.attendances.reload  # ← Critique!
        event.reload  # Recharger l'événement pour mettre à jour le counter_cache
      end

      it 'requires authentication' do
        post event_waitlist_entries_path(event)
        
        # Extraire l'exception du body
        if response.body.include?('Exception')
          # Chercher le message d'erreur dans le HTML
          match = response.body.match(/<h1[^>]*>([^<]+)<\/h1>/)
          puts "\n🔴 Exception: #{match[1]}" if match
          
          # Chercher la trace
          match2 = response.body.match(/<pre[^>]*>(.*?)<\/pre>/m)
          puts "Trace: #{match2[1][0..500]}" if match2
        end
        
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'creates a waitlist entry' do
        login_user(user)

        expect {
          post event_waitlist_entries_path(event), params: { waitlist_entry: { wants_reminder: false } }
        }.to change { WaitlistEntry.count }.by(1)

        expect(response).to redirect_to(event_path(event))
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe 'DELETE /waitlist_entries/:id' do
    # Créer dans before block pour éviter le cache d'association RSpec
    before do
      # Remplir l'événement d'abord (requis pour créer une waitlist_entry)
      2.times do
        attendance = build(:attendance, event: event, status: 'registered', is_volunteer: false)
        attendance.save(validate: false)
      end
      event.attendances.reload  # ← Critique!
      event.reload  # Recharger l'événement pour mettre à jour le counter_cache
      @waitlist_entry = build(:waitlist_entry, user: user, event: event)
      @waitlist_entry.save(validate: false)
      event.waitlist_entries.reload  # ← Critique pour les politiques Pundit!
    end

    it 'requires authentication' do
      delete waitlist_entry_path(@waitlist_entry)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'cancels the waitlist entry' do
      login_user(user)

      expect {
        delete waitlist_entry_path(@waitlist_entry)
      }.to change { @waitlist_entry.reload.status }.from('pending').to('cancelled')

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
    end
  end

  describe 'POST /waitlist_entries/:id/convert_to_attendance' do
    # Créer dans before block pour éviter le cache d'association RSpec
    before do
      # Remplir l'événement d'abord (requis pour créer une waitlist_entry)
      2.times do
        attendance = build(:attendance, event: event, status: 'registered', is_volunteer: false)
        attendance.save(validate: false)
      end
      event.attendances.reload  # ← Critique!
      event.reload  # Recharger l'événement pour mettre à jour le counter_cache
      
      @waitlist_entry = build(:waitlist_entry, user: user, event: event, status: 'notified')
      @waitlist_entry.save(validate: false)
      # Créer l'attendance pending associée (bypass validations)
      pending_attendance = event.attendances.build(
        user: user,
        child_membership_id: nil,
        status: "pending",
        wants_reminder: false,
        needs_equipment: false,
        roller_size: nil,
        free_trial_used: false
      )
      pending_attendance.save(validate: false)
      event.attendances.reload  # ← Critique!
      event.waitlist_entries.reload  # ← Critique pour les politiques Pundit!
      event.reload  # Recharger l'événement pour mettre à jour le counter_cache
    end

    it 'requires authentication' do
      post convert_to_attendance_waitlist_entry_path(@waitlist_entry)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'converts waitlist entry to attendance' do
      login_user(user)

      expect {
        post convert_to_attendance_waitlist_entry_path(@waitlist_entry)
      }.to change { @waitlist_entry.reload.status }.from('notified').to('converted')

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
    end
  end

  describe 'POST /waitlist_entries/:id/refuse' do
    # Créer dans before block pour éviter le cache d'association RSpec
    before do
      # Remplir l'événement d'abord (requis pour créer une waitlist_entry)
      2.times do
        attendance = build(:attendance, event: event, status: 'registered', is_volunteer: false)
        attendance.save(validate: false)
      end
      event.attendances.reload  # ← Critique!
      event.reload  # Recharger l'événement pour mettre à jour le counter_cache
      
      @waitlist_entry = build(:waitlist_entry, user: user, event: event, status: 'notified')
      @waitlist_entry.save(validate: false)
      # Créer l'attendance pending associée (bypass validations)
      pending_attendance = event.attendances.build(
        user: user,
        child_membership_id: nil,
        status: "pending",
        wants_reminder: false,
        needs_equipment: false,
        roller_size: nil,
        free_trial_used: false
      )
      pending_attendance.save(validate: false)
      event.attendances.reload  # ← Critique!
      event.waitlist_entries.reload  # ← Critique pour les politiques Pundit!
      event.reload  # Recharger l'événement pour mettre à jour le counter_cache
    end

    it 'requires authentication' do
      post refuse_waitlist_entry_path(@waitlist_entry)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'refuses the waitlist entry' do
      login_user(user)

      expect {
        post refuse_waitlist_entry_path(@waitlist_entry)
      }.to change { @waitlist_entry.reload.status }.from('notified').to('pending')

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
    end
  end

  describe 'GET /waitlist_entries/:id/confirm' do
    # Créer dans before block pour éviter le cache d'association RSpec
    before do
      # Remplir l'événement d'abord (requis pour créer une waitlist_entry)
      2.times do
        attendance = build(:attendance, event: event, status: 'registered', is_volunteer: false)
        attendance.save(validate: false)
      end
      event.attendances.reload  # ← Critique!
      event.reload  # Recharger l'événement pour mettre à jour le counter_cache
      
      @pending_attendance, @waitlist_entry = create_notified_waitlist_with_pending_attendance(user, event)
      event.attendances.reload  # ← Critique!
      event.waitlist_entries.reload  # ← Critique pour les politiques Pundit!
      event.reload  # Recharger l'événement pour mettre à jour le counter_cache
    end

    it 'requires authentication' do
      get confirm_waitlist_entry_path(@waitlist_entry)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'confirms waitlist entry via GET (from email link)' do
      login_user(user)

      expect {
        get confirm_waitlist_entry_path(@waitlist_entry)
      }.to change { @waitlist_entry.reload.status }.from('notified').to('converted')
        .and change { @pending_attendance.reload.status }.from('pending').to('registered')

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
      expect(flash[:notice]).to include('Inscription confirmée')
    end
  end

  describe 'GET /waitlist_entries/:id/decline' do
    # Créer dans before block pour éviter le cache d'association RSpec
    before do
      # Remplir l'événement d'abord (requis pour créer une waitlist_entry)
      2.times do
        attendance = build(:attendance, event: event, status: 'registered', is_volunteer: false)
        attendance.save(validate: false)
      end
      event.attendances.reload  # ← Critique!
      event.reload  # Recharger l'événement pour mettre à jour le counter_cache
      
      @pending_attendance, @waitlist_entry = create_notified_waitlist_with_pending_attendance(user, event)
      event.attendances.reload  # ← Critique!
      event.waitlist_entries.reload  # ← Critique pour les politiques Pundit!
      event.reload  # Recharger l'événement pour mettre à jour le counter_cache
    end

    it 'requires authentication' do
      get decline_waitlist_entry_path(@waitlist_entry)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'declines waitlist entry via GET (from email link)' do
      initial_count = event.attendances.where(user: user, status: 'pending').count
      
      login_user(user)

      expect {
        get decline_waitlist_entry_path(@waitlist_entry)
      }.to change { @waitlist_entry.reload.status }.from('notified').to('pending')
        .and change { event.attendances.where(user: user, status: 'pending').count }.from(initial_count).to(initial_count - 1)

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
      expect(flash[:notice]).to include('refusé')
    end
  end
end
