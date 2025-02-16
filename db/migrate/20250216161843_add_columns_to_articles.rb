class AddColumnsToArticles < ActiveRecord::Migration[7.1]
  def change
    add_reference :articles, :feed, null: false, foreign_key: true
    add_column :articles, :title, :string
    add_column :articles, :url, :string
    add_column :articles, :published_at, :datetime
    add_column :articles, :content, :text
    add_column :articles, :author, :string
    add_column :articles, :guid, :string
    add_index :articles, :guid, unique: true
  end
end
