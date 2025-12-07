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
    
    # URL pour renvoyer l'email
    @resend_url = new_user_confirmation_path
    
    # Générer QR code pour mobile (avec gestion d'erreur)
    @qr_code = generate_qr_code(@confirmation_url)
    
    # Logging (sans token)
    Rails.logger.info(
      "Sending confirmation email to #{@user.email} " \
      "(expires: #{@expiry_date})"
    )
    
    mail(
      to: record.email,
      subject: "Confirmez votre adresse email - Grenoble Roller"
    )
  rescue => e
    Rails.logger.error("Failed to render confirmation email: #{e.message}")
    raise
  end

  private

  def build_confirmation_url(user, token)
    # Utiliser les helpers URL de Rails avec les routes Devise
    # Le helper confirmation_url de Devise utilise automatiquement ActionMailer.default_url_options
    # On utilise directement le helper depuis le contexte du mailer
    url_helpers = Rails.application.routes.url_helpers
    url_helpers.user_confirmation_url(
      confirmation_token: token,
      host: ActionMailer::Base.default_url_options[:host] || 
            Rails.application.config.action_mailer.default_url_options[:host] ||
            (Rails.env.production? ? "grenoble-roller.org" : "localhost:3000")
    )
  end

  # Générer QR code pour l'URL de confirmation
  def generate_qr_code(url)
    require "rqrcode"
    
    qr = RQRCode::QRCode.new(url)
    
    # Convertir en SVG puis en data URI pour l'inliner dans l'email
    svg = qr.as_svg(
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 4,
      standalone: true,
      use_path: true
    )
    
    # Encoder en base64 pour data URI
    base64_svg = Base64.strict_encode64(svg)
    "data:image/svg+xml;base64,#{base64_svg}"
  rescue => e
    # Si génération QR échoue, ignorer gracieusement
    Rails.logger.debug("QR code generation failed: #{e.message}")
    nil
  end
end
