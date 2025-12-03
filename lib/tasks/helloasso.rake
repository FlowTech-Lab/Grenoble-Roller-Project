namespace :helloasso do
  desc "Sync pending HelloAsso payments"
  task sync_payments: :environment do
    Payment
      .where(provider: "helloasso", status: "pending")
      .where("created_at > ?", 1.day.ago)
      .find_each do |payment|
        begin
          HelloassoService.fetch_and_update_payment(payment)
        rescue StandardError => e
          Rails.logger.error(
            "[Helloasso] Failed to sync payment ##{payment.id}: " \
            "#{e.class} - #{e.message}"
          )
        end
      end
    puts "✅ HelloAsso sync completed."
  end
end
