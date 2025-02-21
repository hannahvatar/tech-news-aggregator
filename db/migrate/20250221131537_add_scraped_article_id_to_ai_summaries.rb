class AddScrapedArticleIdToAiSummaries < ActiveRecord::Migration[7.1]
  def change
    add_reference :ai_summaries, :scraped_article, null: true, foreign_key: true
  end
end
