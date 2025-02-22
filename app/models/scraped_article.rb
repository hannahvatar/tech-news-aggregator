class ScrapedArticle < ApplicationRecord
  belongs_to :scraped_feed
  has_one :ai_summary, dependent: :destroy

  validates :title, presence: true
  validates :url, presence: true, uniqueness: true
  validates :published_at, presence: true

  def source_name
    return "No scraped feed ID" unless scraped_feed_id
    return "No scraped feed found" unless scraped_feed
    return "No scraped feed name" unless scraped_feed.name
    scraped_feed.name
  end
end
