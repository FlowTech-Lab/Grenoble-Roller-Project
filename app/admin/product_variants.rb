# frozen_string_literal: true

ActiveAdmin.register ProductVariant do
  menu priority: 3, label: "Variantes Produits", parent: "Boutique"

  includes :product, :option_values

  permit_params :product_id, :sku, :price_cents, :currency, :stock_qty, :is_active,
                option_value_ids: []

  scope :all, default: true
  scope("Actives") { |variants| variants.where(is_active: true) }
  scope("Inactives") { |variants| variants.where(is_active: false) }
  scope("En rupture de stock") { |variants| variants.where("stock_qty <= 0") }
  scope("En stock") { |variants| variants.where("stock_qty > 0") }

  index do
    selectable_column
    id_column
    column "Produit" do |variant|
      link_to variant.product.name, activeadmin_product_path(variant.product)
    end
    column "SKU" do |variant|
      variant.sku
    end
    column "Options" do |variant|
      options = variant.option_values.includes(:option_type).sort_by { |ov| [ ov.option_type.name, ov.value ] }.map do |ov|
        type_name = ov.option_type.name == "color" ? "Couleur" : (ov.option_type.name == "size" ? "Taille" : ov.option_type.presentation)
        "#{type_name}: #{ov.presentation}"
      end
      if options.any?
        options.join(" | ")
      else
        span "Aucune option", style: "color: #999; font-style: italic;"
      end
    end
    column "Prix" do |variant|
      number_to_currency(variant.price_cents / 100.0, unit: variant.currency)
    end
    column "Stock" do |variant|
      if variant.stock_qty <= 0
        status_tag("Rupture", class: "error")
      elsif variant.stock_qty < 10
        status_tag(variant.stock_qty, class: "warning")
      else
        variant.stock_qty
      end
    end
    column "Statut" do |variant|
      status_tag(variant.is_active ? "Actif" : "Inactif", class: variant.is_active ? "ok" : "warning")
    end
    column :created_at
    actions
  end

  filter :product
  filter :sku
  filter :is_active
  filter :stock_qty
  filter :created_at

  show do
    attributes_table do
      row :product do |variant|
        link_to variant.product.name, activeadmin_product_path(variant.product)
      end
      row :sku
      row "Options" do |variant|
        options = variant.option_values.includes(:option_type).sort_by { |ov| [ ov.option_type.name, ov.value ] }.map do |ov|
          type_name = ov.option_type.name == "color" ? "Couleur" : (ov.option_type.name == "size" ? "Taille" : ov.option_type.presentation)
          "#{type_name}: #{ov.presentation}"
        end
        if options.any?
          options.join(", ")
        else
          "Aucune option"
        end
      end
      row :price_cents do |variant|
        number_to_currency(variant.price_cents / 100.0, unit: variant.currency)
      end
      row :stock_qty do |variant|
        if variant.stock_qty <= 0
          status_tag("Rupture de stock", class: "error")
        elsif variant.stock_qty < 10
          status_tag("#{variant.stock_qty} (stock faible)", class: "warning")
        else
          "#{variant.stock_qty} en stock"
        end
      end
      row :is_active do |variant|
        status_tag(variant.is_active ? "Actif" : "Inactif", class: variant.is_active ? "ok" : "warning")
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs "Variante" do
      f.input :product,
              collection: Product.order(:name).map { |p| [ p.name, p.id ] },
              hint: "Le produit parent qui regroupe cette variante (description, image, catégorie)"
      f.input :sku,
              hint: "Code SKU unique pour cette variante (ex: VESTE-NOIR-M)"
      f.input :price_cents,
              label: "Prix (cents)",
              hint: "Prix en centimes (ex: 4000 = 40.00€). Peut différer du prix du produit parent."
      f.input :currency,
              input_html: { value: f.object.currency || "EUR" }
      f.input :stock_qty,
              hint: "⚠️ IMPORTANT : Le stock est géré uniquement au niveau des variantes, pas au niveau du produit."
      f.input :is_active,
              hint: "Désactiver pour masquer cette variante sur le site"
    end

    f.inputs "Options (Couleur, Taille)" do
      para "Sélectionnez les options qui définissent cette variante (ex: Couleur: Noir + Taille: M)",
           style: "color: #666; margin-bottom: 10px; font-size: 13px;"
      f.input :option_values,
              as: :check_boxes,
              collection: OptionValue.includes(:option_type).order("option_types.name, option_values.value").map { |ov|
                type_name = ov.option_type.name == "color" ? "Couleur" : (ov.option_type.name == "size" ? "Taille" : ov.option_type.presentation)
                [ "#{type_name}: #{ov.presentation}", ov.id ]
              },
              hint: "Cochez au moins une option (couleur et/ou taille)"
    end

    f.actions
  end
end
