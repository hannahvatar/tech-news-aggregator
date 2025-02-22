# config/routes.rb
Rails.application.routes.draw do
  # Existing health check route
  get "up" => "rails/health#show", as: :rails_health_check

  # Articles route with summary generation methods
  resources :articles, only: [:index, :show] do
    # Existing scraped articles route
    get 'scraped/:id', to: 'articles#show_scraped', on: :collection, as: :scraped

    # Summary generation routes (member routes apply to individual articles)
    member do
      post 'generate_summary'
      post 'regenerate_summary'
    end
  end

  # Scraped feeds and articles routes
  resources :scraped_feeds do
    resources :scraped_articles, only: [:index] do
      # Add summary generation for scraped articles
      member do
        post 'generate_summary'
        post 'regenerate_summary'
      end
    end
  end

  # Root route
  root to: "pages#home"

  # Reports routes
  resources :reports, only: [:new, :create, :show] do
    post 'generate', on: :collection, as: :generate
  end
end
