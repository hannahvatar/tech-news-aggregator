# lib/tasks/rss.rake
namespace :rss do
  desc "Sync all active feeds"
  task sync_all: :environment do
    service = RssService.new
    Feed.where(is_active: true).each do |feed|
      service.sync_feed(feed.feed_url)
    end
  end
end
