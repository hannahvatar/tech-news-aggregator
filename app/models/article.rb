class Article < ApplicationRecord
  belongs_to :feed
  has_one :ai_summary, dependent: :destroy
  has_many :key_facts
  has_many :article_tags
  has_many :tags, through: :article_tags
  has_many :scraped_articles

  validates :title, presence: true
  validates :url, presence: true, uniqueness: true
  validates :guid, presence: true, uniqueness: true
  validates :published_at, presence: true
end


# app/models/ai_summary.rb
class AiSummary < ApplicationRecord
  belongs_to :article

  validates :content, presence: true
end
