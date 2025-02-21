# lib/tasks/scraper.rake
namespace :scraper do
  desc "Scrape articles from all feeds"
  task scrape_all: :environment do
    puts "Starting scrape of all feeds..."
    ScraperService.scrape_all_feeds
    puts "Finished scraping feeds"
  end
end
