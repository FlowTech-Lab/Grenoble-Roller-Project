class AddPendingStatusToAttendances < ActiveRecord::Migration[8.1]
  def up
    # Ajouter le statut "pending" à l'enum (Rails gère automatiquement les enums, mais on doit s'assurer que la valeur est acceptée)
    # Pas besoin de modifier la colonne car Rails gère les enums comme des strings
    # On ajoute juste une contrainte de validation dans le modèle
  end

  def down
    # Pas de rollback nécessaire car on ne modifie pas la structure de la base
  end
end
