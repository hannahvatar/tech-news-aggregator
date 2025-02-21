class CreateScrapedFeeds < ActiveRecord::Migration[7.1]
  def change
    create_table :scraped_feeds do |t|
      t.string :name
      t.string :url
      t.string :feed_type
      t.datetime :last_scraped_at

      t.timestamps
    end
  end
end
