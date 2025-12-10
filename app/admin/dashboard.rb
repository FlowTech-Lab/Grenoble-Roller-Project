# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    # Statistiques principales en grid
    div style: "display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px;" do
      # Card Événements à valider
      div style: "background: #fff; border: 1px solid #ddd; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);" do
        div style: "font-size: 32px; font-weight: bold; color: #d9534f; margin-bottom: 10px;" do
          pending_count = Event.pending_validation.count
          if pending_count > 0
            link_to pending_count, admin_events_path(scope: "en_attente_de_validation"), style: "color: #d9534f; text-decoration: none;"
          else
            pending_count
          end
        end
        div style: "color: #666; font-size: 14px;" do
          "Événements à valider"
        end
      end

      # Card Utilisateurs
      div style: "background: #fff; border: 1px solid #ddd; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);" do
        div style: "font-size: 32px; font-weight: bold; color: #337ab7; margin-bottom: 10px;" do
          link_to User.count, admin_users_path, style: "color: #337ab7; text-decoration: none;"
        end
        div style: "color: #666; font-size: 14px;" do
          "Utilisateurs"
        end
      end

      # Card Commandes en attente
      div style: "background: #fff; border: 1px solid #ddd; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);" do
        div style: "font-size: 32px; font-weight: bold; color: #f0ad4e; margin-bottom: 10px;" do
          pending_orders = Order.where(status: "pending").count
          if pending_orders > 0
            link_to pending_orders, admin_orders_path(scope: "pending"), style: "color: #f0ad4e; text-decoration: none;"
          else
            span pending_orders
          end
        end
        div style: "color: #666; font-size: 14px;" do
          "Commandes en attente"
        end
      end

      # Card Chiffre d'affaires boutique (commandes)
      div style: "background: #fff; border: 1px solid #ddd; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);" do
        div style: "font-size: 32px; font-weight: bold; color: #5cb85c; margin-bottom: 10px;" do
          shop_revenue_cents = Order.where(status: %w[paid shipped completed]).sum(:total_cents)
          shop_revenue = shop_revenue_cents / 100.0
          number_to_currency(shop_revenue, unit: "€", separator: ",", delimiter: " ")
        end
        div style: "color: #666; font-size: 14px;" do
          "CA boutique (commandes payées)"
        end
      end

      # Card Adhésions actives
      div style: "background: #fff; border: 1px solid #ddd; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);" do
        div style: "font-size: 32px; font-weight: bold; color: #5cb85c; margin-bottom: 10px;" do
          active_memberships = Membership.active_now.count
          if active_memberships > 0
            link_to active_memberships, admin_memberships_path(scope: "actives"), style: "color: #5cb85c; text-decoration: none;"
          else
            active_memberships
          end
        end
        div style: "color: #666; font-size: 14px;" do
          "Adhésions actives"
        end
      end

      # Card Adhésions en attente
      div style: "background: #fff; border: 1px solid #ddd; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);" do
        div style: "font-size: 32px; font-weight: bold; color: #f0ad4e; margin-bottom: 10px;" do
          pending_memberships = Membership.pending.count
          if pending_memberships > 0
            link_to pending_memberships, admin_memberships_path(scope: "en_attente"), style: "color: #f0ad4e; text-decoration: none;"
          else
            pending_memberships
          end
        end
        div style: "color: #666; font-size: 14px;" do
          "Adhésions en attente"
        end
      end

      # Card Revenus adhésions
      div style: "background: #fff; border: 1px solid #ddd; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);" do
        div style: "font-size: 32px; font-weight: bold; color: #337ab7; margin-bottom: 10px;" do
          current_season = Membership.respond_to?(:current_season_name) ? Membership.current_season_name : nil
          paid_memberships = Membership.where(status: %i[active expired])
          paid_memberships = paid_memberships.where(season: current_season) if current_season
          membership_revenue = paid_memberships.sum { |m| m.total_amount_cents } / 100.0
          number_to_currency(membership_revenue, unit: "€", separator: ",", delimiter: " ")
        end
        div style: "color: #666; font-size: 14px;" do
          if Membership.respond_to?(:current_season_name)
            "Revenus adhésions (saison #{Membership.current_season_name})"
          else
            "Revenus adhésions"
          end
        end
      end

      # Card CA total (boutique + adhésions)
      div style: "background: #fff; border: 1px solid #ddd; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);" do
        div style: "font-size: 32px; font-weight: bold; color: #5bc0de; margin-bottom: 10px;" do
          shop_revenue_cents = Order.where(status: %w[paid shipped completed]).sum(:total_cents)
          current_season = Membership.respond_to?(:current_season_name) ? Membership.current_season_name : nil
          paid_memberships = Membership.where(status: %i[active expired])
          paid_memberships = paid_memberships.where(season: current_season) if current_season
          membership_revenue_cents = paid_memberships.sum { |m| m.total_amount_cents }

          total_revenue = (shop_revenue_cents + membership_revenue_cents) / 100.0
          number_to_currency(total_revenue, unit: "€", separator: ",", delimiter: " ")
        end
        div style: "color: #666; font-size: 14px;" do
          if Membership.respond_to?(:current_season_name)
            "CA total (boutique + adhésions, saison #{Membership.current_season_name})"
          else
            "CA total (boutique + adhésions)"
          end
        end
      end
    end

    # Section Événements à valider (liste simple avec liens)
    panel "📋 Événements à valider", style: "margin-top: 20px;" do
      pending_events = Event.pending_validation.order(created_at: :desc).limit(10)

      if pending_events.any?
        para "Cliquez sur un événement pour le voir et le modifier :", style: "color: #666; margin-bottom: 15px;"

        table_for pending_events, style: "width: 100%;" do
          column "Titre" do |event|
            link_to event.title, admin_event_path(event), style: "color: #337ab7; text-decoration: none; font-weight: 500;"
          end
          column "Créateur" do |event|
            event.creator_user&.email || "N/A"
          end
          column "Date prévue" do |event|
            event.start_at&.strftime("%d/%m/%Y %H:%M") || "N/A"
          end
          column "Inscriptions" do |event|
            "#{event.attendances_count} / #{event.unlimited? ? '∞' : event.max_participants}"
          end
        end

        div style: "margin-top: 20px; text-align: center;" do
          link_to "Voir tous les événements à valider →", admin_events_path(scope: "en_attente_de_validation"),
                  class: "button",
                  style: "background: #337ab7; color: white; padding: 10px 20px; border-radius: 4px; text-decoration: none; display: inline-block;"
        end
      else
        para "✅ Aucun événement en attente de validation", style: "color: #5cb85c; font-weight: bold; text-align: center; padding: 20px;"
      end
    end

    # Section Boutique
    panel "🛒 Statistiques Boutique", style: "margin-top: 20px;" do
      div style: "display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 20px;" do
        div style: "background: #f8f9fa; padding: 15px; border-radius: 4px; border: 1px solid #ddd;" do
          div style: "font-size: 24px; font-weight: bold; color: #337ab7;" do
            link_to Product.count, admin_products_path, style: "color: #337ab7; text-decoration: none;"
          end
          div style: "color: #666; font-size: 13px; margin-top: 5px;" do
            "Produits en catalogue"
          end
        end
        div style: "background: #f8f9fa; padding: 15px; border-radius: 4px; border: 1px solid #ddd;" do
          div style: "font-size: 24px; font-weight: bold; color: #d9534f;" do
            link_to Product.where("stock_qty <= 0").count, admin_products_path(scope: "en_rupture_de_stock"), style: "color: #d9534f; text-decoration: none;"
          end
          div style: "color: #666; font-size: 13px; margin-top: 5px;" do
            "En rupture de stock"
          end
        end
        div style: "background: #f8f9fa; padding: 15px; border-radius: 4px; border: 1px solid #ddd;" do
          div style: "font-size: 24px; font-weight: bold; color: #5cb85c;" do
            completed_orders_count = Order.where(status: %w[paid shipped completed]).count
            link_to completed_orders_count, admin_orders_path(scope: "complétées"), style: "color: #5cb85c; text-decoration: none;"
          end
          div style: "color: #666; font-size: 13px; margin-top: 5px;" do
            "Commandes payées / complétées"
          end
        end

        # CA boutique (commandes payées) dans le bloc Statistiques Boutique
        div style: "background: #f8f9fa; padding: 15px; border-radius: 4px; border: 1px solid #ddd;" do
          div style: "font-size: 24px; font-weight: bold; color: #5cb85c;" do
            shop_revenue_cents = Order.where(status: %w[paid shipped completed]).sum(:total_cents)
            shop_revenue = shop_revenue_cents / 100.0
            number_to_currency(shop_revenue, unit: "€", separator: ",", delimiter: " ")
          end
          div style: "color: #666; font-size: 13px; margin-top: 5px;" do
            "CA boutique (commandes payées)"
          end
        end
      end

      # Commandes récentes
      recent_orders = Order.order(created_at: :desc).limit(5)
      if recent_orders.any?
        para "Commandes récentes :", style: "color: #666; margin-bottom: 10px; font-weight: bold;"
        table_for recent_orders, style: "width: 100%;" do
          column "Utilisateur" do |order|
            if order.user
              link_to order.user.email, admin_user_path(order.user), style: "color: #337ab7; text-decoration: none;"
            else
              "N/A"
            end
          end
          column "Total" do |order|
            number_to_currency(order.total_cents / 100.0, unit: order.currency)
          end
          column "Statut" do |order|
            case order.status
            when "pending"
              status_tag("En attente", class: "warning")
            when "completed"
              status_tag("Complétée", class: "ok")
            when "cancelled", "canceled"
              status_tag("Annulée", class: "error")
            else
              status_tag(order.status)
            end
          end
          column "Date" do |order|
            order.created_at.strftime("%d/%m/%Y %H:%M")
          end
        end
        div style: "margin-top: 15px; text-align: center;" do
          link_to "Voir toutes les commandes →", admin_orders_path,
                  class: "button",
                  style: "background: #337ab7; color: white; padding: 10px 20px; border-radius: 4px; text-decoration: none; display: inline-block;"
        end
      end
    end

    # Section Adhésions
    panel "👥 Statistiques Adhésions", style: "margin-top: 20px;" do
      div style: "display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 20px;" do
        div style: "background: #f8f9fa; padding: 15px; border-radius: 4px; border: 1px solid #ddd;" do
          div style: "font-size: 24px; font-weight: bold; color: #5cb85c;" do
            link_to Membership.active_now.count, admin_memberships_path(scope: "actives"), style: "color: #5cb85c; text-decoration: none;"
          end
          div style: "color: #666; font-size: 13px; margin-top: 5px;" do
            "Adhésions actives"
          end
        end
        div style: "background: #f8f9fa; padding: 15px; border-radius: 4px; border: 1px solid #ddd;" do
          div style: "font-size: 24px; font-weight: bold; color: #f0ad4e;" do
            link_to Membership.pending.count, admin_memberships_path(scope: "en_attente"), style: "color: #f0ad4e; text-decoration: none;"
          end
          div style: "color: #666; font-size: 13px; margin-top: 5px;" do
            "En attente de paiement"
          end
        end
        div style: "background: #f8f9fa; padding: 15px; border-radius: 4px; border: 1px solid #ddd;" do
          div style: "font-size: 24px; font-weight: bold; color: #337ab7;" do
            link_to Membership.personal.count, admin_memberships_path(scope: "personnelles"), style: "color: #337ab7; text-decoration: none;"
          end
          div style: "color: #666; font-size: 13px; margin-top: 5px;" do
            "Adhésions personnelles (toutes saisons)"
          end
        end
        div style: "background: #f8f9fa; padding: 15px; border-radius: 4px; border: 1px solid #ddd;" do
          div style: "font-size: 24px; font-weight: bold; color: #d9534f;" do
            link_to Membership.children.count, admin_memberships_path(scope: "enfants"), style: "color: #d9534f; text-decoration: none;"
          end
          div style: "color: #666; font-size: 13px; margin-top: 5px;" do
            "Adhésions enfants (toutes saisons)"
          end
        end
        div style: "background: #f8f9fa; padding: 15px; border-radius: 4px; border: 1px solid #ddd;" do
          div style: "font-size: 24px; font-weight: bold; color: #f0ad4e;" do
            link_to Membership.expiring_soon.count, admin_memberships_path(scope: "expirent_bientot"), style: "color: #f0ad4e; text-decoration: none;"
          end
          div style: "color: #666; font-size: 13px; margin-top: 5px;" do
            "Expirent bientôt (30j)"
          end
        end
        div style: "background: #f8f9fa; padding: 15px; border-radius: 4px; border: 1px solid #ddd;" do
          div style: "font-size: 24px; font-weight: bold; color: #337ab7;" do
            total_revenue = Membership.active.sum { |m| m.total_amount_cents } / 100.0
            number_to_currency(total_revenue, unit: "€", separator: ",", delimiter: " ")
          end
          div style: "color: #666; font-size: 13px; margin-top: 5px;" do
            "Revenus adhésions"
          end
        end
      end

      # Adhésions récentes
      recent_memberships = Membership.order(created_at: :desc).limit(5)
      if recent_memberships.any?
        para "Adhésions récentes :", style: "color: #666; margin-bottom: 10px; font-weight: bold;"
        table_for recent_memberships, style: "width: 100%;" do
          column "Utilisateur" do |membership|
            if membership.user
              link_to membership.user.email, admin_user_path(membership.user), style: "color: #337ab7; text-decoration: none;"
            else
              "N/A"
            end
          end
          column "Type" do |membership|
            membership.is_child_membership? ? "Enfant" : "Personnelle"
          end
          column "Nom" do |membership|
            if membership.is_child_membership?
              membership.child_full_name
            else
              membership.user&.email || "N/A"
            end
          end
          column "Total" do |membership|
            number_to_currency(membership.total_amount_cents / 100.0, unit: membership.currency || "EUR")
          end
          column "Statut" do |membership|
            case membership.status
            when "active"
              status_tag("Active", class: "ok")
            when "pending"
              status_tag("En attente", class: "warning")
            when "expired"
              status_tag("Expirée", class: "error")
            else
              status_tag(membership.status)
            end
          end
          column "Date" do |membership|
            membership.created_at.strftime("%d/%m/%Y %H:%M")
          end
        end
        div style: "margin-top: 15px; text-align: center;" do
          link_to "Voir toutes les adhésions →", admin_memberships_path,
                  class: "button",
                  style: "background: #337ab7; color: white; padding: 10px 20px; border-radius: 4px; text-decoration: none; display: inline-block;"
        end
      end
    end

    # Liens rapides vers les sections importantes
    panel "🔗 Accès rapide", style: "margin-top: 20px;" do
      div style: "display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px;" do
        div do
          link_to "📅 Tous les événements", admin_events_path,
                  style: "display: block; padding: 15px; background: #f8f9fa; border: 1px solid #ddd; border-radius: 4px; text-decoration: none; color: #333;"
        end
        div do
          link_to "👥 Tous les utilisateurs", admin_users_path,
                  style: "display: block; padding: 15px; background: #f8f9fa; border: 1px solid #ddd; border-radius: 4px; text-decoration: none; color: #333;"
        end
        div do
          link_to "🛒 Toutes les commandes", admin_orders_path,
                  style: "display: block; padding: 15px; background: #f8f9fa; border: 1px solid #ddd; border-radius: 4px; text-decoration: none; color: #333;"
        end
        div do
          link_to "📦 Tous les produits", admin_products_path,
                  style: "display: block; padding: 15px; background: #f8f9fa; border: 1px solid #ddd; border-radius: 4px; text-decoration: none; color: #333;"
        end
        div do
          link_to "📧 Messages de contact", admin_contact_messages_path,
                  style: "display: block; padding: 15px; background: #f8f9fa; border: 1px solid #ddd; border-radius: 4px; text-decoration: none; color: #333;"
        end
        div do
          link_to "👥 Toutes les adhésions", admin_memberships_path,
                  style: "display: block; padding: 15px; background: #f8f9fa; border: 1px solid #ddd; border-radius: 4px; text-decoration: none; color: #333;"
        end
      end
    end
  end # content
end
