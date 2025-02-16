class ArticlesController < ApplicationController
  def index
    @articles = Article.includes(:feed).order(published_at: :desc)

    # Detailed logging
    Rails.logger.info "Total articles: #{@articles.count}"
    @articles.each do |article|
      Rails.logger.info "Article: #{article.title}, Feed: #{article.feed&.name}, Published: #{article.published_at}"
    end
  end
end
