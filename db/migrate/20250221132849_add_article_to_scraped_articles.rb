class AddArticleToScrapedArticles < ActiveRecord::Migration[7.1]
  def change
    add_reference :scraped_articles, :article, foreign_key: true, null: true
  end
end
