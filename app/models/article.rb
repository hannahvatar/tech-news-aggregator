# app/models/article.rb
class Article < ApplicationRecord
  belongs_to :feed
  has_one :ai_summary, dependent: :destroy
  has_many :key_facts, dependent: :destroy
  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  has_many :scraped_articles, dependent: :destroy  # Optional, depending on your relationship

  validates :title, presence: true
  validates :url, presence: true, uniqueness: true
  validates :guid, presence: true, uniqueness: true
  validates :published_at, presence: true

  # Optional: add database indexes for speed and consistency
  # add_index :articles, :url, unique: true
  # add_index :articles, :guid, unique: true
end

# app/models/ai_summary.rb
class AiSummary < ApplicationRecord
  belongs_to :article

  validates :content, presence: true
end
