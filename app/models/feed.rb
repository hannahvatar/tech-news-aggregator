# app/models/feed.rb
class Feed < ApplicationRecord
  has_many :articles
end
