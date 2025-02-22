# app/models/ai_summary.rb
class AiSummary < ApplicationRecord
  belongs_to :article
  belongs_to :scraped_article, optional: true

  # Validations
  validates :content, presence: true, length: { minimum: 10 }

  # Optional logging, make it conditional to avoid unnecessary log noise
  after_create :log_summary_creation
  after_initialize :log_initialization, if: :verbose_logging?

  private

  def log_summary_creation
    Rails.logger.info "AiSummary created for Article ID: #{article_id}" if verbose_logging?
  end

  def log_initialization
    Rails.logger.info "AiSummary initialized for Article ID: #{article_id}" if verbose_logging?
  end

  # Optional method to control logging verbosity
  def verbose_logging?
    Rails.env.development? || Rails.env.test?
  end
end
