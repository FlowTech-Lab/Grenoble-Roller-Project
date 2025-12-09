# frozen_string_literal: true

# Mailer personnalisé pour Devise avec QR code et améliorations UX
class DeviseMailer < Devise::Mailer
  default from: "Grenoble Roller <no-reply@grenoble-roller.org>"
  layout "mailer"

  def confirmation_instructions(record, token, opts = {})
    @user = record
    @token = token
    @confirmation_url = build_confirmation_url(record, token)

    # Calculer date d'expiration (3 jours par défaut)
    expiry_period = Devise.confirm_within || 3.days
    @expiry_date = expiry_period.from_now.strftime("%d/%m/%Y à %H:%M")
    @hours_left = (expiry_period / 1.hour).round

    # URL pour renvoyer l'email (utiliser _url pour URL complète dans email)
    @resend_url = build_resend_confirmation_url

    # Générer QR code pour mobile (avec gestion d'erreur)
    qr_code_data = generate_qr_code_png(@confirmation_url)

    # Définir le Content-ID pour le template (avant l'appel à mail())
    @qr_code_cid = qr_code_data ? "qr-code-confirmation@grenoble-roller.org" : nil

    # Attacher le QR code comme pièce jointe AVANT le rendu du template
    if qr_code_data
      attachments["qr-code-confirmation.png"] = {
        mime_type: "image/png",
        content: qr_code_data,
        content_id: "<#{@qr_code_cid}>"
      }
    end

    # Logging (sans token)
    Rails.logger.info(
      "Sending confirmation email to #{@user.email} " \
      "(expires: #{@expiry_date})"
    )

    mail(
      to: record.email,
      subject: "Confirmez votre adresse email - Grenoble Roller",
      template_path: "devise/mailer",
      template_name: "confirmation_instructions"
    )
  rescue => e
    Rails.logger.error("Failed to render confirmation email: #{e.message}")
    raise
  end

  private

  def build_confirmation_url(user, token)
    # Utiliser les helpers URL de Rails avec les routes Devise
    url_helpers = Rails.application.routes.url_helpers

    # Déterminer le host selon l'environnement
    host = if Rails.env.development?
      ENV.fetch("MAILER_HOST", "dev-grenoble-roller.flowtech-lab.org")
    elsif staging_environment?
      ENV.fetch("MAILER_HOST", "grenoble-roller.flowtech-lab.org")
    elsif Rails.env.production?
      ENV.fetch("MAILER_HOST", "grenoble-roller.org")
    else
      ActionMailer::Base.default_url_options[:host] ||
      Rails.application.config.action_mailer.default_url_options[:host] ||
      "localhost:3000"
    end

    protocol = ActionMailer::Base.default_url_options[:protocol] ||
               Rails.application.config.action_mailer.default_url_options[:protocol] ||
               (Rails.env.development? ? "https" : "https")

    url_helpers.user_confirmation_url(
      confirmation_token: token,
      host: host,
      protocol: protocol
    )
  end

  def staging_environment?
    # Détecter staging via variable d'environnement ou host
    ENV["APP_ENV"] == "staging" ||
    ENV["DEPLOY_ENV"] == "staging" ||
    (Rails.env.production? &&
     (ActionMailer::Base.default_url_options[:host]&.include?("flowtech-lab.org") ||
      Rails.application.config.action_mailer.default_url_options[:host]&.include?("flowtech-lab.org")))
  end

  def build_resend_confirmation_url
    # Construire l'URL pour renvoyer l'email de confirmation
    url_helpers = Rails.application.routes.url_helpers

    # Déterminer le host selon l'environnement
    host = if Rails.env.development?
      ENV.fetch("MAILER_HOST", "dev-grenoble-roller.flowtech-lab.org")
    elsif staging_environment?
      ENV.fetch("MAILER_HOST", "grenoble-roller.flowtech-lab.org")
    elsif Rails.env.production?
      ENV.fetch("MAILER_HOST", "grenoble-roller.org")
    else
      ActionMailer::Base.default_url_options[:host] ||
      Rails.application.config.action_mailer.default_url_options[:host] ||
      "localhost:3000"
    end

    protocol = ActionMailer::Base.default_url_options[:protocol] ||
               Rails.application.config.action_mailer.default_url_options[:protocol] ||
               (Rails.env.development? ? "https" : "https")

    url_helpers.new_user_confirmation_url(
      host: host,
      protocol: protocol
    )
  end

  # Générer QR code en PNG pour meilleure compatibilité avec les clients email
  def generate_qr_code_png(url)
    require "rqrcode"

    qr = RQRCode::QRCode.new(url)

    # Générer le QR code en PNG (méthode simple)
    # Utiliser les options par défaut qui fonctionnent bien
    png = qr.as_png(
      size: 240,
      border_modules: 4,
      module_px_size: 6,
      fill: "white",
      color: "black"
    )

    # Retourner les données PNG brutes (StringIO ou String)
    png.respond_to?(:to_s) ? png.to_s : png.string
  rescue => e
    # Si génération QR échoue, ignorer gracieusement
    Rails.logger.debug("QR code PNG generation failed: #{e.message}")
    Rails.logger.debug(e.backtrace.first(3).join("\n")) if Rails.env.development?
    nil
  end
end
