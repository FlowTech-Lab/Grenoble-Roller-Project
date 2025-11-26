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
  end
end


