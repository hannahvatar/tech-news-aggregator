require_relative "boot"

require "rails/all"

require 'dotenv/load' # Add this near the top of the file, after requiring 'rails'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TechNewsAggregator
  class Application < Rails::Application
    config.action_controller.raise_on_missing_callback_actions = false if Rails.version >= "7.1.0"

    config.generators do |generate|
      generate.assets false
      generate.helper false
      generate.test_framework :test_unit, fixture: false
    end

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Add custom lib directories to autoload paths
    config.autoload_lib(ignore: %w(assets tasks))

    # Enhanced logging configuration
    config.log_level = :debug
    config.log_tags = [ :request_id ]

    # Customize logger formatter for better readability
    config.log_formatter = proc do |severity, datetime, progname, msg|
      formatted_severity = sprintf("%-5s", severity)
      timestamp = datetime.strftime("%Y-%m-%d %H:%M:%S")
      "#{timestamp} [#{formatted_severity}] #{msg}\n"
    end

    # Configure Active Record query logging
    config.active_record.verbose_query_logs = true

    # Optional: Add custom error pages
    config.exceptions_app = self.routes

    # Optional: Configure time zone
    config.time_zone = 'Eastern Time (US & Canada)'

    # Optional: Ensure proper handling of JSON parsing
    config.active_support.json_encode_options = {
      # Example of custom JSON encoding options
      # mode: :compat  # Ensures compatibility with different JSON parsers
    }

    # Middleware for better error tracking (optional)
    config.middleware.use Rack::Attack if defined?(Rack::Attack)

    # Configuration for performance monitoring (if using)
    # config.middleware.use NewRelic::Rack::AgentHooks if defined?(NewRelic)

    # Ensure proper handling of JSON in controllers
    config.action_controller.permit_all_parameters = false
    config.active_job.queue_adapter = :sidekiq
  end
end
