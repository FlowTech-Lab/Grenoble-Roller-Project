# frozen_string_literal: true

ActiveAdmin.register Membership do
  menu priority: 3, label: "Adhésions", parent: "Utilisateurs"

  includes :user, :payment, :tshirt_variant

  permit_params :user_id, :category, :status, :start_date, :end_date, :amount_cents, :currency,
                :season, :is_child_membership, :is_minor, :child_first_name, :child_last_name,
                :child_date_of_birth, :parent_authorization, :parent_authorization_date,
                :parent_name, :parent_email, :parent_phone, :tshirt_variant_id, :tshirt_price_cents,
                :wants_whatsapp, :wants_email_info, :rgpd_consent, :legal_notices_accepted,
                :ffrs_data_sharing_consent, :payment_id,
                :health_q1, :health_q2, :health_q3, :health_q4, :health_q5,
                :health_q6, :health_q7, :health_q8, :health_q9, :health_questionnaire_status,
                :medical_certificate

  scope :all, default: true
  scope("Actives") { |memberships| memberships.active_now }
  scope("En attente") { |memberships| memberships.pending }
  scope("Expirées") { |memberships| memberships.expired }
  scope("Personnelles") { |memberships| memberships.personal }
  scope("Enfants") { |memberships| memberships.children }
  scope("Expirent bientôt") { |memberships| memberships.expiring_soon }

  index do
    selectable_column
    id_column
    column :user
    column :type do |membership|
      if membership.is_child_membership?
        status_tag("Enfant", class: "warning")
      else
        status_tag("Personnelle", class: "ok")
      end
    end
    column :category do |membership|
      membership.category == "standard" ? "Standard" : "FFRS"
    end
    column :status do |membership|
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
    column :season
    column :amount_cents do |membership|
      number_to_currency(membership.total_amount_cents / 100.0, unit: membership.currency || "EUR")
    end
    column :dates do |membership|
      if membership.start_date && membership.end_date
        "#{membership.start_date.strftime("%d/%m/%Y")} → #{membership.end_date.strftime("%d/%m/%Y")}"
      else
        "N/A"
      end
    end
    column :child_name do |membership|
      if membership.is_child_membership?
        membership.child_full_name
      else
        "-"
      end
    end
    column :payment
    column :created_at do |membership|
      membership.created_at.strftime("%d/%m/%Y %H:%M")
    end
    actions
  end

  filter :user
  filter :status, as: :select, collection: Membership.statuses.map { |k, v| [ k.humanize, k ] }
  filter :category, as: :select, collection: Membership.categories.map { |k, v| [ k.humanize, k ] }
  filter :is_child_membership, label: "Type", as: :select, collection: [ [ "Personnelle", false ], [ "Enfant", true ] ]
  filter :season
  filter :start_date
  filter :end_date
  filter :created_at

  show do
    attributes_table do
      row :user
      row :type do |membership|
        membership.is_child_membership? ? "Enfant" : "Personnelle"
      end
      row :category do |membership|
        membership.category == "standard" ? "Standard (10€)" : "FFRS (56.55€)"
      end
      row :status do |membership|
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
      row :season
      row :start_date
      row :end_date
      row :amount_cents do |membership|
        number_to_currency(membership.amount_cents / 100.0, unit: membership.currency || "EUR")
      end
      row :total_amount_cents do |membership|
        number_to_currency(membership.total_amount_cents / 100.0, unit: membership.currency || "EUR")
      end
      row :currency
      row :payment
      row :tshirt_variant
      row :tshirt_price_cents do |membership|
        if membership.tshirt_price_cents
          number_to_currency(membership.tshirt_price_cents / 100.0, unit: membership.currency || "EUR")
        else
          "-"
        end
      end
    end

    if membership.is_child_membership?
      panel "Informations enfant" do
        attributes_table_for membership do
          row :child_first_name
          row :child_last_name
          row :child_full_name
          row :child_date_of_birth
          row :child_age do |m|
            "#{m.child_age} ans"
          end
          row :parent_name
          row :parent_email
          row :parent_phone
          row :parent_authorization do |m|
            m.parent_authorization ? status_tag("Oui", class: "ok") : status_tag("Non", class: "error")
          end
          row :parent_authorization_date
        end
      end
    end

    panel "Questionnaire de santé" do
      attributes_table_for membership do
        row :health_questionnaire_status do |m|
          case m.health_questionnaire_status
          when "ok"
            status_tag("OK", class: "ok")
          when "medical_required"
            status_tag("Certificat requis", class: "warning")
          else
            "-"
          end
        end
        row :medical_certificate do |m|
          if m.medical_certificate.attached?
            link_to "Télécharger le certificat", rails_blob_path(m.medical_certificate, disposition: "attachment"), target: "_blank"
          else
            "Non fourni"
          end
        end
      end
    end

    panel "Consentements" do
      attributes_table_for membership do
        row :rgpd_consent do |m|
          m.rgpd_consent ? status_tag("Oui", class: "ok") : status_tag("Non", class: "error")
        end
        row :legal_notices_accepted do |m|
          m.legal_notices_accepted ? status_tag("Oui", class: "ok") : status_tag("Non", class: "error")
        end
        row :ffrs_data_sharing_consent do |m|
          m.ffrs_data_sharing_consent ? status_tag("Oui", class: "ok") : status_tag("Non", class: "error")
        end
      end
    end

    attributes_table do
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs "Adhésion" do
      f.input :user, collection: User.order(:email).map { |u| [ u.email, u.id ] }
      f.input :category, as: :select, collection: {
        "Standard (10€)" => "standard",
        "FFRS (56.55€)" => "with_ffrs"
      }, prompt: "Sélectionnez une catégorie"
      f.input :status, as: :select, collection: {
        "En attente" => "pending",
        "Active" => "active",
        "Expirée" => "expired"
      }, prompt: "Sélectionnez un statut"
      f.input :season
      f.input :start_date, as: :date_picker
      f.input :end_date, as: :date_picker
      f.input :amount_cents, label: "Montant (cents)"
      f.input :currency, input_html: { value: f.object.currency || "EUR" }
      f.input :is_child_membership, label: "Adhésion enfant"
      f.input :payment
    end

    f.inputs "Informations enfant (si adhésion enfant)" do
      f.input :child_first_name
      f.input :child_last_name
      f.input :child_date_of_birth, as: :date_picker
      f.input :parent_name
      f.input :parent_email
      f.input :parent_phone
      f.input :parent_authorization, label: "Autorisation parentale"
      f.input :parent_authorization_date, as: :date_picker
    end

    f.inputs "Options" do
      f.input :tshirt_variant
      f.input :tshirt_price_cents, label: "Prix T-shirt (cents)"
    end

    f.actions
  end
end
