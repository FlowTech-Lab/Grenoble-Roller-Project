# frozen_string_literal: true

require "rails_helper"

RSpec.describe OutboundEmailLog, type: :model do
  include ActiveJob::TestHelper

  describe ".record_enqueue!" do
    it "creates a queued log for a mail delivery job" do
      user = create(:user)

      expect {
        UserMailer.welcome_email(user).deliver_later
      }.to change(described_class, :count).by(1)

      log = described_class.last
      expect(log.mailer_class).to eq("UserMailer")
      expect(log.mailer_method).to eq("welcome_email")
      expect(log.status).to eq("queued")
    end

    it "marks the log as sent after the job runs" do
      user = create(:user)
      UserMailer.welcome_email(user).deliver_later

      perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob)

      expect(described_class.last.status).to eq("sent")
    end
  end

  describe ".backfill_from_solid_queue_job!" do
    it "imports an existing Solid Queue mail job" do
      job = SolidQueue::Job.create!(
        class_name: "ActionMailer::MailDeliveryJob",
        queue_name: "default",
        arguments: {
          "job_id" => "abc-123",
          "arguments" => [ "UserMailer", "welcome_email", "deliver_now" ]
        },
        created_at: Time.current,
        scheduled_at: Time.current
      )

      log = described_class.backfill_from_solid_queue_job!(job)
      expect(log.mailer_class).to eq("UserMailer")
      expect(log.active_job_id).to eq("abc-123")
    end
  end
end
