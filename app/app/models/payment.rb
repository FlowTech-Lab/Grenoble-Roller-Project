class Payment < ApplicationRecord
  has_many :orders, dependent: :nullify
end

# Un paiement peut être associé à plusieurs commandes
# Toutes les orders qui avaient ce payment_id verront leur payment_id remis à nil
# Ça évite l’erreur FK (foreign key) tout en préservant les commandes (tu ne veux pas les effacer juste parce que le paiement a disparu).