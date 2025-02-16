# lib/tasks/feeds.rake
namespace :feeds do
  desc "Fetch articles from all feeds"
  task fetch: :environment do
    puts "Starting to fetch articles..."
    start_time = Time.current

    FeedFetcherService.fetch_all

    end_time = Time.current
    puts "Finished fetching articles. Duration: #{end_time - start_time} seconds"
    puts "Total Feeds: #{Feed.count}"
    puts "Total Articles: #{Article.count}"
  end
end
