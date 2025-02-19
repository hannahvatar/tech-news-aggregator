# app/models/report.rb
class Report < ApplicationRecord
  # Validations
  validates :start_date, presence: true
  validates :end_date, presence: true

  # Custom serialization method
  def self.serialize_data(data)
    # If it's already a hash, return it
    return data if data.is_a?(Hash)

    # If it's a string, create a structured hash
    {
      original_content: data,
      metadata: {
        status: 'legacy',
        import_note: 'Data could not be parsed automatically',
        date_range: 'Not specified',
        article_count: 3  # Default to 3 articles
      },
      analysis: data.to_s
    }
  end

  # Override the data methods to handle serialization
  def data
    # Read the raw data from the database
    raw_data = read_attribute(:data)

    # If raw_data is nil or already a hash, return it
    return raw_data if raw_data.nil? || raw_data.is_a?(Hash)

    # If it's a string, attempt to parse or create a structured hash
    begin
      parsed_data = JSON.parse(raw_data)
      return parsed_data if parsed_data.is_a?(Hash)
    rescue JSON::ParserError
      # If parsing fails, create a structured hash
      return self.class.serialize_data(raw_data)
    end

    # Fallback to an empty hash
    {}
  end

  def data=(new_data)
    # Normalize the data before saving
    write_attribute(:data, self.class.serialize_data(new_data))
  end

  # Metadata accessor with default values
  def metadata
    # Ensure we have a default metadata structure
    default_metadata = {
      status: 'completed',
      date_range: (start_date.present? && end_date.present?) ? "#{start_date} - #{end_date}" : 'Not specified',
      article_count: 3,
      articles: [],
      generated_at: created_at
    }

    # Try to retrieve stored metadata
    stored_metadata = data.is_a?(Hash) ? data[:metadata] || {} : {}

    # Merge stored metadata with defaults, giving priority to stored values
    result = default_metadata.merge(stored_metadata.symbolize_keys)

    # Ensure article count is accurate
    result[:article_count] = result[:articles]&.length || 3

    result
  end

  # Analysis accessor with fallback
  def analysis
    data.fetch('analysis', data.fetch(:analysis, 'No analysis available'))
  end

  # Rest of the model remains the same...
end
