# app/models/article.rb
class Article < ApplicationRecord
  belongs_to :feed
  has_one :ai_summary, dependent: :destroy
  has_many :key_facts, dependent: :destroy
  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags

  validates :title, presence: true
  validates :url, presence: true, uniqueness: true
  validates :guid, presence: true, uniqueness: true
  validates :published_at, presence: true

  def source_name
    Rails.logger.debug "Checking source_name for article #{id}"
    Rails.logger.debug "Feed ID: #{feed_id}"
    Rails.logger.debug "Feed present?: #{feed.present?}"
    Rails.logger.debug "Feed name: #{feed&.name}"

    feed&.name.presence || "No feed name"
  end
end
