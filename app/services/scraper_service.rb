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
    puts "\nAttempting to fetch: #{url}"
    response = HTTParty.get(url)
    puts "Response status: #{response.code}"
    puts "Response body length: #{response.body.length} characters"

    doc = Nokogiri::HTML(response.body)
    puts "Page title: #{doc.css('title').text}"

    # Debug output for each site's specific selectors
    case @feed.name
    when 'A List Apart'
      puts "Found #{doc.css('div.grid-card-3').count} grid cards"
      puts "Found #{doc.css('h3.article-title').count} article titles"
    when 'UsabilityGeek'
      puts "Found #{doc.css('article.blog-item').count} blog items"
      puts "Found #{doc.css('h2.blog-title').count} blog titles"
    when 'UX Matters'
      puts "Found #{doc.css('div.entry').count} entries"
      puts "Found #{doc.css('h3 a').count} article links"
    when 'Prototypr'
      puts "Found #{doc.css('article.post-preview').count} post previews"
      puts "Found #{doc.css('h2.title').count} titles"
    end

    doc
  rescue => e
    puts "Error fetching #{url}: #{e.message}"
    puts e.backtrace.first(5)
    nil
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

  articles = doc.css('article.type-article')
  puts "\nFound #{articles.count} total articles"

  articles.each do |article|
    # Get article info
    title = article.css('.featured-content__title a, h4.home-post-title a, h2.entry-title a').text.strip
    url = article.css('.featured-content__title a, h4.home-post-title a, h2.entry-title a').attr('href')&.value

    # Try various content selectors
    content = article.css('.featured-content__excerpt, .post-excerpt, .entry-summary p').first&.text&.strip
    content ||= article.css('p').reject { |p| p.text.length < 50 }.first&.text&.strip

    # Get date
    date_text = article.css('time').attr('datetime')&.value
    if date_text.blank? && url =~ /\/(\d{4})\/(\d{2})\//
      date_text = "#{$1}-#{$2}-01"
    end

    next unless title.present? && url.present?

    # Ensure URL is absolute
    unless url.start_with?('http')
      url = "https://alistapart.com#{url}"
    end

    create_article(
      title: title,
      url: url,
      content: content,
      published_at: date_text.present? ? Date.parse(date_text) : Time.current
    )
  end
end


def scrape_usabilitygeek
  doc = fetch_page(@feed.url)
  return unless doc

  articles = doc.css('article.elementor-post')
  puts "\nFound #{articles.count} UsabilityGeek articles"

  articles.each do |article|
    title = article.css('h3.elementor-post__title').text.strip
    url = article.css('a.elementor-post__thumbnail__link').attr('href')&.value
    content = article.css('.elementor-post__excerpt p').text.strip
    date_text = article.css('.elementor-post-date').text.strip

    next unless title.present? && url.present?

    create_article(
      title: title,
      url: url,
      content: content,
      published_at: date_text.present? ? Date.parse(date_text) : Time.current
    )
  end
end

def scrape_uxmatters
  # First try the main articles page
  doc = fetch_page("https://www.uxmatters.com/mt/archives/")
  return unless doc

  puts "\nExamining page structure:"
  puts doc.css('td.title a').map { |a| "#{a.text}: #{a['href']}" }

  articles = doc.css('td.title')
  puts "\nFound #{articles.count} articles"

  articles.each do |article|
    title = article.css('a').text.strip
    relative_url = article.css('a').attr('href')&.value
    url = relative_url.start_with?('http') ? relative_url : "https://www.uxmatters.com#{relative_url}"

    # Get the date from the sibling td with class date
    date_text = article.parent.css('td.date').text.strip

    puts "\nFound article:"
    puts "Title: #{title}"
    puts "URL: #{url}"
    puts "Date: #{date_text}"

    next unless title.present? && url.present?

    create_article(
      title: title,
      url: url,
      content: get_article_content(url),
      published_at: date_text.present? ? Date.parse(date_text) : Time.current
    )
  end
end

def get_article_content(url)
  doc = fetch_page(url)
  return nil unless doc
  doc.css('.article-content p, .entry-content p').first&.text&.strip
end

def fetch_page(url)
  puts "\nFetching: #{url}"
  headers = {
    'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language' => 'en-US,en;q=0.5',
    'Cache-Control' => 'no-cache',
    'Pragma': 'no-cache'
  }

  response = HTTParty.get(url, headers: headers)
  return nil unless response.code == 200

  doc = Nokogiri::HTML(response.body)
  puts "Title: #{doc.css('title').text}"
  doc
rescue => e
  puts "Error fetching #{url}: #{e.message}"
  nil
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
