class Article < ApplicationRecord
  belongs_to :feed
  has_one :ai_summary
  has_many :key_facts
  has_many :article_tags
  has_many :tags, through: :article_tags
end
