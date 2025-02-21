class ArticlesController < ApplicationController
  def index
    # Log the incoming filter parameters
    log_filter_params

    # Prepare base queries with eager loading, including AI summaries for both articles and scraped articles
    @articles = Article.includes(:feed, :ai_summary, :key_facts)
    @scraped_articles = ScrapedArticle.includes(:scraped_feed, :ai_summary)

    # Apply date filtering if the parameters are present
    apply_date_filter if date_params_present?

    # Log counts after applying filters
    log_filtered_counts

    # Order articles and scraped articles by published date
    @articles = @articles.order(published_at: :desc)
    @scraped_articles = @scraped_articles.order(published_at: :desc)

    # Combine both article collections and sort by published date
    @combined_articles = @articles.to_a.concat(@scraped_articles.to_a)

    # Paginate the combined articles before sorting to ensure pagination works as expected
    paginate_articles

    # Sort the paginated articles by published date in descending order
    @combined_articles.sort_by!(&:published_at).reverse!

    # Set the total count for display in the view
    @total_articles_count = @combined_articles.total_count
  end

  private

  def log_filter_params
    Rails.logger.info "=== Article Filter Debug ==="
    Rails.logger.info "Start Date Param: #{params[:start_date]}"
    Rails.logger.info "End Date Param: #{params[:end_date]}"
  end

  def date_params_present?
    params[:start_date].present? && params[:end_date].present?
  end

  def apply_date_filter
    start_date = Date.parse(params[:start_date]).beginning_of_day
    end_date = Date.parse(params[:end_date]).end_of_day
    Rails.logger.info "Parsed Start Date: #{start_date}"
    Rails.logger.info "Parsed End Date: #{end_date}"

    @articles = @articles.where(published_at: start_date..end_date)
    @scraped_articles = @scraped_articles.where(published_at: start_date..end_date)
  end

  def log_filtered_counts
    Rails.logger.info "Total Articles After Filter: #{@articles.count}"
    Rails.logger.info "Total Scraped Articles After Filter: #{@scraped_articles.count}"

    # Log feed information for each scraped article if present
    @scraped_articles.each do |scraped_article|
      if scraped_article.scraped_feed
        Rails.logger.info "Scraped Article Feed: #{scraped_article.scraped_feed.name}"
      else
        Rails.logger.info "Scraped Article has no associated feed"
      end
    end
  end

  def paginate_articles
    # Make sure to paginate before sorting so that pagination works correctly
    @combined_articles = Kaminari.paginate_array(@combined_articles).page(params[:page]).per(20)
  end
end
