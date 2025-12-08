class FixExistingEventsType < ActiveRecord::Migration[8.0]
  def up
    # Corriger les événements existants qui ont été créés avec type = 'Event::Rando'
    # (qui n'existe pas) vers 'Event'
    execute "UPDATE events SET type = 'Event' WHERE type = 'Event::Rando' OR type IS NULL"
  end

  def down
    # Rollback : remettre Event::Rando (mais ça ne fonctionnera pas car le modèle n'existe pas)
    # En pratique, on ne peut pas vraiment rollback cette correction
    # Car Event::Rando n'existe pas
    # On laisse vide car c'est une correction de données
  end
end

