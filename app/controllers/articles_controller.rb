class ArticlesController < ApplicationController
  def index
    Rails.logger.info "=== Article Filter Debug ==="
    Rails.logger.info "Start Date Param: #{params[:start_date]}"
    Rails.logger.info "End Date Param: #{params[:end_date]}"

    # Prepare base queries with eager loading
    @articles = Article.includes(:feed, :ai_summary, :key_facts)
    @scraped_articles = ScrapedArticle.includes(:scraped_feed)

    # Filter by date if params exist
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date]).beginning_of_day
      end_date = Date.parse(params[:end_date]).end_of_day

      Rails.logger.info "Parsed Start Date: #{start_date}"
      Rails.logger.info "Parsed End Date: #{end_date}"

      # Apply date filtering to both article types
      @articles = @articles.where(published_at: start_date..end_date)
      @scraped_articles = @scraped_articles.where(published_at: start_date..end_date)

      # Log the SQL queries
      Rails.logger.info "Articles SQL Query: #{@articles.to_sql}"
      Rails.logger.info "Scraped Articles SQL Query: #{@scraped_articles.to_sql}"
    end

    # Order both article types by published date
    @articles = @articles.order(published_at: :desc)
    @scraped_articles = @scraped_articles.order(published_at: :desc)

    # Debug logging for Articles
    Rails.logger.info "Total articles found: #{@articles.count}"
    Rails.logger.info "Date range of articles:"
    Rails.logger.info "Earliest article: #{@articles.minimum(:published_at)}"
    Rails.logger.info "Latest article: #{@articles.maximum(:published_at)}"

    # Debug logging for Scraped Articles
    Rails.logger.info "Total scraped articles found: #{@scraped_articles.count}"
    Rails.logger.info "Date range of scraped articles:"
    Rails.logger.info "Earliest scraped article: #{@scraped_articles.minimum(:published_at)}"
    Rails.logger.info "Latest scraped article: #{@scraped_articles.maximum(:published_at)}"

    # Sample of articles
    Rails.logger.info "Sample Articles:"
    @articles.limit(5).each do |article|
      Rails.logger.info "Article - Title: #{article.title}, Published: #{article.published_at}"
    end

    # Sample of scraped articles
    Rails.logger.info "Sample Scraped Articles:"
    @scraped_articles.limit(5).each do |scraped_article|
      Rails.logger.info "Scraped Article - Title: #{scraped_article.title}, Published: #{scraped_article.published_at}"
    end
  end
end
