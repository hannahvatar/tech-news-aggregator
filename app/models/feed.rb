require 'feedjira'
require 'httparty'

class Feed < ApplicationRecord
  # Associations
  has_many :articles, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :url, presence: true,
                  uniqueness: true,
                  format: {
                    with: URI::regexp(%w(http https)),
                    message: "must be a valid URL"
                  }

  # Logging method to track feed fetch attempts
  def log_feed_activity(message, level: :info)
    Rails.logger.public_send(level, "[Feed ##{id}] #{name}: #{message}")
  end

  def fetch_and_save_articles
    log_feed_activity("Starting article fetch")

    begin
      # Fetch feed with timeout and error handling
      response = HTTParty.get(url,
        timeout: 10,  # 10 second timeout
        headers: {
          'User-Agent' => 'TechNewsAggregator/1.0',
          'Accept' => 'application/rss+xml, application/atom+xml'
        }
      )

      # Validate response
      unless response.success?
        log_feed_activity("Failed to fetch feed. HTTP Status: #{response.code}", level: :error)
        return []
      end

      # Parse feed
      feed = Feedjira.parse(response.body)
      log_feed_activity("Found #{feed.entries.count} entries")

      # Create articles with deduplication
      new_articles = feed.entries.map do |entry|
        create_unique_article(entry)
      end.compact

      log_feed_activity("Saved #{new_articles.count} new articles")
      new_articles
    rescue SocketError => e
      log_feed_activity("Network error: #{e.message}", level: :error)
      []
    rescue Feedjira::NoParserAvailable => e
      log_feed_activity("Parsing error: Unsupported feed format", level: :error)
      []
    rescue => e
      log_feed_activity("Unexpected error: #{e.message}", level: :error)
      []
    end
  end

  private

  def create_unique_article(entry)
    # Use existing article if already present
    existing_article = articles.find_by(
      guid: entry.id || entry.url,
      url: entry.url
    )

    return nil if existing_article

    # Create new article
    articles.create!(
      title: sanitize_text(entry.title),
      url: entry.url,
      published_at: entry.published || Time.current,
      content: sanitize_text(entry.content || entry.summary),
      guid: entry.id || entry.url
    )
  rescue ActiveRecord::RecordInvalid => e
    log_feed_activity("Failed to create article: #{e.message}", level: :warn)
    nil
  end

  # Basic text sanitization to prevent potential XSS or encoding issues
  def sanitize_text(text)
    return '' if text.nil?
    text.to_s.truncate(1000).strip
  end
end
