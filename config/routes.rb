Rails.application.routes.draw do
  # Keep existing devise and health check routes

  get "up" => "rails/health#show", as: :rails_health_check

  # Update article routes to use resources
  resources :articles, only: [:index]

  # Keep your current root route
  root to: "pages#home"

  # Report routes
  get 'reports/new', to: 'reports#new', as: 'new_report'
  post 'reports/generate', to: 'reports#generate', as: 'generate_report'

  # Add this line for the view route (view report inline in the browser)
  get 'reports/view', to: 'reports#view', as: 'view_report'

  # Add this line for the download route
  get 'reports/download', to: 'reports#download', as: 'download_report'
end
