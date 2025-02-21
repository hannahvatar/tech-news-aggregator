# app/models/article.rb
class Article < ApplicationRecord
  belongs_to :feed
  has_one :ai_summary, dependent: :destroy
  has_many :key_facts, dependent: :destroy
  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags

  validates :title, presence: true
  validates :url, presence: true, uniqueness: true
  validates :guid, presence: true, uniqueness: true
  validates :published_at, presence: true

  # Compatibility method for combined view
  def source_name
    feed.name
  end
end

# app/models/scraped_article.rb
class ScrapedArticle < ApplicationRecord
  belongs_to :scraped_feed
  has_one :ai_summary, dependent: :destroy

  validates :title, presence: true
  validates :url, presence: true, uniqueness: true
  validates :published_at, presence: true

  # Compatibility method for combined view
  def source_name
    scraped_feed.name
  end
end
