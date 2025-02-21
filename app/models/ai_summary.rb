class AiSummary < ApplicationRecord
  belongs_to :summarizable, polymorphic: true  # Polymorphic association

  # Validations
  validates :content, presence: true, length: { minimum: 10 }

  # Optional: Add some callbacks for logging
  after_create :log_summary_creation
  after_initialize :log_initialization

  private

  def log_summary_creation
    Rails.logger.info "AiSummary created for #{summarizable_type} ID: #{summarizable_id}"
  end

  def log_initialization
    Rails.logger.info "AiSummary initialized for #{summarizable_type} ID: #{summarizable_id}"
  end
end
