# config/routes.rb
Rails.application.routes.draw do
  # Existing health check route
  get "up" => "rails/health#show", as: :rails_health_check

  # Articles route
  resources :articles, only: [:index]

  # Scraped feeds and articles routes
  resources :scraped_feeds do
    resources :scraped_articles, only: [:index]
  end

  # Root route
  root to: "pages#home"

  # Reports routes
  resources :reports, only: [:new, :create, :show] do
    post 'generate', on: :collection, as: :generate
  end
end
