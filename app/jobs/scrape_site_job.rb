# app/jobs/scrape_site_job.rb
class ScrapeSiteJob < ApplicationJob
  # Explicitly require the WebsiteScraper
  require 'services/website_scraper'

  queue_as :default

  def perform(scraped_feed_id)
    scraped_feed = ScrapedFeed.find(scraped_feed_id)

    # Initialize the scraper with the feed URL
    scraper = WebsiteScraper.new(scraped_feed.url)

    # Scrape articles
    articles = scraper.scrape

    # Iterate over the scraped articles
    articles.each do |article_data|
      # Extract summary directly or modify scraper to return summary
      summary = extract_summary(article_data[:content])

      # Create or find the article, and add summary
      ScrapedArticle.create_or_find_by!(
        scraped_feed: scraped_feed,
        title: article_data[:title],
        url: article_data[:url],
        published_at: article_data[:published_at] || Time.current,
        content: article_data[:content],  # Make sure you store the content if you need it
        summary: summary                  # Add the summary field here
      )
    end

    # Update last scraped time for the feed
    scraped_feed.update(last_scraped_at: Time.current)
  rescue StandardError => e
    Rails.logger.error("Scraping failed for #{scraped_feed.name}: #{e.message}")
  end

  private

  # A simple method to extract the first 150 characters for the summary
  def extract_summary(content)
    content.truncate(150)
  end
end
