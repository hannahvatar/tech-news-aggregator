class ArticlesController < ApplicationController
  def index
    Rails.logger.info "=== Article Filter Debug ==="
    Rails.logger.info "Start Date Param: #{params[:start_date]}"
    Rails.logger.info "End Date Param: #{params[:end_date]}"

    # Prepare base queries with eager loading
    @articles = Article.includes(:feed, :ai_summary, :key_facts)
    @scraped_articles = ScrapedArticle.includes(:scraped_feed, :article) # Ensure :article is included

    # Filter by date if params exist
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date]).beginning_of_day
      end_date = Date.parse(params[:end_date]).end_of_day

      Rails.logger.info "Parsed Start Date: #{start_date}"
      Rails.logger.info "Parsed End Date: #{end_date}"

      # Apply date filtering to both article types
      @articles = @articles.where(published_at: start_date..end_date)
      @scraped_articles = @scraped_articles.where(published_at: start_date..end_date)
    end

    # Order both article types by published date
    @articles = @articles.order(published_at: :desc)
    @scraped_articles = @scraped_articles.order(published_at: :desc)

    # Combine articles
    @combined_articles = (@articles + @scraped_articles)
      .sort_by(&:published_at)
      .reverse

    # Paginate combined articles
    @combined_articles = Kaminari.paginate_array(@combined_articles).page(params[:page]).per(20)
  end

  def show
    @article = Article.includes(:ai_summary, :feed, :key_facts)
                      .find_by(id: params[:id]) ||
               ScrapedArticle.includes(:scraped_feed, :article) # Ensure :article is included for ScrapedArticle

    raise ActiveRecord::RecordNotFound if @article.nil?

    # Debugging logs
    Rails.logger.info "=== Debugging Article Show Controller ==="
    Rails.logger.info "Article ID: #{@article.id}"
    Rails.logger.info "Article Type: #{@article.class}"
    Rails.logger.info "AI Summary Association Loaded?: #{@article.association(:ai_summary).loaded?}"
    Rails.logger.info "AI Summary Object: #{@article.ai_summary.inspect}"
    Rails.logger.info "AI Summary Content: #{@article.ai_summary&.content}"

    # Assign AI Summary content to an instance variable for the view
    @summary_content = @article.ai_summary&.content || "No AI summary available."

    # If it's a ScrapedArticle, we need to fetch the associated Article's AI summary
    if @article.is_a?(ScrapedArticle)
      @summary_content = @article.article&.ai_summary&.content || "No AI summary available for associated article."
    end
  end
end
