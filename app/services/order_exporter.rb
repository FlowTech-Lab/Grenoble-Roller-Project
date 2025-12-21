# frozen_string_literal: true

require 'csv'

class OrderExporter
  def self.to_csv(orders)
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Date', 'Client', 'Email', 'Montant', 'Articles', 'Statut']
      
      orders.each do |order|
        csv << [
          order.id,
          order.created_at.strftime('%d/%m/%Y %H:%M'),
          order.user.name,
          order.user.email,
          "#{order.total_cents / 100.0}€",
          order.order_items.count,
          order.status
        ]
      end
    end
  end

  def self.to_xlsx(orders)
    # À implémenter avec rubyXL
    to_csv(orders)
  end
end
