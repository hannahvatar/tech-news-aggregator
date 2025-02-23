require 'httparty'

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

        # Use HTTParty to fetch the feed content
        response = HTTParty.get(feed.url)
        parsed_feed = Feedjira.parse(response.body)

        # Check if entries are found in the feed
        if parsed_feed.entries.empty?
          Rails.logger.info "No entries found for feed #{feed.name}"
          next
        end

        parsed_feed.entries.each do |entry|
          Rails.logger.info "Processing entry: #{entry.title}"

          # Check for uniqueness and create/update article
          article = Article.find_or_create_by!(
            title: entry.title,
            url: entry.url,
            published_at: entry.published || Time.current,
            feed: feed
          )

          # Save the content of the article
          article.update(content: entry.content || entry.summary)

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
        Rails.logger.error e.backtrace.join("\n")  # Add this line to get more detailed error information
      end
    end
  end
end
