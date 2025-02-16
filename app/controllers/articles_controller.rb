class ArticlesController < ApplicationController
  def index
    @articles = Article.includes(:feed).order(published_at: :desc)
  end

  def show
    @article = Article.find(params[:id])
  end
end
