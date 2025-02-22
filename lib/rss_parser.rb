require 'rss'
require 'open-uri'

# Define the RSS feed URL
url = 'https://rss.app/feeds/vOX2kDsEMpLIcBGE.xml'

# Fetch and parse the RSS feed
open(url) do |rss|
  feed = RSS::Parser.parse(rss)

  # Loop through each item in the RSS feed and print the title and link
  feed.items.each do |item|
    puts "Title: #{item.title}"
    puts "Link: #{item.link}"
    puts "Published: #{item.pubDate}"
    puts "Description: #{item.description}"
    puts "-" * 50
  end
end
