# frozen_string_literal: true

module AdminPanel
  class NotificationChannelsController < BaseController
    before_action :ensure_superadmin
    before_action :set_notification_channel, only: %i[edit update destroy test sample_event sample_all_events]
    before_action :authorize_notification_channel, only: %i[edit update destroy test sample_event sample_all_events]

    def index
      authorize [ :admin_panel, NotificationChannel ]
      @notification_channels = NotificationChannel.includes(:notification_subscriptions).order(created_at: :desc)
    end

    def show
      @notification_channel = NotificationChannel.find(params[:id])
      authorize [ :admin_panel, @notification_channel ]
      redirect_to edit_admin_panel_notification_channel_path(@notification_channel)
    end

    def new
      @notification_channel = NotificationChannel.new(enabled: true)
      authorize [ :admin_panel, @notification_channel ]
      @grouped_events = NotificationEventRegistry.grouped
      @selected_event_keys = NotificationEventRegistry.default_on_keys
    end

    def create
      @notification_channel = NotificationChannel.new(channel_params)
      authorize [ :admin_panel, @notification_channel ]

      saved = false
      ActiveRecord::Base.transaction do
        saved = @notification_channel.save
        raise ActiveRecord::Rollback unless saved

        event_keys = params[:event_keys].presence || NotificationEventRegistry.default_on_keys
        @notification_channel.sync_subscriptions!(event_keys)
      end

      if saved
        flash[:notice] = "Webhook Discord créé avec succès"
        redirect_to edit_admin_panel_notification_channel_path(@notification_channel)
      else
        @grouped_events = NotificationEventRegistry.grouped
        @selected_event_keys = Array(params[:event_keys])
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @grouped_events = NotificationEventRegistry.grouped
      @selected_event_keys = @notification_channel.subscribed_event_keys
    end

    def update
      attributes = channel_params
      attributes.delete(:webhook_url) if attributes[:webhook_url].blank?

      updated = false
      ActiveRecord::Base.transaction do
        updated = @notification_channel.update(attributes)
        raise ActiveRecord::Rollback unless updated

        @notification_channel.sync_subscriptions!(params[:event_keys])
      end

      if updated
        flash[:notice] = "Webhook Discord mis à jour avec succès"
        redirect_to edit_admin_panel_notification_channel_path(@notification_channel)
      else
        @grouped_events = NotificationEventRegistry.grouped
        @selected_event_keys = Array(params[:event_keys])
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      name = @notification_channel.name
      if @notification_channel.destroy
        flash[:notice] = "Le webhook « #{name} » a été supprimé."
        redirect_to admin_panel_notification_channels_path
      else
        flash[:alert] = "Impossible de supprimer le webhook : #{@notification_channel.errors.full_messages.join(', ')}"
        redirect_to edit_admin_panel_notification_channel_path(@notification_channel)
      end
    end

    def test
      authorize [ :admin_panel, @notification_channel ], :test?

      payload = NotificationEventRegistry.build_payload("test.ping", source: @notification_channel)
      DiscordWebhookClient.post!(@notification_channel.webhook_url, payload)

      @notification_channel.update!(
        last_tested_at: Time.current,
        last_test_status: "success"
      )

      flash[:notice] = "Notification de test envoyée avec succès"
      redirect_to edit_admin_panel_notification_channel_path(@notification_channel)
    rescue DiscordWebhookClient::DeliveryError => e
      @notification_channel.update!(
        last_tested_at: Time.current,
        last_test_status: "error"
      )

      detail = e.response_body.presence || e.message
      flash[:alert] = "Échec de l'envoi du test#{e.http_code ? " (HTTP #{e.http_code})" : ""} : #{detail}"
      redirect_to edit_admin_panel_notification_channel_path(@notification_channel)
    end

    def sample_event
      authorize [ :admin_panel, @notification_channel ], :sample_event?

      event_key = params[:event_key].to_s
      definition = NotificationEventRegistry.find(event_key)

      unless definition
        flash[:alert] = "Événement inconnu."
        return redirect_to edit_admin_panel_notification_channel_path(@notification_channel)
      end

      NotificationChannelSampleService.new(channel: @notification_channel, actor: current_user).send_event!(event_key)

      flash[:notice] = "Échantillon « #{definition.label} » envoyé sur Discord."
      redirect_to edit_admin_panel_notification_channel_path(@notification_channel)
    rescue DiscordWebhookClient::DeliveryError => e
      detail = e.response_body.presence || e.message
      flash[:alert] = "Échec Discord (HTTP #{e.http_code}) : #{detail}"
      redirect_to edit_admin_panel_notification_channel_path(@notification_channel)
    rescue NotificationSampleSourceService::MissingSampleDataError, StandardError => e
      flash[:alert] = "Impossible d'envoyer l'échantillon : #{e.message}"
      redirect_to edit_admin_panel_notification_channel_path(@notification_channel)
    end

    def sample_all_events
      authorize [ :admin_panel, @notification_channel ], :sample_all_events?

      unless @notification_channel.webhook_configured?
        flash[:alert] = "Configurez d'abord l'URL du webhook."
        return redirect_to edit_admin_panel_notification_channel_path(@notification_channel)
      end

      NotificationChannelSampleAllJob.perform_later(@notification_channel.id, current_user.id)

      count = NotificationEventRegistry.all.count { |e| e.key != "test.ping" }
      flash[:notice] = "Envoi de #{count} échantillons en cours (~#{((count * NotificationChannelSampleService::DEFAULT_DELAY_SECONDS) / 60.0).ceil} min). Surveillez Discord."
      redirect_to edit_admin_panel_notification_channel_path(@notification_channel)
    end

    private

    def ensure_superadmin
      return if current_user&.role&.level.to_i >= 70

      redirect_to admin_panel_initiations_path, alert: "Accès réservé aux super-administrateurs"
    end

    def set_notification_channel
      @notification_channel = NotificationChannel.find(params[:id])
    end

    def authorize_notification_channel
      authorize [ :admin_panel, @notification_channel ]
    end

    def channel_params
      params.require(:notification_channel).permit(:name, :webhook_url, :enabled)
    end
  end
end
