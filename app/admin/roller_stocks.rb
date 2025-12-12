ActiveAdmin.register RollerStock do
  menu priority: 15, label: "Stock Rollers", parent: "Matériel"
  
  permit_params :size, :quantity, :is_active
  
  index do
    selectable_column
    id_column
    column :size do |stock|
      "#{stock.size} (EU)"
    end
    column :quantity do |stock|
      if stock.quantity > 0
        status_tag("#{stock.quantity} disponible#{'s' if stock.quantity > 1}", class: "ok")
      else
        status_tag("Rupture de stock", class: "error")
      end
    end
    column :is_active do |stock|
      status_tag(stock.is_active? ? "Actif" : "Inactif", class: stock.is_active? ? "ok" : "no")
    end
    column :created_at
    column :updated_at
    actions
  end
  
  filter :size
  filter :quantity
  filter :is_active, as: :boolean
  filter :created_at
  filter :updated_at
  
  show do
    attributes_table do
      row :id
      row :size do |stock|
        "#{stock.size} (EU)"
      end
      row :quantity do |stock|
        if stock.quantity > 0
          status_tag("#{stock.quantity} disponible#{'s' if stock.quantity > 1}", class: "ok")
        else
          status_tag("Rupture de stock", class: "error")
        end
      end
      row :is_active do |stock|
        status_tag(stock.is_active? ? "Actif" : "Inactif", class: stock.is_active? ? "ok" : "no")
      end
      row :created_at
      row :updated_at
    end
    
    panel "Demandes en attente" do
      pending_requests = Attendance.where(needs_equipment: true, roller_size: resource.size, status: ["registered", "paid"])
      if pending_requests.any?
        table_for pending_requests.limit(10) do
          column "Participant" do |attendance|
            attendance.participant_name
          end
          column "Événement" do |attendance|
            link_to attendance.event.title, admin_event_path(attendance.event)
          end
          column "Date" do |attendance|
            attendance.event.start_at.strftime("%d/%m/%Y") if attendance.event.start_at
          end
          column "Statut" do |attendance|
            status_tag(attendance.status)
          end
        end
        para "Total: #{pending_requests.count} demande(s)"
      else
        para "Aucune demande en attente pour cette taille."
      end
    end
  end
  
  form do |f|
    f.semantic_errors
    f.inputs "Stock de rollers" do
      f.input :size, 
              as: :select, 
              collection: RollerStock::SIZES.map { |s| [s, s] },
              prompt: "Choisir une taille",
              hint: "Taille en pointure européenne (EU)"
      f.input :quantity,
              hint: "Nombre de paires disponibles en stock"
      f.input :is_active,
              as: :boolean,
              hint: "Désactiver pour masquer cette taille du formulaire d'inscription"
    end
    f.actions
  end
  
  controller do
    def create
      @roller_stock = RollerStock.new(permitted_params[:roller_stock])
      
      if @roller_stock.save
        redirect_to resource_path(@roller_stock), notice: "Stock créé avec succès."
      else
        render :new
      end
    end
  end
end

