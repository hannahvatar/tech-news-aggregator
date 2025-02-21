class ChangeArticleIdToNotNull < ActiveRecord::Migration[7.1]
  def change
    change_column_null :scraped_articles, :article_id, false
  end
end
