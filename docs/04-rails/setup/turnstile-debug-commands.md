# 🔍 Commandes de Debug Turnstile

## Suivre les logs en temps réel

```bash
# Dans un terminal, lancer cette commande
docker compose -f ops/dev/docker-compose.yml logs -f web
```

Puis dans un autre terminal ou navigateur, tenter une connexion.

---

## Vérifier les logs après une tentative

```bash
# Chercher toutes les erreurs Turnstile
docker compose -f ops/dev/docker-compose.yml logs web --tail=500 | grep -i -A 10 -B 5 "turnstile\|422\|verification\|security\|failed"

# Chercher les requêtes POST vers sign_in
docker compose -f ops/dev/docker-compose.yml logs web --tail=500 | grep -i -A 20 "POST.*sign_in\|sessions#create"
```

---

## Vérifier le fichier log Rails directement

```bash
# Voir les 100 dernières lignes
docker compose -f ops/dev/docker-compose.yml exec web tail -100 log/development.log

# Chercher les erreurs Turnstile
docker compose -f ops/dev/docker-compose.yml exec web grep -i "turnstile\|422\|verification" log/development.log | tail -50
```

---

## Tester la vérification Turnstile manuellement

```bash
# Tester que le concern fonctionne
docker compose -f ops/dev/docker-compose.yml run --rm web bin/rails runner "
  class TestController < ActionController::Base
    include TurnstileVerifiable
    
    def test_turnstile
      params = ActionController::Parameters.new({'cf-turnstile-response' => 'test-token'})
      puts 'Test Turnstile verification...'
      # Note: Ceci nécessiterait une vraie instance de controller
    end
  end
"
```

---

## Vérifier la configuration

```bash
# Vérifier que les clés sont présentes
docker compose -f ops/dev/docker-compose.yml run --rm web bin/rails runner "
  site_key = Rails.application.credentials.dig(:turnstile, :site_key)
  secret_key = Rails.application.credentials.dig(:turnstile, :secret_key)
  puts 'Site Key: ' + (site_key.present? ? '✅ Présente' : '❌ MANQUANTE')
  puts 'Secret Key: ' + (secret_key.present? ? '✅ Présente' : '❌ MANQUANTE')
  puts 'Environment: ' + Rails.env
  puts 'Test mode skip: ' + Rails.env.test?.to_s
"
```

