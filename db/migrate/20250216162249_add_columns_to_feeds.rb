class AddColumnsToFeeds < ActiveRecord::Migration[7.1]
  def change
    add_column :feeds, :name, :string
    add_column :feeds, :url, :string
    add_column :feeds, :feed_type, :string
    add_column :feeds, :last_fetched_at, :datetime

    add_index :feeds, :url, unique: true
  end
end
