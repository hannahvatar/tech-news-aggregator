class ArticlesController < ApplicationController
  def index
    Rails.logger.info "=== Article Filter Debug ==="
    Rails.logger.info "Start Date Param: #{params[:start_date]}"
    Rails.logger.info "End Date Param: #{params[:end_date]}"

    @articles = Article.includes(:feed, :ai_summary, :key_facts)

    # Filter by date if params exist
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date]).beginning_of_day
      end_date = Date.parse(params[:end_date]).end_of_day

      Rails.logger.info "Parsed Start Date: #{start_date}"
      Rails.logger.info "Parsed End Date: #{end_date}"

      @articles = @articles.where(published_at: start_date..end_date)

      # Log the SQL query
      Rails.logger.info "SQL Query: #{@articles.to_sql}"
    end

    @articles = @articles.order(published_at: :desc)

    # Debug logging
    Rails.logger.info "Total articles found: #{@articles.count}"
    Rails.logger.info "Date range of articles:"
    Rails.logger.info "Earliest article: #{@articles.minimum(:published_at)}"
    Rails.logger.info "Latest article: #{@articles.maximum(:published_at)}"

    # Sample of articles
    @articles.limit(5).each do |article|
      Rails.logger.info "Sample Article - Title: #{article.title}, Published: #{article.published_at}"
    end
  end
end
