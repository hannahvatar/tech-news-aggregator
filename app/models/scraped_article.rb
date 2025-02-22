# app/models/scraped_article.rb
class ScrapedArticle < ApplicationRecord
  belongs_to :scraped_feed
  belongs_to :article, optional: true
  has_one :ai_summary, dependent: :destroy

  validates :title, presence: true
  validates :url, presence: true, uniqueness: true
  validates :published_at, presence: true

  # Add source_name method for consistency with Article model
  def source_name
    scraped_feed&.name || "No source available"
  end
end
