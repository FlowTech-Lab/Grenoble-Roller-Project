# frozen_string_literal: true

require 'database_cleaner/active_record'

# Désactiver la protection DatabaseCleaner pour les URLs distantes (environnement de test contrôlé)
DatabaseCleaner.allow_remote_database_url = true

RSpec.configure do |config|
  # ✅ CRITIQUE: Les tests request ne peuvent pas utiliser les transactions
  # car Devise a besoin d'accéder à la BD depuis la session
  # Transactional tests SEULEMENT pour model/controller (pas request!)
  
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    # Par défaut, utiliser les transactions (plus rapide)
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :request) do
    # ❌ Les tests request ne peuvent pas utiliser les transactions
    # car Devise a besoin d'accéder à la BD depuis la session
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each, js: true) do
    # Les tests JavaScript nécessitent aussi truncation
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
