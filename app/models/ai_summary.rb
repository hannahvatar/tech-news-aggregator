class AiSummary < ApplicationRecord
  belongs_to :scraped_article  # Update this line to match the correct association

  # Validations
  validates :scraped_article_id, presence: true, uniqueness: true
  validates :content, presence: true, length: { minimum: 10 }

  # Optional: Add some callbacks for logging
  after_create :log_summary_creation
  after_initialize :log_initialization

  private

  def log_summary_creation
    Rails.logger.info "AiSummary created for ScrapedArticle ID: #{scraped_article_id}"
  end

  def log_initialization
    Rails.logger.info "AiSummary initialized for ScrapedArticle ID: #{scraped_article_id}"
  end
end
