class AddInitiationFieldsToEvents < ActiveRecord::Migration[8.0]
  def change
    # Safety check : Vérifier si colonne type existe déjà
    unless column_exists?(:events, :type)
      add_column :events, :type, :string
      add_index :events, :type

      # Mettre à jour les événements existants avec type par défaut
      # Utiliser 'Event' (modèle de base) car 'Event::Rando' n'existe pas
      # Note: Si des événements ont été créés avec 'Event::Rando' par erreur,
      # ils seront corrigés par la migration 20251203173759_fix_existing_events_type
      execute "UPDATE events SET type = 'Event' WHERE type IS NULL"
    end

    add_column :events, :is_recurring, :boolean, default: false unless column_exists?(:events, :is_recurring)
    add_column :events, :recurring_day, :string unless column_exists?(:events, :recurring_day)
    add_column :events, :recurring_time, :string unless column_exists?(:events, :recurring_time)
    add_column :events, :season, :string unless column_exists?(:events, :season)
    add_column :events, :recurring_start_date, :date unless column_exists?(:events, :recurring_start_date)
    add_column :events, :recurring_end_date, :date unless column_exists?(:events, :recurring_end_date)

    add_index :events, [ :type, :season ], name: "index_events_on_type_and_season" unless index_exists?(:events, [ :type, :season ])
  end
end
