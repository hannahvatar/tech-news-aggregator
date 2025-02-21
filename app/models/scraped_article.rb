class ScrapedArticle < ApplicationRecord
  belongs_to :scraped_feed
  belongs_to :article
  has_one :ai_summary
end
