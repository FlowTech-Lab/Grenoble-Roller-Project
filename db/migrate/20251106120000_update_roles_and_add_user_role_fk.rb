class UpdateRolesAndAddUserRoleFk < ActiveRecord::Migration[8.0]
  def change
    change_table :roles do |t|
      t.string  :code,  limit: 50
      t.integer :level, limit: 2
    end

    reversible do |dir|
      dir.up do
        # Backfill des colonnes nouvellement ajoutées pour éviter les NULL avant contraintes
        # On utilise une classe anonyme ActiveRecord indépendante du modèle applicatif
        migration_role = Class.new(ActiveRecord::Base) do
          self.table_name = "roles"
        end

        migration_role.reset_column_information
        # Génère des codes uniques basés sur le name (fallback ROLE_<id>) et un niveau par pas de 10
        migration_role.order(:id).find_each.with_index(1) do |role, idx|
          generated_code = if role.respond_to?(:name) && role[:name].present?
                              role[:name].to_s.upcase.gsub(/\s+/, "_")
          else
                              "ROLE_#{role.id || idx}"
          end
          generated_level = role[:level].presence || (idx * 10)
          # update_columns pour éviter validations/callbacks
          role.update_columns(code: role[:code].presence || generated_code,
                              level: generated_level)
        end
      end
    end

    # Index unique une fois les codes remplis
    add_index :roles, :code, unique: true

    # Ajoute la contrainte de clé étrangère user.role_id -> roles.id
    add_foreign_key :users, :roles, column: :role_id

    # Contraintes NOT NULL sur roles.code et roles.level
    change_column_null :roles, :code, false
    change_column_null :roles, :level, false
  end
end
