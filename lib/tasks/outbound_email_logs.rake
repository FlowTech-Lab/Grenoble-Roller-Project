# frozen_string_literal: true

namespace :outbound_email_logs do
  desc "Backfill outbound email logs from remaining Solid Queue mail jobs"
  task backfill: :environment do
    scope = SolidQueue::Job.where(class_name: "ActionMailer::MailDeliveryJob").order(:created_at)
    total = scope.count
    imported = 0

    scope.find_each do |job|
      OutboundEmailLog.backfill_from_solid_queue_job!(job)
      imported += 1
    rescue StandardError => e
      warn "Skip job #{job.id}: #{e.message}"
    end

    puts "Backfill complete: #{imported}/#{total} Solid Queue mail jobs processed."
  end
end
