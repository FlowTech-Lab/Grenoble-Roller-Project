# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Attendances', type: :request do
  include RequestAuthenticationHelper

  let(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let(:user) { create(:user, role: role) }
  let(:event) { create(:event, :published, :upcoming) }
  let(:initiation) { create(:event_initiation, :published, :upcoming) }

  describe 'PATCH /events/:event_id/attendances/toggle_reminder' do
    let(:attendance) { create(:attendance, user: user, event: event, wants_reminder: false) }

    it 'requires authentication' do
      patch toggle_reminder_event_attendances_path(event)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'toggles reminder preference for authenticated user' do
      login_user(user)

      expect {
        patch toggle_reminder_event_attendances_path(event)
      }.to change { attendance.reload.wants_reminder }.from(false).to(true)

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
    end

    it 'toggles reminder from true to false' do
      attendance.update!(wants_reminder: true)
      login_user(user)

      expect {
        patch toggle_reminder_event_attendances_path(event)
      }.to change { attendance.reload.wants_reminder }.from(true).to(false)

      expect(response).to redirect_to(event_path(event))
    end
  end

  describe 'PATCH /initiations/:initiation_id/attendances/toggle_reminder' do
    let(:attendance) { create(:attendance, user: user, event: initiation, wants_reminder: false) }

    it 'requires authentication' do
      patch toggle_reminder_initiation_attendances_path(initiation)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'toggles reminder preference for authenticated user' do
      login_user(user)

      expect {
        patch toggle_reminder_initiation_attendances_path(initiation)
      }.to change { attendance.reload.wants_reminder }.from(false).to(true)

      expect(response).to redirect_to(initiation_path(initiation))
      expect(flash[:notice]).to be_present
    end
  end
end
