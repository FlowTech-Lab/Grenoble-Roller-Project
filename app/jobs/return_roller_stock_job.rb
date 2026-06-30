# Job to close equipment loans after an initiation ends.
# Runs daily for finished initiations not yet marked as returned.
class ReturnRollerStockJob < ApplicationJob
  queue_as :default

  # Closes reservations for all finished initiations with stock_returned_at nil.
  def perform
    now = Time.current

    # All finished initiations (end_at <= now) not yet closed.
    finished_initiations = Event::Initiation
      .published
      .where("start_at + INTERVAL '1 minute' * duration_min <= ?", now)
      .where(stock_returned_at: nil)
      .includes(:attendances)

    count_processed = 0
    total_rollers_returned = 0

    finished_initiations.find_each do |initiation|
      # Vérifier qu'il y a des attendances avec matériel prêté
      has_equipment_loaned = initiation.attendances
        .where(needs_equipment: true)
        .where.not(roller_size: nil)
        .where.not(status: "canceled")
        .exists?

      next unless has_equipment_loaned

      # Close equipment reservations for this initiation
      rollers_returned = initiation.return_roller_stock
      rollers_returned = 0 if rollers_returned.nil?
      if rollers_returned > 0
        count_processed += 1
        total_rollers_returned += rollers_returned
        Rails.logger.info("[ReturnRollerStockJob] Initiation ##{initiation.id}: #{rollers_returned} loan(s) closed")
      end
    end

    Rails.logger.info("[ReturnRollerStockJob] Done: #{count_processed} initiation(s), #{total_rollers_returned} loan(s) closed total")
  end
end
