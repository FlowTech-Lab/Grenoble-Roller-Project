# frozen_string_literal: true

module AdminPanel
  class MailLogsController < BaseController
    before_action :ensure_superadmin

    def index
      @logs = OutboundEmailLog.recent_first

      if params[:mailer].present?
        @logs = @logs.where(mailer_class: params[:mailer])
      end

      case params[:status]
      when "pending"
        @logs = @logs.queued
      when "finished"
        @logs = @logs.sent
      when "failed"
        @logs = @logs.failed
      end

      if params[:since].present?
        since_date = Date.parse(params[:since]) rescue nil
        @logs = @logs.where("queued_at >= ?", since_date.beginning_of_day) if since_date
      end

      @pagy, @logs = pagy(@logs, items: 50)

      @stats = {
        total: OutboundEmailLog.count,
        pending: OutboundEmailLog.queued.count,
        finished: OutboundEmailLog.sent.count,
        failed: OutboundEmailLog.failed.count
      }

      @available_mailers = OutboundEmailLog.where.not(mailer_class: [ nil, "" ])
                                         .distinct
                                         .order(:mailer_class)
                                         .pluck(:mailer_class)
    end

    def show
      @log = OutboundEmailLog.find(params[:id])
      @mailer_info = {
        mailer: @log.mailer_class,
        method: @log.mailer_method,
        args: EmailLog::Parser.call(@log.arguments)[:args]
      }
      @solid_queue_job = SolidQueue::Job.find_by(id: @log.solid_queue_job_id) if @log.solid_queue_job_id
      @failed_execution = SolidQueue::FailedExecution.find_by(job_id: @log.solid_queue_job_id) if @log.solid_queue_job_id
    end

    private

    def ensure_superadmin
      unless current_user&.role&.level.to_i >= 70
        redirect_to admin_panel_initiations_path, alert: "Accès réservé aux super-administrateurs"
      end
    end
  end
end
