# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Events::WaitlistEntries', type: :request do
  include RequestAuthenticationHelper
  include WaitlistTestHelper

  let(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let(:user) { create_user(role: role, confirmed_at: Time.current) }
  let(:event) do
    e = build(:event, :published, :upcoming, max_participants: 1, payment_required: true, price_cents: 500)
    unless e.cover_image.attached?
      test_image_path = Rails.root.join('spec', 'fixtures', 'files', 'test-image.jpg')
      FileUtils.mkdir_p(test_image_path.dirname)
      unless test_image_path.exist?
        jpeg_data = "\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00\xFF\xDB\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t\x08\n\f\x14\r\f\x0B\x0B\f\x19\x12\x13\x0F\x14\x1D\x1A\x1F\x1E\x1D\x1A\x1C\x1C $.' \",#\x1C\x1C(7),01444\x1F'9=82<.342\xFF\xC0\x00\x0B\x08\x00\x01\x00\x01\x01\x01\x11\x00\xFF\xC4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\xFF\xC4\x00\x14\x10\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xDA\x00\x08\x01\x01\x00\x00?\x00\xAA\xFF\xD9"
        File.binwrite(test_image_path, jpeg_data)
      end
      e.cover_image.attach(
        io: File.open(test_image_path),
        filename: 'test-image.jpg',
        content_type: 'image/jpeg'
      )
    end
    e.save!
    e
  end

  before do
    allow_any_instance_of(User).to receive(:send_confirmation_instructions).and_return(true)
    allow_any_instance_of(User).to receive(:send_welcome_email_and_confirmation).and_return(true)
    fill_event_to_capacity(event, 1)
  end

  context 'when event requires online payment' do
    describe 'POST /events/:event_id/waitlist_entries' do
      before { login_user(user) }

      it 'blocks waitlist creation' do
        expect {
          post event_waitlist_entries_path(event)
        }.not_to change(WaitlistEntry, :count)

        expect(response).to redirect_to(event_path(event))
        expect(flash[:alert]).to include('liste d\'attente')
      end
    end
  end
end
