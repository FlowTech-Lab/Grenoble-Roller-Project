# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Waitlist Entries', type: :request do
  include RequestAuthenticationHelper

  let(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let(:user) { create(:user, role: role, confirmed_at: Time.current) }
  let(:event) { create(:event, :published, :upcoming, max_participants: 2) }
  let(:initiation) { create(:event_initiation, :published, :upcoming, max_participants: 2) }

  describe 'POST /events/:event_id/waitlist_entries' do
    context 'when event is full' do
      before do
        # Remplir l'événement
        2.times { create(:attendance, event: event, status: 'confirmed') }
      end

      it 'requires authentication' do
        post event_waitlist_entries_path(event)

        expect(response).to redirect_to(new_user_session_path)
      end

      it 'creates a waitlist entry for authenticated user' do
        login_user(user)

        expect {
          post event_waitlist_entries_path(event), params: { wants_reminder: '1' }
        }.to change(WaitlistEntry, :count).by(1)

        expect(response).to redirect_to(event_path(event))
        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to include('liste d\'attente')
      end

      it 'creates a waitlist entry with reminder preference' do
        login_user(user)

        post event_waitlist_entries_path(event), params: { wants_reminder: '1' }

        waitlist_entry = WaitlistEntry.last
        expect(waitlist_entry.wants_reminder).to be true
      end

      it 'does not create duplicate waitlist entry' do
        login_user(user)
        create(:waitlist_entry, user: user, event: event, status: 'pending')

        expect {
          post event_waitlist_entries_path(event)
        }.not_to change(WaitlistEntry, :count)

        expect(response).to redirect_to(event_path(event))
        expect(flash[:alert]).to be_present
      end
    end

    context 'when event is not full' do
      it 'does not create waitlist entry' do
        login_user(user)

        expect {
          post event_waitlist_entries_path(event)
        }.not_to change(WaitlistEntry, :count)

        expect(response).to redirect_to(event_path(event))
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'POST /initiations/:initiation_id/waitlist_entries' do
    context 'when initiation is full' do
      before do
        # Remplir l'initiation
        2.times { create(:attendance, event: initiation, status: 'confirmed') }
      end

      it 'requires authentication' do
        post initiation_waitlist_entries_path(initiation)

        expect(response).to redirect_to(new_user_session_path)
      end

      it 'creates a waitlist entry for authenticated user' do
        login_user(user)

        expect {
          post initiation_waitlist_entries_path(initiation), params: {
            needs_equipment: '0',
            wants_reminder: '1'
          }
        }.to change(WaitlistEntry, :count).by(1)

        expect(response).to redirect_to(initiation_path(initiation))
        expect(flash[:notice]).to be_present
        expect(flash[:notice]).to include('liste d\'attente')
      end

      it 'creates a waitlist entry with equipment request' do
        login_user(user)

        post initiation_waitlist_entries_path(initiation), params: {
          needs_equipment: '1',
          roller_size: '38',
          wants_reminder: '0'
        }

        waitlist_entry = WaitlistEntry.last
        expect(waitlist_entry.needs_equipment).to be true
        expect(waitlist_entry.roller_size).to eq('38')
      end

      it 'validates roller size when equipment is needed' do
        login_user(user)

        post initiation_waitlist_entries_path(initiation), params: {
          needs_equipment: '1',
          roller_size: ''
        }

        expect(response).to redirect_to(initiation_path(initiation))
        expect(flash[:alert]).to include('taille de rollers')
      end
    end
  end

  describe 'DELETE /waitlist_entries/:id' do
    let(:waitlist_entry) { create(:waitlist_entry, user: user, event: event, status: 'pending') }

    it 'requires authentication' do
      delete waitlist_entry_path(waitlist_entry)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'cancels waitlist entry for authenticated user' do
      login_user(user)

      expect {
        delete waitlist_entry_path(waitlist_entry)
      }.to change { waitlist_entry.reload.status }.from('pending').to('cancelled')

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
    end

    it 'does not allow canceling other user\'s waitlist entry' do
      other_user = create(:user, role: role)
      other_waitlist_entry = create(:waitlist_entry, user: other_user, event: event)
      login_user(user)

      expect {
        delete waitlist_entry_path(other_waitlist_entry)
      }.not_to change { other_waitlist_entry.reload.status }

      expect(response).to redirect_to(event_path(event))
      expect(flash[:alert]).to be_present
    end
  end

  describe 'POST /waitlist_entries/:id/convert_to_attendance' do
    let(:waitlist_entry) do
      create(:waitlist_entry, user: user, event: event, status: 'notified')
    end
    let(:pending_attendance) do
      create(:attendance, user: user, event: event, status: 'pending')
    end

    before do
      pending_attendance # Créer l'attendance pending
    end

    it 'requires authentication' do
      post convert_to_attendance_waitlist_entry_path(waitlist_entry)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'converts notified waitlist entry to attendance' do
      login_user(user)

      expect {
        post convert_to_attendance_waitlist_entry_path(waitlist_entry)
      }.to change { waitlist_entry.reload.status }.from('notified').to('converted')
        .and change { pending_attendance.reload.status }.from('pending').to('confirmed')

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
      expect(flash[:notice]).to include('Inscription confirmée')
    end

    it 'does not convert if waitlist entry is not notified' do
      waitlist_entry.update!(status: 'pending')
      login_user(user)

      post convert_to_attendance_waitlist_entry_path(waitlist_entry)

      expect(response).to redirect_to(event_path(event))
      expect(flash[:alert]).to be_present
      expect(waitlist_entry.reload.status).to eq('pending')
    end

    it 'does not convert if pending attendance does not exist' do
      pending_attendance.destroy
      login_user(user)

      post convert_to_attendance_waitlist_entry_path(waitlist_entry)

      expect(response).to redirect_to(event_path(event))
      expect(flash[:alert]).to be_present
      expect(flash[:alert]).to include('plus disponible')
    end
  end

  describe 'POST /waitlist_entries/:id/refuse' do
    let(:waitlist_entry) do
      create(:waitlist_entry, user: user, event: event, status: 'notified')
    end

    it 'requires authentication' do
      post refuse_waitlist_entry_path(waitlist_entry)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'refuses notified waitlist entry' do
      login_user(user)

      expect {
        post refuse_waitlist_entry_path(waitlist_entry)
      }.to change { waitlist_entry.reload.status }.from('notified').to('refused')

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
      expect(flash[:notice]).to include('refusé')
    end

    it 'does not refuse if waitlist entry is not notified' do
      waitlist_entry.update!(status: 'pending')
      login_user(user)

      post refuse_waitlist_entry_path(waitlist_entry)

      expect(response).to redirect_to(event_path(event))
      expect(flash[:alert]).to be_present
      expect(waitlist_entry.reload.status).to eq('pending')
    end
  end

  describe 'GET /waitlist_entries/:id/confirm' do
    let(:waitlist_entry) do
      create(:waitlist_entry, user: user, event: event, status: 'notified')
    end
    let(:pending_attendance) do
      create(:attendance, user: user, event: event, status: 'pending')
    end

    before do
      pending_attendance # Créer l'attendance pending
    end

    it 'requires authentication' do
      get confirm_waitlist_entry_path(waitlist_entry)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'confirms waitlist entry via GET (from email link)' do
      login_user(user)

      expect {
        get confirm_waitlist_entry_path(waitlist_entry)
      }.to change { waitlist_entry.reload.status }.from('notified').to('converted')
        .and change { pending_attendance.reload.status }.from('pending').to('confirmed')

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
    end
  end

  describe 'GET /waitlist_entries/:id/decline' do
    let(:waitlist_entry) do
      create(:waitlist_entry, user: user, event: event, status: 'notified')
    end

    it 'requires authentication' do
      get decline_waitlist_entry_path(waitlist_entry)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'declines waitlist entry via GET (from email link)' do
      login_user(user)

      expect {
        get decline_waitlist_entry_path(waitlist_entry)
      }.to change { waitlist_entry.reload.status }.from('notified').to('refused')

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
    end
  end
end

