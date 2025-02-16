require 'httparty'
require 'feedjira'

class FeedFetcherService
  def self.fetch_all
    Feed.find_each do |feed|
      new(feed).fetch
    end
  end

  def initialize(feed)
    @feed = feed
  end

  def fetch
    response = HTTParty.get(@feed.url)
    return unless response.success?

    parsed_feed = Feedjira.parse(response.body)
    save_articles(parsed_feed.entries)
    @feed.update(last_fetched_at: Time.current)
  rescue StandardError => e
    Rails.logger.error("Error fetching feed #{@feed.name}: #{e.message}")
  end

  private

  def save_articles(entries)
    entries.each do |entry|
      article = @feed.articles.find_or_initialize_by(guid: entry.entry_id || entry.url)

      article.assign_attributes(
        title: entry.title,
        url: entry.url,
        content: entry.content || entry.summary,
        author: entry.author,
        published_at: entry.published || Time.current
      )

      article.save if article.changed?
    end
  end
end
