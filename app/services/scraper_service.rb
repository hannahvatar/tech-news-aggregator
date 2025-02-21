# app/services/scraper_service.rb
require 'nokogiri'
require 'httparty'

class ScraperService
  def initialize(feed)
    @feed = feed
  end

  def scrape
    case @feed.name
    when 'Smashing Magazine UX'
      scrape_smashing_magazine
    when 'A List Apart'
      scrape_alistapart
    when 'UsabilityGeek'
      scrape_usabilitygeek
    when 'UX Matters'
      scrape_uxmatters
    when 'Prototypr'
      scrape_prototypr
    when 'Boxes and Arrows'
      scrape_boxes_and_arrows
    end

    @feed.update(last_scraped_at: Time.current)
  end

  private

  def fetch_page(url)
    response = HTTParty.get(url)
    Nokogiri::HTML(response.body)
  rescue => e
    Rails.logger.error "Error fetching #{url}: #{e.message}"
    nil
  end

  def scrape_smashing_magazine
    doc = fetch_page(@feed.url)
    return unless doc

    doc.css('article.article--post').each do |article|
      # Extract title and URL
      title = article.css('h2.article--post__title').text.strip
      relative_url = article.css('h2.article--post__title a').attr('href')&.value
      absolute_url = "https://www.smashingmagazine.com#{relative_url}"

      # Get content
      content = article.css('.article--post__teaser').text.strip

      # Parse the published date from datetime attribute
      datetime = article.css('time').attr('datetime')&.value
      published_at = if datetime
        # Convert YYYY-MM-DD format to DateTime
        Date.parse(datetime).beginning_of_day
      else
        # Extract from URL as fallback (format: /YYYY/MM/...)
        match = relative_url.match(%r{/(\d{4})/(\d{2})})
        match ? Date.new(match[1].to_i, match[2].to_i, 1).beginning_of_day : Time.current
      end

      # Debug output
      Rails.logger.info "Creating article: #{title}"
      Rails.logger.info "Published at: #{published_at}"

      create_article(
        title: title,
        url: absolute_url,
        content: content,
        published_at: published_at
      )
    end
  end

  def create_article(data)
    ScrapedArticle.create!(
      scraped_feed: @feed,
      title: data[:title],
      url: data[:url],
      content: data[:content],
      published_at: data[:published_at]
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create article: #{e.message} for #{data[:url]}"
    Rails.logger.error "Data: #{data.inspect}"
  end

# app/services/scraper_service.rb

def scrape_alistapart
  doc = fetch_page(@feed.url)
  return unless doc

  doc.css('div.grid-card-3').each do |article|
    title = article.css('h3').text.strip
    relative_url = article.css('a').first.attr('href')
    url = relative_url.start_with?('http') ? relative_url : "https://alistapart.com#{relative_url}"
    content = article.css('p.article-summary').text.strip
    date = article.css('time').attr('datetime')&.value

    create_article(
      title: title,
      url: url,
      content: content,
      published_at: date ? Date.parse(date) : nil
    )
  end
end


def scrape_usabilitygeek
  doc = fetch_page(@feed.url)
  return unless doc

  doc.css('article.blog-item').each do |article|
    title = article.css('h2.blog-title').text.strip
    url = article.css('h2.blog-title a').attr('href')&.value
    content = article.css('div.blog-excerpt').text.strip
    date = article.css('.blog-date').text.strip

    create_article(
      title: title,
      url: url,
      content: content,
      published_at: date.present? ? Date.parse(date) : nil
    )
  end
end

def scrape_uxmatters
  doc = fetch_page(@feed.url)
  return unless doc

  doc.css('div.entry').each do |article|
    title = article.css('h3 a').text.strip
    relative_url = article.css('h3 a').attr('href')&.value
    url = relative_url.start_with?('http') ? relative_url : "https://www.uxmatters.com#{relative_url}"
    content = article.css('p').first&.text&.strip
    date = article.css('.date').text.strip

    create_article(
      title: title,
      url: url,
      content: content,
      published_at: date.present? ? Date.parse(date) : nil
    )
  end
end


def scrape_prototypr
  doc = fetch_page(@feed.url)
  return unless doc

  doc.css('article.post-preview').each do |article|
    title = article.css('h2.title').text.strip
    url = article.css('a.post-link').attr('href')&.value
    content = article.css('p.description').text.strip
    date = article.css('time').attr('datetime')&.value

    create_article(
      title: title,
      url: url,
      content: content,
      published_at: date ? Date.parse(date) : nil
    )
  end
end

def scrape_boxes_and_arrows
  doc = fetch_page(@feed.url)
  return unless doc

  doc.css('article.post').each do |article|
    title = article.css('h2.entry-title a').text.strip
    url = article.css('h2.entry-title a').attr('href')&.value
    content = article.css('div.entry-content p').first&.text&.strip
    date = article.css('time.entry-date').attr('datetime')&.value

    create_article(
      title: title,
      url: url,
      content: content,
      published_at: date ? Date.parse(date) : nil
    )
  rescue => e
    Rails.logger.error "Error scraping Boxes and Arrows article: #{e.message}"
  end
end
end
