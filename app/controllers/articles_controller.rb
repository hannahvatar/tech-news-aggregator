class ArticlesController < ApplicationController
  def index
    begin
      # Log start of method
      Rails.logger.info "ArticlesController#index - Starting article retrieval"

      # Fetch articles with error handling and logging
      @articles = fetch_articles
      @scraped_articles = fetch_scraped_articles

      # Log article counts
      log_article_counts

      # Combine and paginate articles
      @combined_articles = combine_articles
      paginate_articles

      # Additional error logging if no articles found
      if @combined_articles.empty?
        Rails.logger.warn "ArticlesController#index - No articles found"
      end

    rescue StandardError => e
      # Comprehensive error logging
      Rails.logger.error "ArticlesController#index - Error retrieving articles: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Set empty collections to prevent nil errors
      @articles = Article.none
      @scraped_articles = ScrapedArticle.none
      @combined_articles = []
    end
  end

  private

  def fetch_articles
    Article.includes(:feed, :ai_summary, :key_facts)
           .order(published_at: :desc)
  rescue => e
    Rails.logger.error "Error fetching articles: #{e.message}"
    Article.none
  end

  def fetch_scraped_articles
    ScrapedArticle.includes(:scraped_feed, :ai_summary)
                  .order(published_at: :desc)
  rescue => e
    Rails.logger.error "Error fetching scraped articles: #{e.message}"
    ScrapedArticle.none
  end

  def log_article_counts
    Rails.logger.info "Regular Articles Count: #{@articles.count}"
    Rails.logger.info "Scraped Articles Count: #{@scraped_articles.count}"
  end

  def combine_articles
    articles = @articles.to_a + @scraped_articles.to_a
    articles.sort_by! { |a| a.published_at || Time.now }.reverse!
  rescue => e
    Rails.logger.error "Error combining articles: #{e.message}"
    []
  end

  def paginate_articles
    @combined_articles = Kaminari.paginate_array(@combined_articles)
                                  .page(params[:page])
                                  .per(20)
  rescue => e
    Rails.logger.error "Pagination error: #{e.message}"
    @combined_articles = []
  end
end
