class ScrapedFeed < ApplicationRecord
  has_many :scraped_articles

  def scrape_and_save_articles
    response = HTTParty.get(url)
    doc = Nokogiri::HTML(response.body)

    doc.css('article.article--post').each do |article|
      title = article.css('h2.article--post__title').text.strip
      article_url = article.css('h2.article--post__title a').first['href']
      article_url = "https://www.smashingmagazine.com#{article_url}" unless article_url.start_with?('http')

      # Get the date
      date_element = article.css('time').first
      published_at = date_element ? Time.parse(date_element['datetime']) : Time.current

      # Try different CSS selectors for content
      content = article.css('.article-content p').text.strip
      if content.empty?
        content = article.css('.article__intro').text.strip
      end
      if content.empty?
        content = article.css('p.article--post__teaser').text.strip
      end

      scraped_articles.create!(
        title: title,
        url: article_url,
        content: content,
        published_at: published_at
      )
    end
    update(last_scraped_at: Time.current)
  rescue => e
    puts "Error scraping feed: #{e.message}"
    []
  end
end
