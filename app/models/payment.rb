class Payment < ApplicationRecord
  has_many :orders, dependent: :nullify
  has_many :attendances, dependent: :nullify
end

# Un paiement peut être associé à plusieurs commandes et attendances
# Toutes les orders/attendances qui avaient ce payment_id verront leur payment_id remis à nil
# Ça évite l'erreur FK (foreign key) tout en préservant les commandes/attendances (tu ne veux pas les effacer juste parce que le paiement a disparu).