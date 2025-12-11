ActiveAdmin.register OptionType do
  menu priority: 4, label: "Types d'options", parent: "Boutique"

  permit_params :name

  index do
    selectable_column
    id_column
    column :name
    column :option_values_count do |option_type|
      option_type.option_values.count
    end
    column :created_at
    actions
  end

  filter :name
  filter :created_at

  show do
    attributes_table do
      row :id
      row :name
      row :created_at
      row :updated_at
    end

    panel "Option Values" do
      table_for option_type.option_values do
        column :id
        column :value
        column :created_at
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :name
    end
    f.actions
  end
end

