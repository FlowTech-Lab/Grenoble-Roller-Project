# frozen_string_literal: true

class OutboundEmailLog < ApplicationRecord
  STATUSES = %w[queued sent failed].freeze

  validates :active_job_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :queued_at, presence: true

  scope :recent_first, -> { order(queued_at: :desc) }
  scope :queued, -> { where(status: "queued") }
  scope :sent, -> { where(status: "sent") }
  scope :failed, -> { where(status: "failed") }

  def self.record_enqueue!(job)
    payload = job.serialize
    info = EmailLog::Parser.call(payload)

    record = find_or_initialize_by(active_job_id: job.job_id)
    record.assign_attributes(
      mailer_class: info[:mailer],
      mailer_method: info[:method],
      arguments: payload,
      status: "queued",
      queued_at: Time.current,
      solid_queue_job_id: job.provider_job_id,
      sent_at: nil,
      failed_at: nil,
      error_message: nil
    )
    record.save!
    record
  end

  def self.mark_sent!(active_job_id:, solid_queue_job_id: nil)
    log = find_by(active_job_id: active_job_id)
    return unless log

    log.update!(
      status: "sent",
      sent_at: Time.current,
      solid_queue_job_id: solid_queue_job_id || log.solid_queue_job_id
    )
  end

  def self.mark_failed!(active_job_id:, error_message:, solid_queue_job_id: nil)
    log = find_by(active_job_id: active_job_id)
    return unless log

    log.update!(
      status: "failed",
      failed_at: Time.current,
      error_message: error_message,
      solid_queue_job_id: solid_queue_job_id || log.solid_queue_job_id
    )
  end

  def self.backfill_from_solid_queue_job!(job)
    return unless job.class_name == "ActionMailer::MailDeliveryJob"

    payload = job.arguments
    payload = JSON.parse(payload) if payload.is_a?(String)
    active_job_id = payload.is_a?(Hash) ? payload["job_id"] : nil
    return if active_job_id.blank?

    info = EmailLog::Parser.call(payload)
    failed = SolidQueue::FailedExecution.find_by(job_id: job.id)

    status = if failed
      "failed"
    elsif job.finished_at.present?
      "sent"
    else
      "queued"
    end

    record = find_or_initialize_by(active_job_id: active_job_id)
    record.assign_attributes(
      mailer_class: info[:mailer],
      mailer_method: info[:method],
      arguments: payload,
      status: status,
      queued_at: job.created_at,
      sent_at: status == "sent" ? job.finished_at : nil,
      failed_at: status == "failed" ? (job.finished_at || job.updated_at) : nil,
      error_message: failed&.error,
      solid_queue_job_id: job.id
    )
    record.save!
    record
  end

  def pending?
    status == "queued"
  end

  def finished_at
    sent_at || failed_at
  end
end
