# app/models/report.rb
class Report < ApplicationRecord
  # Validations
  validates :report_type, presence: true
  validates :detail_level, presence: true
  validates :data, presence: true

  # Enums for standardizing report types and detail levels
  enum report_type: {
    executive: 'executive',
    detailed: 'detailed',
    summary: 'summary'
  }

  enum detail_level: {
    low: 'low',
    medium: 'medium',
    high: 'high'
  }

  # Parse data with more robust error handling
  def parsed_data
    JSON.parse(data, symbolize_names: true)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse report data: #{e.message}"
    {}
  rescue StandardError => e
    Rails.logger.error "Unexpected error parsing report data: #{e.message}"
    {}
  end

  # Extract specific sections of the report
  def executive_summary
    parsed_data.dig(:data, :executive_summary)
  end

  def key_trends
    parsed_data.dig(:data, :key_trends)
  end

  def recommendations
    parsed_data.dig(:data, :recommendations)
  end

  # Scopes for filtering reports
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(report_type: type) }
  scope :by_detail_level, ->(level) { where(detail_level: level) }

  # Method to check if report data is valid
  def valid_data?
    parsed_data.present? &&
    parsed_data.dig(:data, :executive_summary).present? &&
    parsed_data.dig(:data, :key_trends).present?
  rescue
    false
  end

  # Generate a human-readable title
  def title
    "#{report_type.titleize} Report - #{created_at.strftime('%B %d, %Y')}"
  end

  # Class method to cleanup old reports
  def self.cleanup_old_reports(days = 30)
    where('created_at < ?', days.days.ago).destroy_all
  end
end
