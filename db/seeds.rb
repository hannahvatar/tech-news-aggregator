# db/seeds.rb
feeds_data = [
  {
    name: 'UX Design Weekly',
    url: 'https://uxdesignweekly.com/feed/',
    description: 'Weekly curated UX design resources and insights'
  },
  {
    name: 'UX Planet',
    url: 'https://uxplanet.org/feed',
    description: 'UX design articles, tutorials, and inspiration'
  },
  {
    name: 'NN/g UX Research',
    url: 'https://www.nngroup.com/feed/rss/',
    description: 'Nielsen Norman Group UX research and articles'
  },
  {
    name: 'UX Collective on Medium',
    url: 'https://uxdesign.cc/feed',
    description: 'UX design stories and insights from Medium'
  },
  {
    name: 'UX Movement',
    url: 'https://uxmovement.com/feed/',
    description: 'UX design principles and best practices'
  }
]

feeds_data.each do |feed_attrs|
  # This will only create the feed if it doesn't already exist
  Feed.find_or_create_by(url: feed_attrs[:url]) do |feed|
    feed.name = feed_attrs[:name]
    feed.description = feed_attrs[:description] if Feed.column_names.include?('description')
  end
end

puts "Created #{Feed.count} feeds"
