class AddSummaryToScrapedArticles < ActiveRecord::Migration[7.1]
  def change
    add_column :scraped_articles, :summary, :text
  end
end
