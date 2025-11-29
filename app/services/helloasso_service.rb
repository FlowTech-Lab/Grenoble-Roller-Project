
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
    # - order: objet ressemblant à une Order locale (id, total_cents, currency, order_items)
    # - donation_cents: montant du don additionnel en centimes (Integer)
    # - back_url: URL suivie par le contributeur s'il veut revenir en arrière
    # - error_url: URL appelée en cas d'erreur pendant le checkout
    # - return_url: URL appelée après le paiement (succès / échec)
    #
    # NOTE: on ne fait AUCUN appel réseau ici, juste un Hash Ruby.
    def build_checkout_intent_payload(order, donation_cents:, back_url:, error_url:, return_url:)
      raise ArgumentError, "order is required" unless order
      raise "HelloAsso organization_slug manquant" if organization_slug.to_s.strip.empty?

      # Récupérer le don depuis l'order si disponible, sinon utiliser le paramètre
      donation = order.respond_to?(:donation_cents) ? (order.donation_cents || 0) : donation_cents.to_i
      
      # Construire le tableau items avec les articles de la commande
      items = []
      
      # Ajouter les articles de la commande (si order_items est disponible)
      if order.respond_to?(:order_items) && order.order_items.any?
        order.order_items.each do |order_item|
          product_name = if order_item.respond_to?(:variant) && order_item.variant
                           order_item.variant.product&.name || "Article ##{order_item.variant_id}"
                         elsif order_item.respond_to?(:product)
                           order_item.product&.name || "Article ##{order_item.id}"
                         else
                           "Article ##{order_item.id}"
                         end
          
          items << {
            name: product_name,
            quantity: order_item.quantity.to_i,
            amount: order_item.unit_price_cents.to_i,
            type: "Product"
          }
        end
      else
        # Fallback : si pas d'order_items, créer un item générique avec le total des articles
        articles_cents = order.total_cents.to_i - donation
        if articles_cents > 0
          items << {
            name: "Commande ##{order.id} - Boutique Grenoble Roller",
            quantity: 1,
            amount: articles_cents,
            type: "Product"
          }
        end
      end
      
      # Ajouter le don comme item séparé si > 0 (selon la doc HelloAsso)
      if donation > 0
        items << {
          name: "Contribution à l'association",
          quantity: 1,
          amount: donation,
          type: "Donation"
        }
      end

      # Structure du payload pour checkout-intents
      # NOTE: L'endpoint /checkout-intents peut nécessiter une structure différente de /orders
      # Selon la doc HelloAsso, checkout-intents utilise totalAmount/initialAmount, pas items
      # Mais on peut essayer avec items d'abord, et fallback si erreur 400
      
      total_cents = items.sum { |item| item[:amount] * item[:quantity] }
      
      # Structure pour checkout-intents (selon tests précédents qui fonctionnaient)
      {
        totalAmount: total_cents,
        initialAmount: total_cents,
        itemName: items.any? ? items.map { |i| "#{i[:name]} x#{i[:quantity]}" }.join(", ") : "Commande ##{order.id}",
        backUrl: back_url,
        errorUrl: error_url,
        returnUrl: return_url,
        containsDonation: donation.positive?,
        metadata: {
          localOrderId: order.id,
          environment: environment,
          donationCents: donation,
          items: items # Garder les items dans metadata pour référence
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
        error_msg = if response.code.to_i == 429
                      "HelloAsso OAuth error (429): Rate limit atteint. " \
                      "Les serveurs HelloAsso sont surchargés. Réessayez dans quelques minutes."
                    else
                      "HelloAsso OAuth error (#{response.code}): #{response.body[0..200]}"
                    end
        raise error_msg
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
    # Force un nouveau token à chaque appel (pas de cache) pour éviter les tokens expirés
    def access_token
      result = fetch_access_token!
      token = result[:access_token]
      
      if token.to_s.strip.empty?
        Rails.logger.error("[HelloassoService] access_token vide dans la réponse : #{result.inspect}")
        return nil
      end
      
      token
    rescue => e
      Rails.logger.error("[HelloassoService] Impossible de récupérer l'access_token : #{e.class} - #{e.message}")
      Rails.logger.error("[HelloassoService] Backtrace: #{e.backtrace.first(5).join("\n")}")
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
      # Vérifier les prérequis
      raise "HelloAsso organization_slug manquant" if organization_slug.to_s.strip.empty?
      
      # Obtenir un token (avec retry si nécessaire)
      token = access_token
      if token.to_s.strip.empty?
        Rails.logger.error("[HelloassoService] Tentative de récupération du token échouée")
        # Réessayer une fois
        begin
          token = fetch_access_token![:access_token]
        rescue => e
          Rails.logger.error("[HelloassoService] Échec définitif de récupération du token : #{e.message}")
          raise "HelloAsso access_token introuvable. Vérifiez les credentials (client_id, client_secret) dans Rails credentials."
        end
      end
      
      raise "HelloAsso access_token introuvable après retry" if token.to_s.strip.empty?

      payload = build_checkout_intent_payload(
        order,
        donation_cents: donation_cents,
        back_url: back_url,
        error_url: error_url,
        return_url: return_url
      )

      # Log du payload pour debug
      Rails.logger.info("[HelloassoService] Payload checkout-intent: #{payload.to_json}")

      uri = URI.parse("#{api_base_url}/organizations/#{organization_slug}/checkout-intents")

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["accept"] = "application/json"
      request["content-type"] = "application/json"
      request.body = payload.to_json

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      response = http.request(request)

      # Si 401 (Unauthorized), le token a peut-être expiré, réessayer une fois avec un nouveau token
      if response.code.to_i == 401
        Rails.logger.warn("[HelloassoService] Token expiré (401) lors de create_checkout_intent, réessai avec un nouveau token...")
        token = fetch_access_token![:access_token]
        request["Authorization"] = "Bearer #{token}"
        response = http.request(request)
      end

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

      # Log détaillé pour debug
      if response.code.to_i != 200
        Rails.logger.error("[HelloassoService] create_checkout_intent ERROR (#{response.code}): #{response.body}")
      else
        Rails.logger.info("[HelloassoService] create_checkout_intent SUCCESS: #{result.inspect}")
      end
      
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

    # Récupère l'état d'un paiement HelloAsso et met à jour le Payment et l'Order associés.
    # Utilise l'endpoint GET /v5/organizations/{slug}/checkout-intents/{checkoutIntentId}
    # Si un order est présent dans le checkout-intent, on peut récupérer son état
    def fetch_and_update_payment(payment)
      # provider_payment_id contient l'ID du checkout-intent
      checkout_intent_id = payment.provider_payment_id
      
      # 1. Récupérer le checkout-intent
      intent = fetch_checkout_intent(checkout_intent_id)
      
      # 2. Si un order est présent, récupérer son état via /orders/{orderId}
      state = nil
      if intent.key?("order") && intent["order"].present?
        order_id = intent.dig("order", "id") || intent.dig("order", "orderId")
        
        if order_id
          begin
            order_data = fetch_helloasso_order(order_id)
            state = order_data['state'] if order_data
          rescue StandardError => e
            Rails.logger.warn(
              "[HelloassoService] Failed to fetch order #{order_id}, " \
              "using checkout-intent status: #{e.message}"
            )
          end
        end
      end

      # 3. Déterminer le nouveau statut
      new_status = if state
                     case state
                     when 'Confirmed' then 'succeeded'
                     when 'Refused' then 'failed'
                     when 'Refunded' then 'refunded'
                     else 'pending'
                     end
                   elsif intent.key?("order") && intent["order"].present?
                     # Order présent mais pas de state → considérer comme confirmé
                     'succeeded'
                   else
                     # Pas d'order → encore en attente ou abandonné
                     payment.created_at < 45.minutes.ago ? 'abandoned' : 'pending'
                   end

      return payment if new_status == payment.status

      # 4. Mettre à jour le paiement
      payment.update!(status: new_status)

      # 5. Mettre à jour les commandes associées
      order_status = case new_status
                     when 'succeeded' then 'paid'
                     when 'failed', 'refunded', 'abandoned' then 'failed'
                     else 'pending'
                     end

      payment.orders.each { |order| order.update!(status: order_status) }

      # 6. Mettre à jour les adhésions associées
      if payment.membership
        membership_status = case new_status
                           when 'succeeded' then 'active'
                           when 'failed', 'refunded', 'abandoned' then 'expired'
                           else 'pending'
                           end
        
        old_status = payment.membership.status
        payment.membership.update!(status: membership_status)
        
        # Envoyer email si le paiement a échoué
        if new_status == 'failed' && old_status == 'pending'
          MembershipMailer.payment_failed(payment.membership).deliver_later if defined?(MembershipMailer)
        end
      end

      Rails.logger.info(
        "[HelloassoService] Payment ##{payment.id} updated to #{new_status}. " \
        "Orders: #{payment.orders.pluck(:id).join(', ')}, " \
        "Membership: #{payment.membership&.id}"
      )

      payment
    end

    # Récupère l'état d'une commande HelloAsso via l'endpoint /orders/{orderId}
    def fetch_helloasso_order(order_id)
      uri = URI.parse(
        "#{api_base_url}/organizations/#{organization_slug}/orders/#{order_id}"
      )

      # Obtenir un token frais
      token = access_token
      raise "HelloAsso access_token introuvable" if token.to_s.strip.empty?

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["accept"] = "application/json"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      response = http.request(request)

      # Si 401 (Unauthorized), le token a peut-être expiré, réessayer une fois avec un nouveau token
      if response.code.to_i == 401
        Rails.logger.warn("[HelloassoService] Token expiré (401), réessai avec un nouveau token...")
        token = fetch_access_token![:access_token]
        request["Authorization"] = "Bearer #{token}"
        response = http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise "HelloAsso order fetch error (#{response.code}): #{response.body}"
      end

      JSON.parse(response.body)
    end

    # Extrait le montant du don depuis une réponse HelloAsso (order ou checkout-intent).
    # Cherche un item avec type: "Donation" dans le tableau items.
    #
    # - response_data: Hash Ruby parsé depuis la réponse JSON HelloAsso
    #
    # Retourne le montant en centimes (Integer), ou 0 si aucun don trouvé.
    def extract_donation_from_response(response_data)
      return 0 unless response_data.is_a?(Hash)
      
      items = response_data['items'] || response_data[:items] || []
      return 0 unless items.is_a?(Array)
      
      donation_item = items.find { |item| 
        (item['type'] || item[:type]) == 'Donation' 
      }
      
      return 0 unless donation_item
      
      (donation_item['amount'] || donation_item[:amount] || 0).to_i
    end

    # ---- Adhésions (checkout-intent simplifié) -------------------------------------

    # Crée un checkout-intent HelloAsso pour une adhésion.
    # Utilise un payload simplifié (pas d'items, juste le montant total).
    #
    # - membership: objet Membership
    # - back_url, error_url, return_url: URLs de redirection
    #
    # Retourne un Hash avec status, success, body (id, redirectUrl)
    def create_membership_checkout_intent(membership, back_url:, error_url:, return_url:)
      raise ArgumentError, "membership is required" unless membership
      raise "HelloAsso organization_slug manquant" if organization_slug.to_s.strip.empty?

      token = access_token
      if token.to_s.strip.empty?
        begin
          token = fetch_access_token![:access_token]
        rescue => e
          Rails.logger.error("[HelloassoService] Échec récupération token : #{e.message}")
          raise "HelloAsso access_token introuvable"
        end
      end

      # Construire le payload pour adhésion avec T-shirt optionnel
      category_name = membership.category == 'standard' ? 'Cotisation Adhérent Grenoble Roller' : 
                      membership.category == 'with_ffrs' ? 'Cotisation Adhérent Grenoble Roller + Licence FFRS' : 
                      'Adhésion'
      season_name = membership.season || Membership.current_season_name
      
      # Calculer le montant total (adhésion + T-shirt si présent)
      total_amount = membership.total_amount_cents
      
      # Construire les items
      items = [
        {
          name: "#{category_name} Saison #{season_name}",
          amount: membership.amount_cents,
          type: "Membership"
        }
      ]
      
      # Ajouter le T-shirt si présent
      if membership.tshirt_variant_id.present?
        tshirt_size = membership.tshirt_variant&.option_values&.find { |ov| 
          ov.option_type.name.downcase.include?('taille') || 
          ov.option_type.name.downcase.include?('size') ||
          ov.option_type.name.downcase.include?('dimension')
        }&.value || "Taille standard"
        
        items << {
          name: "T-shirt Grenoble Roller (#{tshirt_size})",
          amount: membership.tshirt_price_cents || 1400,
          type: "Product"
        }
      end

      payload = {
        organizationSlug: organization_slug,
        initialAmount: {
          total: total_amount,
          currency: membership.currency || "EUR"
        },
        totalAmount: {
          total: total_amount,
          currency: membership.currency || "EUR"
        },
        items: items,
        metadata: {
          membership_id: membership.id,
          user_id: membership.user_id,
          category: membership.category,
          season: season_name,
          tshirt_variant_id: membership.tshirt_variant_id,
          environment: environment
        },
        backUrl: back_url,
        errorUrl: error_url,
        returnUrl: return_url
      }

      Rails.logger.info("[HelloassoService] Payload membership checkout-intent: #{payload.to_json}")

      uri = URI.parse("#{api_base_url}/organizations/#{organization_slug}/checkout-intents")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["accept"] = "application/json"
      request["content-type"] = "application/json"
      request.body = payload.to_json

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      response = http.request(request)

      # Retry avec nouveau token si 401
      if response.code.to_i == 401
        Rails.logger.warn("[HelloassoService] Token expiré (401), réessai...")
        token = fetch_access_token![:access_token]
        request["Authorization"] = "Bearer #{token}"
        response = http.request(request)
      end

      body = begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        { "raw_body" => response.body }
      end

      success = response.is_a?(Net::HTTPSuccess)
      
      Rails.logger.info("[HelloassoService] create_membership_checkout_intent response: #{{
        status: response.code.to_i,
        success: success,
        body: body
      }.inspect}")

      {
        status: response.code.to_i,
        success: success,
        body: body
      }
    end

    # Helper pour obtenir l'URL de redirection HelloAsso pour une adhésion
    def membership_checkout_redirect_url(membership, back_url:, error_url:, return_url:)
      result = create_membership_checkout_intent(
        membership,
        back_url: back_url,
        error_url: error_url,
        return_url: return_url
      )

      return nil unless result[:success]
      result[:body]["redirectUrl"]
    end

    private

    # Lecture d'un checkout-intent HelloAsso.
    # Utilise l'endpoint :
    #   GET /v5/organizations/{organizationSlug}/checkout-intents/{checkoutIntentId}
    def fetch_checkout_intent(checkout_intent_id)
      uri = URI.parse(
        "#{api_base_url}/organizations/#{organization_slug}/checkout-intents/#{checkout_intent_id}"
      )

      # Obtenir un token frais
      token = access_token
      raise "HelloAsso access_token introuvable" if token.to_s.strip.empty?

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["accept"] = "application/json"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      response = http.request(request)

      # Si 401 (Unauthorized), le token a peut-être expiré, réessayer une fois avec un nouveau token
      if response.code.to_i == 401
        Rails.logger.warn("[HelloassoService] Token expiré (401), réessai avec un nouveau token...")
        token = fetch_access_token![:access_token]
        request["Authorization"] = "Bearer #{token}"
        response = http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise "HelloAsso checkout-intent fetch error (#{response.code}): #{response.body}"
      end

      JSON.parse(response.body)
    end
  end
end

