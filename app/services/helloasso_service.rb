
class HelloassoService
  require "net/http"
  require "uri"
  require "json"

  # OAuth2 token endpoint (client_credentials)
  # Note: la doc HelloAsso utilise généralement /oauth2/token pour obtenir le jeton
  HELLOASSO_SANDBOX_OAUTH_URL = "https://api.helloasso-sandbox.com/oauth2/token"
  HELLOASSO_PRODUCTION_OAUTH_URL = "https://api.helloasso.com/oauth2/token"

  HELLOASSO_SANDBOX_API_BASE_URL = "https://api.helloasso-sandbox.com/v5"
  HELLOASSO_PRODUCTION_API_BASE_URL = "https://api.helloasso.com/v5"

  class << self
    # Renvoie la configuration brute depuis les credentials
    def config
      Rails.application.credentials.helloasso || {}
    end

    # Détermine l'environnement HelloAsso réellement utilisé
    # - En production Rails → on force l'usage des credentials de production
    # - En dehors de la production → sandbox par défaut
    def environment
      return "production" if Rails.env.production?

      config[:environment].presence || "sandbox"
    end

    def sandbox?
      environment == "sandbox"
    end

    def production?
      environment == "production"
    end

    # Sélectionne le bon client_id selon l'environnement
    def client_id
      if production?
        config[:client_id_production] || config[:client_id]
      else
        config[:client_id]
      end
    end

    # Sélectionne le bon client_secret selon l'environnement
    def client_secret
      if production?
        config[:client_secret_production] || config[:client_secret]
      else
        config[:client_secret]
      end
    end

    def organization_slug
      config[:organization_slug]
    end

    def oauth_token_url
      production? ? HELLOASSO_PRODUCTION_OAUTH_URL : HELLOASSO_SANDBOX_OAUTH_URL
    end

    def api_base_url
      production? ? HELLOASSO_PRODUCTION_API_BASE_URL : HELLOASSO_SANDBOX_API_BASE_URL
    end

    # ---- Payload helpers (no network) -------------------------------------------

    # Construit le payload JSON (Hash Ruby) pour initialiser un checkout HelloAsso.
    #
    # - order: objet ressemblant à une Order locale (id, total_cents, currency)
    # - donation_cents: montant du don additionnel en centimes (Integer)
    # - back_url: URL suivie par le contributeur s'il veut revenir en arrière
    # - error_url: URL appelée en cas d'erreur pendant le checkout
    # - return_url: URL appelée après le paiement (succès / échec)
    #
    # NOTE: on ne fait AUCUN appel réseau ici, juste un Hash Ruby.
    def build_checkout_intent_payload(order, donation_cents:, back_url:, error_url:, return_url:)
      raise ArgumentError, "order is required" unless order
      raise "HelloAsso organization_slug manquant" if organization_slug.to_s.strip.empty?

      total_cents = order.total_cents.to_i + donation_cents.to_i

      {
        totalAmount: total_cents,
        initialAmount: total_cents, # un seul paiement pour l'instant
        itemName: "Commande ##{order.id} - Boutique Grenoble Roller",
        backUrl: back_url,
        errorUrl: error_url,
        returnUrl: return_url,
        containsDonation: donation_cents.to_i.positive?,
        terms: nil,
        payer: nil,
        # La doc indique que metadata est un JSON object, pas une string.
        metadata: {
          localOrderId: order.id,
          environment: environment
        }
      }
    end

    # ---- OAuth2 / Token management -------------------------------------------------

    # Appelle l'API HelloAsso pour obtenir un access_token OAuth2
    # Utilise le flux client_credentials (pas d'utilisateur final impliqué)
    #
    # Retourne une Hash Ruby avec au minimum :
    #   {
    #     access_token: "xxx",
    #     token_type:   "Bearer",
    #     expires_in:   3600,
    #     raw:          <réponse JSON complète>
    #   }
    #
    # Lève une RuntimeError en cas d'erreur réseau ou HTTP != 200.
    def fetch_access_token!
      raise "HelloAsso client_id manquant dans les credentials" if client_id.to_s.strip.empty?
      raise "HelloAsso client_secret manquant dans les credentials" if client_secret.to_s.strip.empty?

      uri = URI.parse(oauth_token_url)

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/x-www-form-urlencoded"
      request.set_form_data(
        "grant_type" => "client_credentials",
        "client_id" => client_id,
        "client_secret" => client_secret
      )

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise "HelloAsso OAuth error (#{response.code}): #{response.body}"
      end

      body = JSON.parse(response.body)

      {
        access_token: body["access_token"],
        token_type: body["token_type"],
        expires_in: body["expires_in"],
        raw: body
      }
    rescue JSON::ParserError => e
      raise "HelloAsso OAuth JSON parse error: #{e.message}"
    end

    # Helper pratique pour juste récupérer le token (ou nil en cas d'erreur)
    def access_token
      fetch_access_token![:access_token]
    rescue => e
      Rails.logger.error("[HelloassoService] Impossible de récupérer l'access_token : #{e.class} - #{e.message}")
      nil
    end

    # ---- Checkout intents (REST) -----------------------------------------------

    # Initialise un checkout HelloAsso via l'endpoint officiel :
    # POST /v5/organizations/{organizationSlug}/checkout-intents
    #
    # - order: objet ressemblant à une Order locale (id, total_cents, currency)
    # - donation_cents: montant du don additionnel en centimes (Integer)
    # - back_url, error_url, return_url: URLs de redirection (voir doc HelloAsso)
    #
    # Retourne un Hash :
    #   {
    #     status: 200,
    #     success: true/false,
    #     body: { "id" => ..., "redirectUrl" => "..." }
    #   }
    def create_checkout_intent(order, donation_cents:, back_url:, error_url:, return_url:)
      token = access_token
      raise "HelloAsso access_token introuvable" if token.to_s.strip.empty?
      raise "HelloAsso organization_slug manquant" if organization_slug.to_s.strip.empty?

      payload = build_checkout_intent_payload(
        order,
        donation_cents: donation_cents,
        back_url: back_url,
        error_url: error_url,
        return_url: return_url
      )

      uri = URI.parse("#{api_base_url}/organizations/#{organization_slug}/checkout-intents")

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["accept"] = "application/json"
      request["content-type"] = "application/*+json"
      request.body = payload.to_json

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      response = http.request(request)

      body =
        begin
          JSON.parse(response.body)
        rescue JSON::ParserError
          { "raw_body" => response.body }
        end

      result = {
        status: response.code.to_i,
        success: response.is_a?(Net::HTTPSuccess),
        body: body
      }

      Rails.logger.info("[HelloassoService] create_checkout_intent response: #{result.inspect}")
      result
    end

    # Helper pour récupérer directement l'URL de redirection si tout s'est bien passé.
    def checkout_redirect_url(order, donation_cents:, back_url:, error_url:, return_url:)
      result = create_checkout_intent(
        order,
        donation_cents: donation_cents,
        back_url: back_url,
        error_url: error_url,
        return_url: return_url
      )

      return nil unless result[:success]

      result.dig(:body, "redirectUrl")
    end

    # Récupère l'URL de redirection pour un checkout-intent existant.
    # Utile pour permettre à un utilisateur de reprendre un paiement interrompu.
    def checkout_redirect_url_for_intent(checkout_intent_id)
      intent = fetch_checkout_intent(checkout_intent_id)
      intent["redirectUrl"]
    end

    # ---- Lecture / mise à jour des paiements (polling Phase 2) -----------------

    # Récupère les informations d'un checkout-intent HelloAsso et met à jour
    # le Payment et l'Order associés.
    #
    # D'après la doc HelloAsso, l'endpoint
    #   GET /v5/organizations/{slug}/checkout-intents/{checkoutIntentId}
    # renvoie un champ `order` uniquement si le paiement a bien abouti.
    #
    # Pour l'instant on part sur une logique simple :
    # - order présent  → paiement OK → Payment.succeeded + Order.paid
    # - order absent   → on considère que c'est encore en attente
    #
    # (Les cas de refus / abandon seront raffinés plus tard si la doc expose
    #  un état plus précis côté checkout-intent.)
    def fetch_and_update_payment(payment)
      intent = fetch_checkout_intent(payment.provider_payment_id)

      has_order = intent.key?("order") && intent["order"].present?
      Rails.logger.info(
        "[HelloassoService] fetch_and_update_payment ##{payment.id} " \
        "checkoutIntentId=#{payment.provider_payment_id} has_order=#{has_order}"
      )

      order = payment.orders.first

      if has_order
        # Paiement confirmé
        payment.update!(status: "succeeded")
        order&.update!(status: "paid")
      else
        # Si aucun order associé après le délai HelloAsso (~45 minutes),
        # on considère le paiement comme abandonné / non finalisé.
        if payment.created_at < 45.minutes.ago
          payment.update!(status: "abandoned")
          order&.update!(status: "failed")
          Rails.logger.info(
            "[HelloassoService] CheckoutIntent ##{payment.provider_payment_id} " \
            "considéré comme abandonné (aucune commande créée après 45 minutes)."
          )
        else
          Rails.logger.warn(
            "[HelloassoService] CheckoutIntent ##{payment.provider_payment_id} " \
            "sans commande associée (encore en attente)."
          )
        end
      end

      payment
    end

    private

    # Lecture d'un checkout-intent HelloAsso.
    # Utilise l'endpoint :
    #   GET /v5/organizations/{organizationSlug}/checkout-intents/{checkoutIntentId}
    def fetch_checkout_intent(checkout_intent_id)
      uri = URI.parse(
        "#{api_base_url}/organizations/#{organization_slug}/checkout-intents/#{checkout_intent_id}"
      )

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{access_token}"
      request["accept"] = "application/json"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise "HelloAsso checkout-intent fetch error (#{response.code}): #{response.body}"
      end

      JSON.parse(response.body)
    end
  end
end

