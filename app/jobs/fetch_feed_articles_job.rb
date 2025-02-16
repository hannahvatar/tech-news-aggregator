# app/jobs/fetch_feed_articles_job.rb
class FetchFeedArticlesJob < ApplicationJob
  queue_as :default

  def perform(feed_id = nil)
    feeds = feed_id ? Feed.where(id: feed_id) : Feed.all

    feeds.each do |feed|
      begin
        # Use a gem like feedjira to parse RSS feeds
        parsed_feed = Feedjira.parse(URI.open(feed.url))

        parsed_feed.entries.each do |entry|
          # Create a new article if it doesn't already exist
          Article.find_or_create_by!(
            title: entry.title,
            url: entry.url,
            published_at: entry.published || Time.current,
            feed: feed
          )
        end

        # Update the last fetched time
        feed.update(last_fetched_at: Time.current)
      rescue StandardError => e
        Rails.logger.error "Error fetching feed #{feed.name}: #{e.message}"
      end
    end
  end
end
