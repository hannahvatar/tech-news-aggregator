# app/models/report.rb
class Report < ApplicationRecord
  validates :report_type, presence: true
  validates :detail_level, presence: true
  validates :data, presence: true

  # Optional: Add any specific validations for your use case
end
