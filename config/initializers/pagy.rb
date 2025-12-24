# frozen_string_literal: true

# Pagy configuration
require 'pagy/extras/bootstrap'
require 'pagy/extras/overflow'

Pagy::DEFAULT[:items] = 25 # Items par page par défaut
Pagy::DEFAULT[:size] = [1, 4, 4, 1] # [first, page, gap, last]
Pagy::DEFAULT[:overflow] = :last_page # Gérer les pages hors limites
