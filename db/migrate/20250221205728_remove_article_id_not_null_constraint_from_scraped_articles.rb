class RemoveArticleIdNotNullConstraintFromScrapedArticles < ActiveRecord::Migration[7.1]
  def change
    # First remove the foreign key
    remove_foreign_key :scraped_articles, :articles

    # Make article_id nullable
    change_column_null :scraped_articles, :article_id, true

    # Add back the foreign key but allow null
    add_foreign_key :scraped_articles, :articles, null: true
  end
end
