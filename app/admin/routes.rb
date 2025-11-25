ActiveAdmin.register Route do
  menu priority: 2

  permit_params :name, :description, :distance_km, :elevation_m, :difficulty,
                :gpx_url, :map_image_url, :safety_notes

  scope :all, default: true
  scope("Faciles") { |routes| routes.where(difficulty: "easy") }
  scope("Intermédiaires") { |routes| routes.where(difficulty: "medium") }
  scope("Difficiles") { |routes| routes.where(difficulty: "hard") }

  index do
    selectable_column
    id_column
    column :name
    column :difficulty do |route|
      status_tag(route.difficulty.presence || "nc", class: "status-#{route.difficulty}")
    end
    column :distance_km
    column :elevation_m
    column :updated_at
    actions
  end

  filter :name
  filter :difficulty, as: :select, collection: -> { Route.distinct.pluck(:difficulty).compact }
  filter :distance_km
  filter :elevation_m
  filter :created_at

  show do
    attributes_table do
      row :name
      row :difficulty
      row :distance_km
      row :elevation_m
      row :gpx_url
      row :map_image_url
      row :description
      row :safety_notes
      row :created_at
      row :updated_at
    end

    panel "Événements associés" do
      table_for route.events.order(start_at: :desc) do
        column :title
        column :status do |event|
          status_tag(event.status)
        end
        column :start_at
        column :creator_user
      end
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs "Parcours" do
      f.input :name
      f.input :difficulty, as: :select, collection: %w[easy medium hard], include_blank: "Non défini"
      f.input :distance_km
      f.input :elevation_m
      f.input :gpx_url
      f.input :map_image_url
      f.input :description
      f.input :safety_notes
    end

    f.actions
  end
end
