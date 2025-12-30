# frozen_string_literal: true

require "csv"

class ProductExporter
  def self.to_csv(products)
    CSV.generate(headers: true) do |csv|
      csv << [ "ID", "Nom", "Catégorie", "Prix", "Stock Total", "Variantes", "SKUs", "Statut" ]

      products.each do |product|
        csv << [
          product.id,
          product.name,
          product.category&.name || "-",
          "#{product.price_cents / 100.0}€",
          product.total_stock,
          product.product_variants.count,
          product.product_variants.pluck(:sku).join("; "),
          product.is_active ? "Actif" : "Inactif"
        ]
      end
    end
  end

  def self.to_xlsx(products)
    # À implémenter avec rubyXL
    # Pour l'instant, utiliser CSV
    to_csv(products)
  end
end
