FactoryBot.define do
  factory :roller_stock do
    transient do
      size_index { 0 }
    end
    
    size do
      available_sizes = RollerStock::SIZES - RollerStock.pluck(:size)
      if available_sizes.any?
        available_sizes.first
      else
        # Si toutes les tailles sont prises, utiliser une taille non utilisée avec un index
        RollerStock::SIZES[size_index % RollerStock::SIZES.length]
      end
    end
    quantity { 1 }
    is_active { true }
  end
end
