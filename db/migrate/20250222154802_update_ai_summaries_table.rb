class UpdateAiSummariesTable < ActiveRecord::Migration[7.1]
  def change
    change_column_null :ai_summaries, :article_id, true
    add_index :ai_summaries, [:article_id, :scraped_article_id], unique: true
    add_check_constraint :ai_summaries, "(article_id IS NOT NULL) OR (scraped_article_id IS NOT NULL)", name: "check_article_or_scraped_article_presence"
  end
end
