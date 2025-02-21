# config/routes.rb
Rails.application.routes.draw do
  # Existing health check route
  get "up" => "rails/health#show", as: :rails_health_check

  # Articles route with both regular and scraped articles
  resources :articles, only: [:index, :show] do
    # Add a custom route for scraped articles
    get 'scraped/:id', to: 'articles#show_scraped', on: :collection, as: :scraped
  end

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
