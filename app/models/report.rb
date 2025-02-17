# app/models/report.rb
class Report < ApplicationRecord
  # Add any necessary logic here (e.g., validations, associations)

  def self.fetch_report_data(report_type, detail_level)
    data = where(report_type: report_type, detail_level: detail_level).to_a
    data.presence || []
  end
end
