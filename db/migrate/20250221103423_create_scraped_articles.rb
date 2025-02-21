class CreateScrapedArticles < ActiveRecord::Migration[7.1]
  def change
    create_table :scraped_articles do |t|
      t.string :title
      t.string :url
      t.text :content
      t.datetime :published_at
      t.references :scraped_feed, foreign_key: true

      # For uniqueness validation
      t.index :url, unique: true

      t.timestamps
    end
  end
end
