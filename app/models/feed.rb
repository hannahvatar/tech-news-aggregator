# app/models/feed.rb
require 'feedjira'
require 'httparty'

class Feed < ApplicationRecord
  has_many :articles

  def fetch_and_save_articles
    response = HTTParty.get(url)
    feed = Feedjira.parse(response.body)

    feed.entries.each do |entry|
      articles.create!(
        title: entry.title,
        url: entry.url,
        published_at: entry.published,
        content: entry.content || entry.summary,
        guid: entry.id || entry.url  # Add this line - using URL as fallback if id not present
      )
    end
  rescue => e
    puts "Error fetching feed: #{e.message}"
    []
  end
end
