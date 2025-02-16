class ArticlesController < ApplicationController
  def index
    @articles = Article.includes(:feed, :ai_summary, :key_facts).order(published_at: :desc)

    # Filter by date if params exist
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date]).beginning_of_day
      end_date = Date.parse(params[:end_date]).end_of_day
      @articles = @articles.where(published_at: start_date..end_date)
    end

    # Debug logging
    Rails.logger.info "Total articles: #{@articles.count}"
    @articles.each do |article|
      Rails.logger.info "Article: #{article.title}, Feed: #{article.feed&.name}, Published: #{article.published_at}, AI Summary: #{article.ai_summary&.content}"
    end
  end
end
