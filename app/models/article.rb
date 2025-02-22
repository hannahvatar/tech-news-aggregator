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

  # Scopes for convenience
  scope :without_ai_summary, -> { left_joins(:ai_summary).where(ai_summaries: { id: nil }) }
  scope :with_ai_summary, -> { joins(:ai_summary) }

  # Method to return source name (feed's name or default text)
  def source_name
    feed&.name || "No source available"
  end

  # Check if AI summary exists
  def ai_summary_generated?
    ai_summary.present?
  end

  # Method to generate AI summary if not exists
  def generate_ai_summary
    return ai_summary if ai_summary_generated?

    summary_service = AiSummaryService.new(self)
    create_ai_summary(
      content: summary_service.generate_summary,
      generated_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.error "Failed to generate AI summary for Article #{id}: #{e.message}"
    nil
  end
end
