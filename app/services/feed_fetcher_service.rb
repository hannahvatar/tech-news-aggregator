# app/services/feed_fetcher_service.rb
class FeedFetcherService
  def initialize(feed_id)
    @feed_id = feed_id
  end

  def fetch_articles(start_date:, end_date:)
    Rails.logger.info "Fetching articles for Feed #{@feed_id} between #{start_date} and #{end_date}"

    # Convert dates to proper format if they're strings
    start_date = Date.parse(start_date) if start_date.is_a?(String)
    end_date = Date.parse(end_date) if end_date.is_a?(String)

    # Fetch articles from the database for the specific feed ID and date range
    articles = Article.where(feed_id: @feed_id, published_at: start_date.beginning_of_day..end_date.end_of_day)
                       .order(published_at: :desc)

    # Generate and save summaries for each article
    articles.each do |article|
      summary = generate_summary(article)
      article.update(summary: summary) if article.summary.nil? || article.summary.empty?
    end

    articles
  rescue StandardError => e
    Rails.logger.error "Error fetching articles: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    []
  end

  private

  # Implement the summary generation logic here
  def generate_summary(article)
    # Example: A simple summary based on article body (you can customize this logic)
    if article.body.present?
      article.body.truncate(200)  # Truncates body to 200 characters as a summary
    else
      "No summary available for #{article.title}" # Fallback if no body
    end
  end
end
