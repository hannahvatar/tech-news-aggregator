class WebsiteScraper
  def initialize(url)
    @url = url
    @agent = Mechanize.new do |agent|
      agent.user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36'
      agent.verify_mode = OpenSSL::SSL::VERIFY_NONE  # Add this for SSL issues
    end
  end

  def scrape
    begin
      # Try different methods of fetching the page
      page = fetch_page
      extract_articles(page)
    rescue StandardError => e
      Rails.logger.error("Scraping error for #{@url}: #{e.message}")
      log_detailed_error(e)
      []
    end
  end

  private

  def fetch_page
    begin
      # First try Mechanize
      page = @agent.get(@url)
      return page
    rescue StandardError => e
      Rails.logger.warn("Mechanize fetch failed: #{e.message}")
    end

    begin
      # Fallback to HTTParty
      response = HTTParty.get(@url, headers: {'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36'})
      Nokogiri::HTML(response.body)
    rescue StandardError => e
      Rails.logger.error("HTTParty fetch failed: #{e.message}")
      raise
    end
  end

  def extract_articles(page)
    selectors = [
      '.article-title a',
      '.post-title a',
      '.entry-title a',
      'article a',
      '.blog-post a',
      'h2 a',
      'h3 a'
    ]

    articles = selectors.flat_map do |selector|
      extract_articles_with_selector(page, selector)
    end.uniq { |article| article[:url] }

    # If no articles found, log the page content for debugging
    if articles.empty?
      log_page_content(page)
    end

    articles
  end

  def extract_articles_with_selector(page, selector)
    page.search(selector).map do |link|
      title = link.text.strip
      url = link['href']

      # Extract content for each article
      content = extract_content(page, url)

      # Handle relative URLs
      url = URI.join(@url, url).to_s if url && url.start_with?('/')

      {
        title: title,
        url: url,
        content: content, # Add content here
        published_at: Time.current
      }
    end.select { |article| valid_article?(article) }
  end

  def extract_content(page, article_url)
    # Extract the main content of the article using a selector
    # This might vary based on the site's structure; you'll need to inspect the HTML and adjust accordingly

    content = page.search('.article-body').first
    content ? content.text.strip : "No content found"
  end

  def valid_article?(article)
    article[:title].present? &&
    article[:url].present? &&
    article[:title].length > 5 &&
    !article[:url].include?('#')
  end

  def log_page_content(page)
    Rails.logger.warn("No articles found for #{@url}")
    Rails.logger.warn("Page content preview (first 1000 characters):")
    Rails.logger.warn(page.to_s[0..1000])
  end
end
