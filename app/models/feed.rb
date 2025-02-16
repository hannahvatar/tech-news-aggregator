class Feed < ApplicationRecord
  has_many :articles

  validates :name, presence: true
  validates :url, presence: true, uniqueness: true
  validates :feed_type, presence: true
end
