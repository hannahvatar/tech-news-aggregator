# db/migrate/TIMESTAMP_ensure_report_data_is_json.rb
class EnsureReportDataIsJson < ActiveRecord::Migration[6.1]
  def up
    Report.find_each do |report|
      begin
        # Use the new normalization method
        normalized_data = Report.normalize_data(report.data)

        # Update the report with normalized data
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
