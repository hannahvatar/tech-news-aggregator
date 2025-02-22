class FetchFeedArticlesJob < ApplicationJob
  queue_as :default

  def perform(feed_id = nil)
    # Log the received feed_id for debugging purposes
    Rails.logger.info "Received feed_id: #{feed_id}"

    # Ensure feed_id is passed, otherwise, fetch all feeds
    feeds = feed_id ? Feed.where(id: feed_id) : Feed.all

    feeds.each do |feed|
      begin
        # Log the name and URL of the feed for debugging
        Rails.logger.info "Processing feed: #{feed.name}, URL: #{feed.url}"

        # Parse the feed using Feedjira (ensure feed is valid)
        parsed_feed = Feedjira.parse(URI.open(feed.url))

        # Check if entries are found in the feed
        if parsed_feed.entries.empty?
          Rails.logger.info "No entries found for feed #{feed.name}"
          next
        end

        parsed_feed.entries.each do |entry|
          # Log the entry details to verify the feed content
          Rails.logger.info "Processing entry: #{entry.title}"

          # Check for uniqueness and create/update article
          article = Article.find_or_create_by!(
            title: entry.title,
            url: entry.url,
            published_at: entry.published || Time.current,
            feed: feed
          )

          # Check if AI summary exists; if not, generate one
          if article.ai_summary.nil?
            article.generate_ai_summary
            Rails.logger.info "Generated AI summary for article: #{entry.title}"
          end
        end

        # Update the last fetched time for the feed
        feed.update(last_fetched_at: Time.current)
        Rails.logger.info "Updated last_fetched_at for feed: #{feed.name}"

      rescue StandardError => e
        # Log errors with more context, including feed name and ID
        Rails.logger.error "Error fetching feed #{feed.name} (ID: #{feed.id}): #{e.message}"
      end
    end
  end
end
