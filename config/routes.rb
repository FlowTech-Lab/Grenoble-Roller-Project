Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  devise_for :users, controllers: {
    passwords: 'passwords'
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  root 'pages#index'
  
  # Static pages
  get '/association', to: 'pages#association', as: 'association'

  # Shop
  resources :products, only: [:index, :show]
  get '/shop', to: 'products#index', as: 'shop'

  # Cart
  resource :cart, only: [:show] do
    post :add_item
    patch :update_item
    delete :remove_item
    delete :clear
  end

  # Orders (Checkout)
  resources :orders, only: [:index, :new, :create, :show] do
    member do
      patch :cancel
    end
  end
end
