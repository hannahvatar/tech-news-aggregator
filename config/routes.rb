Rails.application.routes.draw do
  # Keep existing devise and health check routes
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check

  # Update article routes to use resources
  resources :articles, only: [:index]

  # Keep your current root route
  root to: "pages#home"
end
