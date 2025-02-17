# app/services/feed_fetcher_service.rb
class FeedFetcherService
  def initialize
    # Initialize any necessary API clients or configurations here
  end

  def fetch_articles(start_date:, end_date:)
    Rails.logger.info "Fetching articles between #{start_date} and #{end_date}"

    # Convert dates to proper format if they're strings
    start_date = Date.parse(start_date) if start_date.is_a?(String)
    end_date = Date.parse(end_date) if end_date.is_a?(String)

    # Fetch articles from your database or API
    Article.where(published_at: start_date.beginning_of_day..end_date.end_of_day)
          .order(published_at: :desc)
  rescue StandardError => e
    Rails.logger.error "Error fetching articles: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    []
  end
end
