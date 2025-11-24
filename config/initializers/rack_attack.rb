# frozen_string_literal: true

# Rate limiting avec Rack::Attack
# Conformité sécurité 2025 - Protection contre brute force et spam

# Configuration du cache (utilise Rails.cache)
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

# === PROTECTION CONNEXION (Brute force) ===
# 5 tentatives de connexion par IP toutes les 15 minutes
Rack::Attack.throttle('logins/ip', limit: 5, period: 15.minutes) do |req|
  if req.path == '/users/sign_in' && req.post?
    req.ip
  end
end

# === PROTECTION INSCRIPTION (Spam) ===
# 3 inscriptions par IP par heure
Rack::Attack.throttle('registrations/ip', limit: 3, period: 1.hour) do |req|
  if req.path == '/users' && req.post?
    req.ip
  end
end

# === PROTECTION RESET PASSWORD ===
# 3 demandes de reset par IP par heure
Rack::Attack.throttle('password_resets/ip', limit: 3, period: 1.hour) do |req|
  if req.path == '/users/password' && req.post?
    req.ip
  end
end

# === PROTECTION GLOBALE ===
# 300 requêtes par IP par minute (protection DDoS basique)
Rack::Attack.throttle('req/ip', limit: 300, period: 1.minute) do |req|
  req.ip
end

# === WHITELIST (Développement) ===
# En développement, pas de rate limiting pour localhost
if Rails.env.development?
  Rack::Attack.safelist('allow-localhost') do |req|
    req.ip == '127.0.0.1' || req.ip == '::1'
  end
end

# === CUSTOM RESPONSE ===
Rack::Attack.throttled_responder = lambda do |env|
  match_data = env['rack.attack.match_data']
  retry_after = match_data ? match_data[:period] : 60
  
  [
    429,
    {
      'Content-Type' => 'text/html; charset=utf-8',
      'Retry-After' => retry_after.to_s
    },
    ['<html><body><h1>Trop de tentatives</h1><p>Veuillez réessayer plus tard.</p></body></html>']
  ]
end

