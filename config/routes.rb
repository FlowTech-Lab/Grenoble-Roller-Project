Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  
  # Route pour le toggle du mode maintenance (controller personnalisé)
  post '/admin/maintenance/toggle', to: 'admin/maintenance_toggle#toggle', as: 'admin_maintenance_toggle'
  
  # Page maintenance simple (optionnel, pour tests)
  get '/maintenance', to: proc { |env| 
    [
      200,
      { 'Content-Type' => 'text/html' },
      [File.read(Rails.root.join('public', 'maintenance.html'))]
    ]
  }
  
  devise_for :users, controllers: {
    registrations: "registrations",
    sessions: "sessions",
    passwords: "passwords",
    confirmations: "confirmations"
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  # Standard Rails endpoint - simple check (no DB queries)
  get "up" => "rails/health#show", as: :rails_health_check

  # Advanced health check with database connection and migrations status
  # Returns JSON with detailed status (DB + migrations) - useful for monitoring/alerting
  get "health" => "health#check", as: :health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  root "pages#index"

  # Static pages
  get "/a-propos", to: "pages#about", as: "about"
  # Redirection 301 de /association vers /a-propos (fusion des pages)
  get "/association", to: redirect("/a-propos", status: 301), as: "association"

  # Shop
  resources :products, only: [ :index, :show ]
  get "/shop", to: "products#index", as: "shop"

  # Cart
  resource :cart, only: [ :show ] do
    post :add_item
    patch :update_item
    delete :remove_item
    delete :clear
  end

  # Orders (Checkout)
  resources :orders, only: [ :index, :new, :create, :show ] do
    member do
      patch :cancel
      post :pay
      post :check_payment
      get :payment_status
    end
  end

  # Memberships - Routes REST/CRUD
  resources :memberships, only: [ :index, :new, :create, :show, :edit, :update, :destroy ] do
    collection do
      # Page de sélection (adhésion seule ou avec T-shirt)
      get :choose
      # Paiement groupé pour plusieurs enfants en attente
      post :pay_multiple
    end
    member do
      # Actions personnalisées (non-CRUD)
      post :pay
      get :payment_status
    end
  end

  # Events (Phase 2)
  resources :events do
    member do
      post :attend
      delete :cancel_attendance
      get :ical, defaults: { format: "ics" }
      patch :toggle_reminder
    end
  end

  # Initiations
  resources :initiations do
    member do
      post :attend
      delete :cancel_attendance
    end
  end

  # Routes pour pré-remplir les champs niveau et distance
  get "/routes/:id/info", to: "routes#info", as: "route_info", defaults: { format: "json" }

  resources :attendances, only: :index

  # Legal pages
  get "/mentions-legales", to: "legal_pages#mentions_legales", as: "mentions_legales"
  get "/politique-confidentialite", to: "legal_pages#politique_confidentialite", as: "politique_confidentialite"
  get "/rgpd", to: "legal_pages#politique_confidentialite" # Alias pour RGPD
  get "/cgv", to: "legal_pages#cgv", as: "cgv"
  get "/conditions-generales-vente", to: "legal_pages#cgv" # Alias pour CGV
  get "/cgu", to: "legal_pages#cgu", as: "cgu"
  get "/conditions-generales-utilisation", to: "legal_pages#cgu" # Alias pour CGU
  get "/contact", to: "legal_pages#contact", as: "contact"

  # Cookie consent
  resource :cookie_consent, only: [] do
    collection do
      get :preferences
      post :accept
      post :reject
      patch :update
    end
  end
end
