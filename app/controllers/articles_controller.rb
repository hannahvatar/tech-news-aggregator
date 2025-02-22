# app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  def index
    begin
      # Log start of method
      Rails.logger.info "ArticlesController#index - Starting article retrieval"

      # Fetch articles with error handling and logging
      @articles = fetch_articles
      @scraped_articles = fetch_scraped_articles

      # Log article counts and details about AI summaries
      log_article_counts_and_summaries

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

  def show
    @article = Article.includes(:feed, :ai_summary, :key_facts, :tags).find_by(id: params[:id]) ||
               ScrapedArticle.includes(:scraped_feed, :ai_summary).find_by(id: params[:id])

    if @article
      Rails.logger.debug "Article found: #{@article.id}"
      Rails.logger.debug "Article class: #{@article.class}"
      Rails.logger.debug "Feed info: #{@article.feed.inspect}" if @article.respond_to?(:feed)
    else
      flash[:alert] = "Article not found"
      redirect_to articles_path
    end
  end

  private

  def log_article_counts_and_summaries
    Rails.logger.info "Regular Articles Count: #{@articles.count}"
    Rails.logger.info "Scraped Articles Count: #{@scraped_articles.count}"

    # Log AI summary details for debugging
    @articles.each do |article|
      Rails.logger.info "Article #{article.id} AI Summary: #{article.ai_summary.present?}"
    end

    @scraped_articles.each do |article|
      Rails.logger.info "Scraped Article #{article.id} AI Summary: #{article.ai_summary.present?}"
    end
  end

  def fetch_articles
    # Default to a wide date range if no params are provided
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 1.year.ago
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today

    # Ensure correct order of dates
    start_date, end_date = end_date, start_date if start_date > end_date

    # Eager load all necessary associations
    Article.includes(:feed, :ai_summary, :key_facts)
           .references(:ai_summary)  # This ensures AI summaries are loaded
           .where(published_at: start_date.beginning_of_day..end_date.end_of_day)
           .order(published_at: :desc)
  rescue => e
    Rails.logger.error "Error fetching articles: #{e.message}"
    Article.none
  end

  def fetch_scraped_articles
    # Default to a wide date range if no params are provided
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 1.year.ago
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today

    # Ensure correct order of dates
    start_date, end_date = end_date, start_date if start_date > end_date

    # Eager load all necessary associations
    ScrapedArticle.includes(:scraped_feed, :ai_summary)
                  .references(:ai_summary)  # This ensures AI summaries are loaded
                  .where(published_at: start_date.beginning_of_day..end_date.end_of_day)
                  .order(published_at: :desc)
  rescue => e
    Rails.logger.error "Error fetching scraped articles: #{e.message}"
    ScrapedArticle.none
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
