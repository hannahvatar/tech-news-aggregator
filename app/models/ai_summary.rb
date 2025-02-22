class AiSummary < ApplicationRecord
  belongs_to :article, optional: true
  belongs_to :scraped_article, optional: true

  validates :content, presence: true, length: { minimum: 10 }
  validate :must_belong_to_one_article_type

  after_create :log_summary_creation
  after_initialize :log_initialization, if: :verbose_logging?

  private

  def must_belong_to_one_article_type
    if article.blank? && scraped_article.blank?
      errors.add(:base, "Must belong to either an article or a scraped article")
    elsif article.present? && scraped_article.present?
      errors.add(:base, "Cannot belong to both an article and a scraped article")
    end
  end

  def log_summary_creation
    article_id = article&.id || scraped_article&.id
    Rails.logger.info "AiSummary created for #{article_type} ID: #{article_id}" if verbose_logging?
  end

  def log_initialization
    article_id = article&.id || scraped_article&.id
    Rails.logger.info "AiSummary initialized for #{article_type} ID: #{article_id}" if verbose_logging?
  end

  def article_type
    article.present? ? "Article" : "ScrapedArticle"
  end

  def verbose_logging?
    Rails.env.development? || Rails.env.test?
  end
end
