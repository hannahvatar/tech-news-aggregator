# config/initializers/sidekiq.rb
require 'sidekiq'

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }

  # Optional: Configure Sidekiq logging
  config.logger.level = Rails.env.production? ? Logger::INFO : Logger::DEBUG
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }
end

# Optional: Configure Sidekiq middleware
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    # Add custom middleware here if needed
  end
end
