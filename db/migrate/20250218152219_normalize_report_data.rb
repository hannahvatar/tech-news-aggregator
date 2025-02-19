# db/migrate/TIMESTAMP_normalize_report_data.rb
class NormalizeReportData < ActiveRecord::Migration[7.1]
  def up
    Report.find_each do |report|
      begin
        # Force data normalization
        normalized_data = report.data
        report.update_column(:data, normalized_data)
      rescue => e
        Rails.logger.error "Error processing report #{report.id}: #{e.message}"
      end
    end
  end

  def down
    # No need to revert
  end
end
