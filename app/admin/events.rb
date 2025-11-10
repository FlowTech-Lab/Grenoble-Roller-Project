ActiveAdmin.register Event do
  menu priority: 1
  includes :creator_user, :route

  permit_params :creator_user_id, :status, :start_at, :duration_min, :title,
                :description, :price_cents, :currency, :location_text,
                :meeting_lat, :meeting_lng, :route_id, :cover_image_url,
                :max_participants

  scope :all, default: true
  scope('À venir') { |events| events.upcoming }
  scope('Publies') { |events| events.published }
  scope('Brouillons') { |events| events.where(status: 'draft') }
  scope('Annulés') { |events| events.where(status: 'canceled') }

  index do
    selectable_column
    id_column
    column :title
    column :status do |event|
      status_tag(event.status)
    end
    column :start_at
    column :duration_min
    column :max_participants do |event|
      event.unlimited? ? 'Illimité' : event.max_participants
    end
    column :attendances_count
    column :route
    column :creator_user
    column :price_cents do |event|
      number_to_currency(event.price_cents / 100.0, unit: event.currency)
    end
    actions
  end

  filter :title
  filter :status, as: :select, collection: Event.statuses.keys
  filter :route
  filter :creator_user, collection: -> { User.order(:email) }
  filter :start_at
  filter :created_at

  show do
    attributes_table do
      row :title
      row :status
      row :start_at
      row :duration_min
      row :max_participants do |event|
        event.unlimited? ? 'Illimité (0)' : event.max_participants
      end
      row :attendances_count
      row :remaining_spots do |event|
        if event.unlimited?
          'Illimité'
        elsif event.full?
          'Complet (0)'
        else
          "#{event.remaining_spots} places restantes"
        end
      end
      row :creator_user
      row :route
      row :price_cents do |event|
        number_to_currency(event.price_cents / 100.0, unit: event.currency)
      end
      row :currency
      row :location_text
      row :meeting_lat
      row :meeting_lng
      row :cover_image_url
      row :description
      row :created_at
      row :updated_at
    end

    panel 'Inscriptions' do
      table_for event.attendances.includes(:user) do
        column :user
        column :status do |attendance|
          status_tag(attendance.status)
        end
        column :payment
        column :created_at
      end
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs 'Informations générales' do
      f.input :title
      f.input :status, as: :select, collection: Event.statuses.keys
      f.input :route
      f.input :creator_user, collection: User.order(:email)
      f.input :start_at, as: :datetime_select
      f.input :duration_min
      f.input :max_participants, label: 'Nombre maximum de participants', hint: 'Mettez 0 pour un nombre illimité de participants.'
      f.input :location_text
      f.input :description
    end

    f.inputs 'Tarification' do
      f.input :price_cents, label: 'Prix (cents)'
      f.input :currency, input_html: { value: f.object.currency || 'EUR' }
    end

    f.inputs 'Point de rendez-vous' do
      f.input :meeting_lat
      f.input :meeting_lng
      f.input :cover_image_url
    end

    f.actions
  end
end
